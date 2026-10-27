import json


def loads_strict_json(data):
    def unique_pairs(pairs):
        result = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f"duplicate JSON key {key!r}")
            result[key] = value
        return result

    def reject_constant(value):
        raise ValueError(f"invalid JSON constant {value}")

    return json.loads(
        data,
        object_pairs_hook=unique_pairs,
        parse_constant=reject_constant,
    )
