#!/usr/bin/env python3
"""Run source-owned fixtures through existing Lean detectors; admit receipts in Lean.

Python owns filesystem/process orchestration only. Rule identity, diagnostic decoding,
expectation matching and demonstration admission are implemented by RuleExampleQualification.
"""
from __future__ import annotations
import argparse
from collections import deque
from concurrent.futures import ThreadPoolExecutor
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import time

ROOT = Path(__file__).resolve().parents[1]
CORPUS = ROOT / "examples/rules"
ENV = {k: v for k, v in os.environ.items() if k not in ("LEAN_PATH", "LEAN_SRC_PATH")}


def run(args: list[str], *, cwd: Path = ROOT) -> subprocess.CompletedProcess:
    return subprocess.run(args, cwd=cwd, env=ENV, text=True, capture_output=True, timeout=75)


def setup(project: Path) -> None:
    project.mkdir()
    (project / "lean-toolchain").write_bytes((ROOT / "lean-toolchain").read_bytes())
    (project / "lakefile.lean").write_text(
        "import Lake\nopen Lake DSL\npackage rule_examples\nrequire strict_lean from "
        + json.dumps(str(ROOT)) + "\nlean_lib Example\n")
    (project / "Example.lean").write_text("/-! The true proposition. -/\ntheorem baseline : True := True.intro\n")
    (project / "foundation_manifest.json").write_text(json.dumps({"schema-version": 2,
        "surfaces": [{"library": "Example", "claim": "kernel-only", "execution": "checked",
                      "rationale": "The fixture's exact mathematical claim and scope."}],
        "excluded-libraries": [], "excluded-executables": []}))
    manifest = json.loads((ROOT / "lake-manifest.json").read_text())
    for package in manifest["packages"]:
        package["inherited"] = True
    manifest["packages"].append({"type": "path", "name": "strict_lean", "dir": str(ROOT),
        "manifestFile": "lake-manifest.json", "inherited": False, "configFile": "lakefile.lean"})
    (project / "lake-manifest.json").write_text(json.dumps(manifest))
    (project / ".lake").mkdir()
    (project / ".lake/packages").symlink_to(ROOT / ".lake/packages", target_is_directory=True)


def instantiate(value, replacements):
    if isinstance(value, str):
        # Whole-field placeholders only: never rewrite actual diagnostic/source evidence.
        return replacements.get(value, value)
    if isinstance(value, list):
        return [instantiate(item, replacements) for item in value]
    if isinstance(value, dict):
        return {key: instantiate(item, replacements) for key, item in value.items()}
    return value


