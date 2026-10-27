import hashlib
import json
import math
import struct
import tempfile
from pathlib import Path

from renn.generator import BuildError
from renn.jsonutil import loads_strict_json


_FORMATS = {
    "F16": ("e", 2),
    "F32": ("f", 4),
    "F64": ("d", 8),
    "BF16": (None, 2),
}
_MAX_HEADER_SIZE = 100 * 1024 * 1024


def _read_safetensors(path):
    data = Path(path).read_bytes()
    if len(data) < 8:
        raise BuildError("Safetensors file is shorter than its header length")
    header_size = struct.unpack_from("<Q", data)[0]
    if header_size > _MAX_HEADER_SIZE or 8 + header_size > len(data):
        raise BuildError("Safetensors header has an invalid size")
    try:
        header = loads_strict_json(data[8:8 + header_size])
    except (UnicodeDecodeError, json.JSONDecodeError, ValueError) as exc:
        raise BuildError(f"invalid Safetensors header: {exc}") from exc
    if not isinstance(header, dict):
        raise BuildError("Safetensors header must be a JSON object")

    data_start = 8 + header_size
    data_size = len(data) - data_start
    tensors = {}
    ranges = []
    for name, description in header.items():
        if name == "__metadata__":
            if not isinstance(description, dict) or not all(
                isinstance(key, str) and isinstance(value, str)
                for key, value in description.items()
            ):
                raise BuildError("Safetensors metadata must contain string keys and values")
            continue
        if not isinstance(name, str) or not isinstance(description, dict):
            raise BuildError("invalid Safetensors tensor entry")
        dtype = description.get("dtype")
        shape = description.get("shape")
        offsets = description.get("data_offsets")
        if not isinstance(dtype, str) or dtype not in _FORMATS:
            raise BuildError(f"unsupported Safetensors dtype for {name!r}: {dtype!r}")
        if (
            not isinstance(shape, list)
            or any(not isinstance(size, int) or isinstance(size, bool) or size < 0 for size in shape)
        ):
            raise BuildError(f"invalid Safetensors shape for {name!r}")
        if (
            not isinstance(offsets, list)
            or len(offsets) != 2
            or any(not isinstance(offset, int) or isinstance(offset, bool) for offset in offsets)
        ):
            raise BuildError(f"invalid Safetensors data offsets for {name!r}")
        start, end = offsets
        format_code, item_size = _FORMATS[dtype]
        item_count = math.prod(shape)
        if start < 0 or end < start or end > data_size or end - start != item_count * item_size:
            raise BuildError(f"invalid Safetensors data range for {name!r}")
        ranges.append((start, end, name))
        raw = data[data_start + start:data_start + end]
        if dtype == "BF16":
            values = [
                struct.unpack("<f", struct.pack("<I", struct.unpack_from("<H", raw, offset)[0] << 16))[0]
                for offset in range(0, len(raw), 2)
            ]
        else:
            values = [item[0] for item in struct.iter_unpack("<" + format_code, raw)]
        if not all(math.isfinite(value) for value in values):
            raise BuildError(f"Safetensors tensor {name!r} contains non-finite values")
        tensors[name] = (shape, values)

    ranges.sort()
    if ranges and ranges[0][0] != 0:
        raise BuildError("Safetensors data section has unreferenced leading bytes")
    for previous, current in zip(ranges, ranges[1:]):
        if previous[1] > current[0]:
            raise BuildError(f"overlapping Safetensors data ranges: {previous[2]!r} and {current[2]!r}")
        if previous[1] < current[0]:
            raise BuildError("Safetensors data section has unreferenced bytes")
    if ranges and ranges[-1][1] != data_size:
        raise BuildError("Safetensors data section has unreferenced trailing bytes")
    if not ranges and data_size:
        raise BuildError("Safetensors data section has no tensor entries")
    return tensors


