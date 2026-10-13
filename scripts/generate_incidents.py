import json
import random
from pathlib import Path

random.seed(42)

scenarios = [
    {
        "service": "EC2",
        "issue": "High CPU utilization",
        "root_cause": "Excessive application workload",
        "resolution": "Inspect top processes and optimize workload",
        "severity": "HIGH",
    },
    {
        "service": "EKS",
        "issue": "CrashLoopBackOff",
        "root_cause": "Application container exits repeatedly",
        "resolution": "Inspect pod logs and Kubernetes events",
        "severity": "HIGH",
    },
    {
        "service": "RDS",
        "issue": "Database connection exhaustion",
        "root_cause": "Connection pool limit reached",
        "resolution": "Inspect connection usage and application leaks",
        "severity": "CRITICAL",
    },
    {
        "service": "Lambda",
        "issue": "Function timeout",
        "root_cause": "Execution exceeds configured timeout",
        "resolution": "Inspect downstream latency and optimize execution",
        "severity": "MEDIUM",
    },
]

output = Path("data/raw/incidents.jsonl")
output.parent.mkdir(parents=True, exist_ok=True)

with output.open("w", encoding="utf-8") as file:
    for i in range(1000):
        scenario = random.choice(scenarios)

        record = {
            "incident_id": f"INC-{i+1:05d}",
            "instruction": (
                "Analyze the following cloud incident. "
                "Identify the root cause, severity, and resolution."
            ),
            "context": (
                f"AWS Service: {scenario['service']}. "
                f"Observed issue: {scenario['issue']}."
            ),
            "response": json.dumps({
                "root_cause": scenario["root_cause"],
                "severity": scenario["severity"],
                "resolution": scenario["resolution"],
            }),
        }

        file.write(json.dumps(record) + "\n")

print(f"Generated 1000 records in {output}")