def snapshot(paths: list[Path]) -> list[dict]:
    return [{"uri": str(path), "source": path.read_text()} for path in paths]


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rules", nargs="+", help="Explicit scoped qualification, never full-corpus PASS")
    parser.add_argument("--evidence", type=Path, required=True)
    options = parser.parse_args()
    specs = json.loads((CORPUS / "corpus.json").read_text())
    selected = options.rules or list(specs)
    if len(set(selected)) != len(selected) or any(rule not in specs for rule in selected):
        raise RuntimeError("unknown or duplicate selected rule")
    records = []
    checker_paths = sorted((ROOT / "lean/StrictLean").rglob("*.lean")) + sorted(
        (ROOT / "lean/StrictLeanPolicy").rglob("*.lean")) + [
        ROOT / "lean/StrictLeanPolicy.lean", ROOT / "lean-toolchain", ROOT / "lakefile.lean",
        ROOT / "lake-manifest.json", ROOT / "scripts/rule_example_checks.py"] + sorted(
        path for path in CORPUS.rglob("*") if path.is_file())
    checker_before = snapshot(checker_paths)
    with tempfile.TemporaryDirectory(prefix="rule-examples-", dir=ROOT / "tmp") as raw:
        scratch = Path(raw)
        def produce(rule: str, phase: str) -> dict:
            spec = specs[rule]
            case = "Fixed" if phase == "Restored" else phase
            project = scratch / f"{rule}-{phase}"
            setup(project)  # Each phase has fresh, disjoint root artifacts.
            folder = CORPUS / rule
            source_file = folder / (spec.get("source", "{case}.lean").format(case=case))
            paths = [project / "Example.lean"]
            source_path = project / "Example.lean"
            output = scratch / f"{rule}-{phase}.json"
            kind = "positive" if case == "Fixed" else spec["kind"]
            mode = spec["invocation"]
            if mode == "file" and rule != "SL2001":
                source_path = project / "Fixture.lean"
                paths.append(source_path)
            command = [str(ROOT / ".lake/build/bin/axiomGate"), "--project", str(project)]
            if mode == "documentation":
                docs = project / "docs"
                docs.mkdir()
                source_path = docs / "Example.md"
                source_path.write_bytes(source_file.read_bytes())
                paths.append(source_path)
                command = [str(ROOT / ".lake/build/bin/ruleExamples"), "--documentation",
                           str(project), str(docs), str(output)]
            else:
                source_path.write_bytes(source_file.read_bytes())
                if rule == "SL2001":
                    request_file = folder / f"{case}.json"
                    request = json.loads(request_file.read_text())
                    command += ["--file", str(project / request["source"]), "--claim", "kernel-only",
                                "--execution", "checked"]
                elif rule == "SL2002":
                    (project / "foundation_manifest.json").write_bytes((folder / f"{case}.json").read_bytes())
                elif rule == "SL1003":
                    vendor = project / "vendor"
                    vendor.mkdir()
                    (vendor / "Dependency.lean").write_bytes((folder / f"{case}.lean").read_bytes())
                    (vendor / "lean-toolchain").write_bytes((ROOT / "lean-toolchain").read_bytes())
                    (vendor / "lakefile.toml").write_text('name = "example_dependency"\n[[lean_lib]]\nname = "Dependency"\n')
                    config = project / "lakefile.lean"
                    config.write_text(config.read_text() + '\nrequire example_dependency from "vendor"\n')
                    lock = project / "lake-manifest.json"
                    m = json.loads(lock.read_text())
                    m["packages"].append({"type": "path", "name": "example_dependency", "dir": "vendor",
                        "manifestFile": "lake-manifest.json", "inherited": False, "configFile": "lakefile.toml"})
                    lock.write_text(json.dumps(m))
                    paths.append(vendor / "Dependency.lean")
                elif mode == "file":
                    command += ["--file", str(source_path), "--claim", spec.get("claim", "kernel-only"),
                                "--execution", "checked"]
                if rule == "SL1002" and case == "Violation":
                    command = [str(ROOT / ".lake/build/bin/ruleExamples"), "--policy-negative",
                               str(project), str(source_path), str(output)]
                else:
                    command += ["--json-out", str(output)]
            config_paths = [project / name for name in
                            ("foundation_manifest.json", "lakefile.lean", "lake-manifest.json", "lean-toolchain")]
            if rule == "SL1003":
                config_paths += [project / "vendor/lakefile.toml", project / "vendor/lean-toolchain"]
            configuration = {"uri": str(project), "source": json.dumps(snapshot(config_paths), sort_keys=True)}
            before = {"sources": snapshot(paths), "configuration": configuration}
            started = time.monotonic()
            execution = run(command, cwd=project)
            elapsed = time.monotonic() - started
            if not output.is_file():
                raise RuntimeError(f"{rule}/{phase}: missing terminal result\n{execution.stdout}{execution.stderr}")
            observed = json.loads(output.read_text())
            after = {"sources": snapshot(paths), "configuration": {"uri": str(project),
                     "source": json.dumps(snapshot(config_paths), sort_keys=True)}}
            replacements = {"$PROJECT": str(project), "$SOURCE": str(source_path),
                "$MISSING": str(project / "Missing.lean"), "$SOURCE_TEXT": source_path.read_text(),
                "$DOCS": str(project / "docs")}
            # An isolated project producer returns its actual temporary source URI.
            # Obtain it from the independently recorded scope source map, never from a finding.
            scope = observed["scope"]
            if isinstance(scope, dict) and "sources" in scope:
                candidates = [s for s in scope["sources"] if s["module"] == [["str", "Example"]]]
                if len(candidates) != 1 or candidates[0]["source"] != source_path.read_text():
                    raise RuntimeError("project example source account mismatch")
                item = candidates[0]
                actual_path = Path(item["path"])
                if not actual_path.is_relative_to(project / "tmp"):
                    raise RuntimeError("fresh project source outside owned copy")
                replacements["$SOURCE"] = item["path"]
                alias = {"uri": item["path"], "source": item["source"]}
                before["sources"].append(alias)
                after["sources"].append(alias)
            if mode == "documentation":
                # Explicit fixture-owned byte slice, not a second Markdown parser.
                if case == "Violation" and "snippet" in spec:
                    start, stop, origin = spec["snippet"]
                    text = source_path.read_bytes()[start:stop].decode()
                    uri = str(project / "docs") + "/" + origin + "#lean-snippet"
                    replacements.update({"$SNIPPET_URI": uri, "$SNIPPET_TEXT": text})
                    alias = {"uri": uri, "source": text}
                    before["sources"].append(alias)
                    after["sources"].append(alias)
            expected = [] if case == "Fixed" else instantiate(spec["diagnostics"], replacements)
            return {"rule": rule, "phase": phase, "kind": kind,
                "mode": spec["mode"], "sourcePath": str(source_file.relative_to(ROOT)), "source": source_file.read_text(),
                "command": command, "exitCode": execution.returncode,
                "before": before, "after": after, "expected": expected, "result": observed,
                "unresolvedPatterns": [] if case == "Fixed" else spec.get("unresolvedPatterns", []),
                "stdout": execution.stdout, "stderr": execution.stderr, "detectorSeconds": elapsed}

        # Two independent processes at most. Each phase has its own root artifacts;
        # consumption/export stays in registry/phase order, independent of completion.
        jobs = iter((rule, phase) for rule in selected for phase in ("Fixed", "Violation", "Restored"))
        with ThreadPoolExecutor(max_workers=2) as pool:
            pending = deque()
            for _ in range(2):
                if job := next(jobs, None):
                    pending.append(pool.submit(produce, *job))
            while pending:
                record = pending.popleft().result()
                records.append(record)
                options.evidence.parent.mkdir(parents=True, exist_ok=True)
                options.evidence.write_text(json.dumps({"schemaVersion": 1, "completeCorpus": options.rules is None, "selected": selected,
                    "checkerBefore": checker_before, "checkerAfter": snapshot(checker_paths), "records": records}, indent=2) + "\n")
                current = scratch / "current.json"
                current.write_text(json.dumps({"checkerBefore": checker_before,
                    "checkerAfter": snapshot(checker_paths), "records": [records[-1]]}))
                checked = run(["lake", "env", "lean", "--run",
                    "lean/StrictLean/Checker/RuleExampleQualification.lean", "--record", str(current)])
                if checked.returncode:
                    raise RuntimeError(f"{record['rule']}/{record['phase']}: {checked.stdout}{checked.stderr}")
                print(f"{record['rule']}/{record['phase']}: qualified {record['kind']} ({record['detectorSeconds']:.2f}s detector)", flush=True)
                if job := next(jobs, None):
                    pending.append(pool.submit(produce, *job))
    checked = run(["lake", "env", "lean", "--run",
        "lean/StrictLean/Checker/RuleExampleQualification.lean", str(options.evidence.resolve())])
    if checked.returncode:
        raise RuntimeError(checked.stdout + checked.stderr)
    print(f"rule example campaign: PASS ({len(selected)} selected rules; diagnostic evidence only)")


if __name__ == "__main__":
    main()
