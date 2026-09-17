#!/usr/bin/env python3
"""Qualify actual acceptance routes at their raw worker boundary.

This is diagnostic fault injection, not a proof of universal correctness. The driver
and library are unchanged: an isolated copy of the native driver launches a wrapper
that changes one completed packet or refuses one child. No installed binary is edited.
ResultState.collect/finalize supply the universal finite-observation guarantees.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
WRAPPER = r'''#!/usr/bin/env python3
import json, os, pathlib, subprocess, sys, time
args = sys.argv[1:]
mode = os.environ.get("STRICT_LEAN_PACKET_FAULT", "")
surface = args and args[0] == "--surface-worker"
compile_batch = args and args[0] == "--compile-batch-worker"
if surface and mode == "process": sys.exit(17)
if surface and mode == "timeout":
    print("qualification: surface worker waiting", flush=True)
    time.sleep(60)
code = subprocess.run([str(pathlib.Path(__file__).with_name("axiomGate-real")), *args]).returncode
if code != 0: sys.exit(code)
if surface and mode in {"missing", "duplicate", "misindexed", "stale", "unknown", "conflict", "build"}:
    request = json.loads(pathlib.Path(args[1]).read_text())
    output = pathlib.Path(request["output"])
    if mode == "missing": output.unlink(); sys.exit(0)
    packet = json.loads(output.read_text())
    payload = packet["payload"]
    if mode == "duplicate": payload["inspections"].append(payload["inspections"][0])
    if mode == "misindexed": payload["inspections"][0]["expectedModules"] = []
    if mode == "stale": packet["request"]["reportRoot"] += "-stale"
    if mode == "unknown": payload["inspections"][0]["report"]["declarations"][0]["kind"] = "unknown-kind"
    if mode == "conflict": payload["inspections"][0]["report"]["sourceBindings"][0]["content"] += "\n-- conflicting observation\n"
    if mode == "build": payload["build"]["exitCode"] = 17
    output.write_text(json.dumps(packet))
if compile_batch and mode in {"fence-missing", "fence-duplicate", "fence-misindexed"}:
    output = pathlib.Path(args[2]); packet = json.loads(output.read_text())
    if mode == "fence-missing": packet["payload"].pop()
    if mode == "fence-duplicate": packet["payload"].append(packet["payload"][0])
    if mode == "fence-misindexed": packet["payload"][0][0] = 999999
    output.write_text(json.dumps(packet))
sys.exit(0)
'''
GROUPS = {
    "surface": [("missing", "No such file"), ("duplicate", "omitted or added"),
                ("misindexed", "indexed to another request"), ("stale", "request binding mismatch")],
    "evidence": [("unknown", "unknown DeclarationKind"), ("conflict", "producer-source"),
                 ("build", "acceptance refused")],
    "fences": [("fence-missing", "missing required key"), ("fence-duplicate", "duplicateResult"),
               ("fence-misindexed", "unknownKey")],
    "process": [("process", None), ("timeout", "qualification: surface worker waiting")],
}


def setup(project: Path) -> None:
    project.mkdir(); (project / "docs").mkdir()
    (project / "lean-toolchain").write_bytes((ROOT / "lean-toolchain").read_bytes())
    (project / "lakefile.lean").write_text(
        "import Lake\nopen Lake DSL\npackage acceptance_control\nrequire strict_lean from "
        + json.dumps(str(ROOT)) + "\n@[default_target] lean_lib Example\n")
    (project / "foundation_manifest.json").write_text(json.dumps({
        "schema-version": 2, "surfaces": [{"library": "Example", "claim": "standard-logical",
        "execution": "report", "rationale": "Exact accepted-result transport controls."}],
        "excluded-libraries": [], "excluded-executables": []}))
    lock = json.loads((ROOT / "lake-manifest.json").read_text())
    lock["packages"] = [dict(p, inherited=True) for p in lock["packages"]] + [{
        "name": "strict_lean", "scope": "", "type": "path", "dir": str(ROOT),
        "configFile": "lakefile.lean", "manifestFile": "lake-manifest.json", "inherited": False}]
    (project / "lake-manifest.json").write_text(json.dumps(lock))
    (project / ".lake").mkdir(); (project / ".lake/packages").symlink_to(ROOT / ".lake/packages")
    (project / "Example.lean").write_text(
        "import StrictLean.Contract\n/-! Public acceptance transport control. -/\ndef value : Nat := 7\n")
    (project / "docs/control.md").write_text(
        "```lean\ntheorem documented : True := True.intro\n```\n\n"
        "<!-- lean-fail: Type mismatch -->\n```lean\nexample : False := True.intro\n```\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--group", choices=GROUPS, required=True)
    parser.add_argument("--evidence", type=Path, required=True)
    args = parser.parse_args()
    records = []
    active: subprocess.Popen | None = None

    def terminate_group(signum: int, _frame: object) -> None:
        # The outer 179s TERM / 180s KILL budget must also stop detached children.
        if active is not None:
            try:
                os.killpg(active.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            active.wait()
        raise SystemExit(128 + signum)

    signal.signal(signal.SIGTERM, terminate_group)
    signal.signal(signal.SIGINT, terminate_group)
    executable = ROOT / ".lake/build/bin/axiomGate"
    inputs = {"head": subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=ROOT, text=True).strip(),
              "binarySha256": hashlib.sha256(executable.read_bytes()).hexdigest()}
    args.evidence.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="acceptance-controls-", dir=ROOT / "tmp") as raw:
        scratch = Path(raw); project = scratch / "project"; setup(project)
        tools = scratch / "tool"; (tools / "bin").mkdir(parents=True); (tools / "lib").mkdir()
        (tools / "lib/lean").symlink_to(ROOT / ".lake/build/lib/lean")
        shutil.copy2(executable, tools / "bin/axiomGate-real")
        wrapper = tools / "bin/axiomGate"; wrapper.write_text(WRAPPER); wrapper.chmod(0o755)
        source_inputs = {str(p.relative_to(project)): p.read_text() for p in project.rglob("*")
                         if p.is_file() and ".lake" not in p.relative_to(project).parts}

        def invoke(fault: str, phase: str, reason: str | None = None) -> None:
            nonlocal active
            output = scratch / f"result-{len(records)}.json"
            command = [str(wrapper), "--project", str(project), "--with-docs", "--json-out", str(output)]
            env = {k: v for k, v in os.environ.items() if k not in ("LEAN_PATH", "LEAN_SRC_PATH")}
            env["STRICT_LEAN_PACKET_FAULT"] = fault
            started = time.monotonic()
            process = subprocess.Popen(command, cwd=project, env=env, stdout=subprocess.PIPE,
                                       stderr=subprocess.STDOUT, text=True, start_new_session=True)
            active = process
            timed_out = False
            try:
                log, _ = process.communicate(timeout=8 if fault == "timeout" else 60)
            except subprocess.TimeoutExpired:
                timed_out = True
                os.killpg(process.pid, signal.SIGKILL)
                log, _ = process.communicate()
            active = None
            value = json.loads(output.read_text()) if output.exists() else None
            passed = (not timed_out and process.returncode == 0 and value is not None and
                      value.get("status") == "completed" and "acceptance" in value and
                      "documentationAcceptance" in value) if not fault else (
                      process.returncode != 0 and value is not None and value.get("status") == "incomplete" and
                      "acceptance" not in value and "documentationAcceptance" not in value and
                      (fault != "timeout" or timed_out) and (reason is None or reason.lower() in log.lower()))
            record = {"phase": phase, "fault": fault, "command": command, "seconds": time.monotonic()-started,
                      "exitCode": process.returncode, "timeout": timed_out, "expectedReason": reason,
                      "expected": "incomplete, no acceptance" if fault else "same-snapshot combined acceptance",
                      "status": None if value is None else value.get("status"), "pass": bool(passed),
                      "log": log, "result": value}
            records.append(record)
            args.evidence.write_text(json.dumps({"inputs": inputs, "sources": source_inputs,
                                                "group": args.group, "records": records}, indent=2)+"\n")
            print(f"{phase}/{fault or 'positive'}: {'PASS' if passed else 'FAIL'} ({record['seconds']:.3f}s)", flush=True)
            if not passed:
                raise AssertionError((phase, fault, process.returncode, record["status"], log))
        invoke("", "positive")
        for fault, reason in GROUPS[args.group]:
            invoke(fault, "mutation", reason)
            invoke("", "restored")
    print("acceptance transport qualification: PASS (selected diagnostic group only)")


if __name__ == "__main__":
    main()