def _read_safetensors_index(index_path):
    index_path = Path(index_path)
    if index_path.is_symlink() or not index_path.is_file():
        raise BuildError("Safetensors index must be a regular file")
    try:
        index_bytes = index_path.read_bytes()
        index = loads_strict_json(index_bytes.decode("utf-8"))
    except (OSError, UnicodeDecodeError, json.JSONDecodeError, ValueError) as exc:
        raise BuildError(f"invalid Safetensors index JSON: {exc}") from exc
    if not isinstance(index, dict) or not isinstance(index.get("weight_map"), dict):
        raise BuildError("Safetensors index must contain a weight_map object")
    weight_map = index["weight_map"]
    if not weight_map:
        raise BuildError("Safetensors index weight_map must not be empty")

    shards = {}
    for tensor_name, filename in weight_map.items():
        if not isinstance(tensor_name, str) or not tensor_name:
            raise BuildError("Safetensors index tensor names must be non-empty strings")
        if (
            not isinstance(filename, str)
            or not filename
            or filename in {".", ".."}
            or "/" in filename
            or "\\" in filename
            or any(ord(char) < 32 for char in filename)
        ):
            raise BuildError(f"invalid Safetensors shard filename for tensor {tensor_name!r}")
        shards.setdefault(filename, set()).add(tensor_name)

    tensors = {}
    shard_hashes = []
    for filename, expected_names in sorted(shards.items()):
        shard_path = index_path.parent / filename
        if shard_path.is_symlink() or not shard_path.is_file():
            raise BuildError(f"Safetensors shard {filename!r} is missing or is not a regular file")
        shard_tensors = _read_safetensors(shard_path)
        actual_names = set(shard_tensors)
        if actual_names != expected_names:
            missing = sorted(expected_names - actual_names)
            unexpected = sorted(actual_names - expected_names)
            raise BuildError(
                f"Safetensors shard {filename!r} does not match index weight_map "
                f"(missing: {missing!r}, unexpected: {unexpected!r})"
            )
        tensors.update(shard_tensors)
        shard_hashes.append({
            "filename": filename,
            "sha256": hashlib.sha256(shard_path.read_bytes()).hexdigest(),
        })

    source_files = {
        "index": {
            "filename": index_path.name,
            "sha256": hashlib.sha256(index_bytes).hexdigest(),
        },
        "shards": shard_hashes,
    }
    source_hash = hashlib.sha256(
        json.dumps(source_files, sort_keys=True, separators=(",", ":")).encode("utf-8")
    ).hexdigest()
    return tensors, source_hash


def _reshape(values, shape):
    if len(shape) == 1:
        return values
    stride = math.prod(shape[1:])
    return [
        _reshape(values[index * stride:(index + 1) * stride], shape[1:])
        for index in range(shape[0])
    ]


def import_safetensors(checkpoint_path, descriptor_path, output_path):
    checkpoint_path = Path(checkpoint_path)
    descriptor_path = Path(descriptor_path)
    try:
        descriptor = loads_strict_json(descriptor_path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, UnicodeDecodeError, ValueError) as exc:
        raise BuildError(f"invalid architecture descriptor JSON: {exc}") from exc
    if not isinstance(descriptor, dict):
        raise BuildError("architecture descriptor must be a JSON object")
    layers = descriptor.get("layers")
    if not isinstance(layers, list) or not layers:
        raise BuildError("architecture descriptor layers must be a non-empty list")

    if checkpoint_path.name.endswith(".safetensors.index.json"):
        tensors, checkpoint_hash = _read_safetensors_index(checkpoint_path)
    else:
        tensors = _read_safetensors(checkpoint_path)
        checkpoint_hash = hashlib.sha256(checkpoint_path.read_bytes()).hexdigest()
    model = {
        key: descriptor.get(key)
        for key in ("model_id", "source_revision", "license", "validation_inputs")
    }
    model_layers = []
    referenced_tensors = set()
    for index, layer in enumerate(layers, start=1):
        if not isinstance(layer, dict):
            raise BuildError(f"architecture descriptor layer {index} must be an object")
        weights_name = layer.get("weights_tensor")
        bias_name = layer.get("bias_tensor")
        if not isinstance(weights_name, str) or not isinstance(bias_name, str):
            raise BuildError(f"architecture descriptor layer {index} tensor names must be strings")
        if weights_name not in tensors or bias_name not in tensors:
            raise BuildError(f"architecture descriptor layer {index} references a missing tensor")
        for tensor_name in (weights_name, bias_name):
            if tensor_name in referenced_tensors:
                raise BuildError(
                    f"architecture descriptor references tensor {tensor_name!r} more than once"
                )
            referenced_tensors.add(tensor_name)
        weights_shape, weights_values = tensors[weights_name]
        bias_shape, bias_values = tensors[bias_name]
        if len(weights_shape) != 2 or len(bias_shape) != 1:
            raise BuildError(f"architecture descriptor layer {index} requires a 2D weight tensor and 1D bias tensor")
        model_layers.append({
            "name": layer.get("name"),
            "weights": _reshape(weights_values, weights_shape),
            "bias": bias_values,
            "activation": layer.get("activation"),
        })
    unreferenced_tensors = sorted(set(tensors) - referenced_tensors)
    if unreferenced_tensors:
        raise BuildError(
            "Safetensors checkpoint contains tensors not mapped by the architecture descriptor: "
            + ", ".join(repr(name) for name in unreferenced_tensors)
        )
    model["layers"] = model_layers

    from renn.generator import _build_model, load_model

    with tempfile.TemporaryDirectory() as temporary_directory:
        model_path = Path(temporary_directory) / "model.json"
        model_path.write_text(json.dumps(model, allow_nan=False), encoding="utf-8")
        checked_model = load_model(model_path)
    return _build_model(
        checked_model,
        output_path,
        checkpoint_hash,
        hashlib.sha256(descriptor_path.read_bytes()).hexdigest(),
    )
