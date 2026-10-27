import json
import sys


def evaluate(values):
    hidden = [
        max(0.0, values[0] - values[1]),
        max(0.0, 0.5 * values[0] + 0.5 * values[1] + 0.25),
    ]
    output = [2.0 * hidden[0] - hidden[1] + 0.5]
    return [
        {"layer": "hidden", "output": hidden},
        {"layer": "output", "output": output},
    ]


request = json.load(sys.stdin)
cases = []
for case in request["cases"]:
    trace = evaluate(case["input"])
    cases.append({
        "input": case["input"],
        "expected_output": trace[-1]["output"],
        "expected_trace": trace,
    })

json.dump({"model_id": request["model_id"], "cases": cases}, sys.stdout)
sys.stdout.write("\n")
