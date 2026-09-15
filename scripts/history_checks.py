#!/usr/bin/env python3
"""Qualify source-bound replacement histories through actual file/project entrypoints.

These observations exercise IO/source extraction and worker/JSON transport; they do not
prove compiler authenticity or replace the pure policy proofs.
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = '''import Lean
/-! Two callers preserve an earlier implementation overwritten after compilation. -/
def earlier (n : Nat) : Nat := n + 0
def target (n : Nat) : Nat := n
@[implemented_by earlier] def reference (n : Nat) : Nat := n
def first (n : Nat) : Nat := reference n
attribute [implemented_by target] reference
def second (n : Nat) : Nat := reference n
-- evaluator control
'''


def name(value):
    return [["str", part] for part in value.split(".")]


def main():
    env = {k: v for k, v in os.environ.items() if k not in ("LEAN_PATH", "LEAN_SRC_PATH")}
    with tempfile.TemporaryDirectory(prefix="history-controls-", dir=ROOT / "tmp") as raw:
        project = Path(raw)
        (project / "lean-toolchain").write_bytes((ROOT / "lean-toolchain").read_bytes())
        (project / "lakefile.lean").write_text(
            "import Lake\nopen Lake DSL\npackage history_adopter\nrequire strict_lean from "
            + json.dumps(str(ROOT)) + "\nlean_lib Example\n")
        (project / "foundation_manifest.json").write_text(json.dumps({
            "schema-version": 2, "surfaces": [{"library": "Example", "claim": "standard-logical",
                "execution": "checked", "rationale": "All three implementations compute the identity."}],
            "excluded-libraries": [], "excluded-executables": []}))
        lock = json.loads((ROOT / "lake-manifest.json").read_text())
        for package in lock["packages"]:
            package["inherited"] = True
        lock["packages"].append({"name": "strict_lean", "scope": "", "type": "path",
            "dir": str(ROOT), "configFile": "lakefile.lean", "manifestFile": "lake-manifest.json", "inherited": False})
        (project / "lake-manifest.json").write_text(json.dumps(lock))
        (project / ".lake").mkdir()
        (project / ".lake/packages").symlink_to(ROOT / ".lake/packages", target_is_directory=True)
        for invocation, flags, mode in [("project", [], "freshProject"),
                ("incremental", ["--incremental"], "incrementalProject"),
                ("file", ["--file", "Example.lean", "--claim", "standard-logical", "--execution", "checked"], "freshFile")]:
            for phase in ("positive", "unsupported", "restored"):
                source = SOURCE.replace("-- evaluator control", "run_cmd pure ()") if phase == "unsupported" else SOURCE
                (project / "Example.lean").write_text(source)
                shutil.rmtree(project / ".lake/build", ignore_errors=True)
                output = project / f"{invocation}-{phase}.json"
                assert not output.exists()
                run = subprocess.run([str(ROOT / ".lake/build/bin/axiomGate"), "--project", str(project),
                    *flags, "--json-out", str(output)], cwd=project, env=env, text=True, capture_output=True, timeout=80)
                assert output.exists(), (run.stdout, run.stderr)
                result = json.loads(output.read_text())
                assert run.returncode == (1 if phase == "unsupported" else 0), (run.stdout, run.stderr)
                assert result["mode"] == mode, (result["status"], result["diagnostics"])
                assert {d["id"] for d in result["diagnostics"]} == ({"SL3001"} if phase == "unsupported" else set()), (result["status"], result["diagnostics"])
                assert result["status"] == ("incomplete" if phase == "unsupported" else "completed"), (result["status"], result["diagnostics"])
                report = result["scope"]["report"] if invocation == "file" else result["scope"]["surfaces"][0]["report"]
                requests = report["census"]["historyRequests"]
                assert requests and len(requests) == len({json.dumps(r) for r in requests}), requests
                # File inspection uses a fresh unit name, recorded in the declaration census.
                own_module = report["census"]["modules"][0]
                own_histories = [(mod, h) for mod, h in report["histories"] if mod == own_module]
                assert len(own_histories) == 1, report["histories"]
                history = own_histories[0][1]
                assert all([name(root), own_module] in requests for root in ("reference", "first", "second")), requests
                assert (project / "Example.lean").read_text() == source
                if phase == "unsupported":
                    assert history["kind"] == "unavailable" and "unsupported replacement-history evaluators" in history["detail"], history
                    assert all(r["unresolved"] for r in report["execution"] if [r["name"], own_module] in requests), report
                else:
                    assert history["kind"] == "completed" and history["before"] == source == history["after"], history
                    assert Path(history["path"]).name.endswith(".lean"), history
                    assert [name("reference"), name("earlier")] in history["replacements"], history
                    assert [name("reference"), name("target")] in history["replacements"], history
                    if invocation == "project" and phase == "restored":
                        check = subprocess.run(["lake", "env", "lean", "--run", "lean/StrictLean/Checker/HistoryQualification.lean", str(output)],
                            cwd=ROOT, env=env, text=True, capture_output=True, timeout=30)
                        assert check.returncode == 0, (check.stdout, check.stderr)
                        print(check.stdout, end="", flush=True)
                print(f"history {invocation}/{phase}: exact requests/source/outcome PASS", flush=True)


if __name__ == "__main__":
    main()
