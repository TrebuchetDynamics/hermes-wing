#!/usr/bin/env python3
"""Check the bounded Desktop outcome mapping, not runtime parity."""

import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
RECEIPT = ROOT / "docs/quality/desktop-next-port-slice.md"
MATRIX = ROOT / "docs/product/hermes-desktop-feature-matrix.json"


def require(condition, message):
    if not condition:
        raise SystemExit(message)


def check_path(relative):
    require((ROOT / relative).is_file(), f"Missing source: {relative}")


def main():
    matrix = json.loads(MATRIX.read_text())
    ledger = json.loads((ROOT / "goals.json").read_text())
    goals = {item["id"]: item for item in ledger["goals"]}
    tasks = {item["id"]: item for item in ledger["tasks"]}
    rows = matrix["features"]
    ids = [row["id"] for row in rows]
    require(len(ids) == len(set(ids)), "Duplicate matrix outcome ID")
    markdown = (ROOT / "docs/product/hermes-desktop-feature-matrix.md").read_text()
    markdown_ids = re.findall(r"^\| (HD-[A-Z]+) —", markdown, re.MULTILINE)
    require(sorted(ids) == sorted(markdown_ids), "JSON/Markdown row mismatch")
    todo = (ROOT / "TODO.md").read_text()
    resolved = []
    sources = set()
    for row in rows:
        goal_id = row["goal"]
        require(goal_id in goals, f"{row['id']}: unknown goal {goal_id}")
        require(row["existing_task_ids"], f"{row['id']}: missing task mapping")
        for task_id in row["existing_task_ids"]:
            require(task_id in tasks, f"{row['id']}: unknown task {task_id}")
            require(tasks[task_id]["goal"] == goal_id,
                    f"{row['id']}: task belongs to another goal")
            require(task_id in goals[goal_id]["tasks"], "Goal/task index mismatch")
            require(f"**{task_id}**" in todo, f"Missing TODO entry: {task_id}")
        paths = [row["reference"], *row["android_flow_candidates"]]
        if row["linux_native_candidate"]:
            paths.append(row["linux_native_candidate"])
        for path in paths:
            check_path(path)
            sources.add(path)
        require(row["android_runtime_result"] == "not_run" and
                row["linux_native_runtime_result"] == "not_run",
                f"{row['id']}: changed platform evidence boundary")
        resolved.append({"id": row["id"], "goal": goal_id,
                         "tasks": {key: tasks[key]["status"]
                                   for key in row["existing_task_ids"]},
                         "scope": row["wing_scope"]})
    text = RECEIPT.read_text()
    require(text.count("## Next implementation contract") == 1,
            "Receipt must choose exactly one next slice")
    for heading in ["Scope", "Sources", "Invariants", "Observable regressions",
                    "Executed evidence and limits"]:
        require(f"## {heading}" in text, f"Missing contract section: {heading}")
    links = re.findall(r"\[[^\]]+\]\(([^)]+)\)", text)
    for link in links:
        require(not re.match(r"[a-z]+:", link), "Receipt must use local sources")
        path, _, fragment = link.partition("#")
        target = (RECEIPT.parent / path).resolve() if path else RECEIPT
        require(target.is_file(), f"Broken receipt link: {link}")
        if fragment:
            headings = re.findall(r"^#+\s+(.+)$", target.read_text(), re.MULTILINE)
            anchors = {re.sub(r"[^\w\- ]", "", title.lower()).replace(" ", "-")
                       for title in headings}
            require(fragment in anchors, f"Broken receipt anchor: {link}")
    require(goals["PARITY"]["status"] == "partial", "Do not certify PARITY")
    desktop_head = subprocess.check_output(
        ["git", "-C", str(ROOT / "hermes-desktop"), "rev-parse", "HEAD"],
        text=True).strip()
    require(desktop_head == matrix["reference_head"], "Desktop source pin moved")
    pinned = re.findall(r"^\| `([^`]+)` \| `([0-9a-f]{64})` \|$", text,
                        re.MULTILINE)
    require(len(pinned) >= 4, "Missing scoped source fingerprints")
    for path, expected in pinned:
        check_path(path)
        require(hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == expected,
                f"Inspected source changed: {path}")
    result = {"result": "pass", "outcomes": len(ids),
              "unique_outcomes": len(set(ids)), "mapped_outcomes": len(resolved),
              "unique_goals": len({row["goal"] for row in rows}),
              "unique_tasks": len({key for row in rows
                                   for key in row["existing_task_ids"]}),
              "checked_source_paths": len(sources), "receipt_links": len(links),
              "pinned_sources": len(pinned), "reference_head": desktop_head,
              "mappings": resolved}
    counts = re.search(
        r"Executed mapping: (\d+) outcomes, (\d+) unique IDs, (\d+) resolved mappings, "
        r"(\d+) unique\s+goals and (\d+) unique task IDs\. All (\d+) distinct "
        r"source/candidate paths exist\.\s+The check also passed (\d+) receipt "
        r"links and (\w+) scoped source fingerprints\.", text)
    if counts is None:
        raise SystemExit("Missing declared totals")
    declared = [int(value) for value in counts.groups()[:-1]]
    actual = [result[key] for key in ["outcomes", "unique_outcomes",
              "mapped_outcomes", "unique_goals", "unique_tasks",
              "checked_source_paths", "receipt_links"]]
    require(declared == actual, f"Receipt totals differ: {declared} != {actual}")
    require(counts.group(8) == "six" and result["pinned_sources"] == 6,
            "Receipt fingerprint total differs")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
