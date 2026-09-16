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
import StrictLean.Contract
/-! Two callers preserve an earlier implementation overwritten after compilation. -/
def earlier (n : Nat) : Nat := n + 0
def target (n : Nat) : Nat := n
@[implemented_by earlier] def reference (n : Nat) : Nat := n
def first (n : Nat) : Nat := reference n
attribute [implemented_by target] reference
def second (n : Nat) : Nat := reference n
def recursiveSum : List Nat → Nat
  | [] => 0
  | x :: xs => x + recursiveSum xs
private def unused (xs : List Nat) : Nat := recursiveSum xs
private def unregistered (xs : List Nat) : Nat := recursiveSum xs
theorem privateContract : StrictLean.ExecutableContract unused
    (fun f => ∀ xs, f xs = recursiveSum xs) := ⟨by intro xs; rfl⟩
theorem importedContract : StrictLean.ExecutableContract Nat.add
    (fun f => ∀ n m, f n m = n + m) := ⟨by intros; rfl⟩
-- evaluator control
'''
UNCHECKED = '''open Lean Elab Command
run_cmd do
  let d := Declaration.thmDecl {
    name := `admissionFalse
    levelParams := [], type := mkConst ``False, value := mkConst ``True.intro }
  match (← getEnv).addDeclCore 200000 1000 d none false with
  | .ok env => setEnv env
  | .error _ => throwError "construction failed"
'''
CHANGED = '''run_cmd do
  let path ← Lean.getFileName
  let content ← IO.FS.readFile path
  IO.FS.writeFile path (content ++ "\\n")
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
            phases = ["positive", "unsupported", "restored"]
            if invocation != "incremental":
                phases += ["admission", "restored", "source-change", "restored"]
            for phase_index, phase in enumerate(phases):
                mutation = {"unsupported": "run_cmd pure ()", "admission": UNCHECKED,
                            "source-change": CHANGED}.get(phase, "-- evaluator control")
                source = SOURCE.replace("-- evaluator control", mutation)
                (project / "Example.lean").write_text(source)
                shutil.rmtree(project / ".lake/build", ignore_errors=True)
                output = project / f"{invocation}-{phase_index}-{phase}.json"
                assert not output.exists()
                run = subprocess.run([str(ROOT / ".lake/build/bin/axiomGate"), "--project", str(project),
                    *flags, "--json-out", str(output)], cwd=project, env=env, text=True, capture_output=True, timeout=80)
                assert output.exists(), (run.stdout, run.stderr)
                result = json.loads(output.read_text())
                incomplete = phase in ("unsupported", "admission", "source-change")
                assert run.returncode == int(incomplete), (run.stdout, run.stderr)
                assert result["mode"] == mode, (result["status"], result["diagnostics"])
                expected = {"SL3001"} if phase == "unsupported" else ({"SL2005"} if incomplete else set())
                assert {d["id"] for d in result["diagnostics"]} == expected, (result["status"], result["diagnostics"])
                assert result["status"] == ("incomplete" if incomplete else "completed"), (result["status"], result["diagnostics"])
                if phase in ("admission", "source-change"):
                    assert len(result["diagnostics"]) == 1, result
                    finding = result["diagnostics"][0]
                    detail = finding["arguments"]["detail"]
                    if phase == "admission":
                        assert "kernel-admission" in detail and "admissionFalse" in detail, finding
                    else:
                        assert "producer-source: source snapshot changed" in detail, finding
                    assert finding["impact"] == "incomplete" and finding["mode"] == mode, finding
                    print(f"source {invocation}/{phase}: exact SL2005 incomplete PASS", flush=True)
                    continue
                report = result["scope"]["report"] if invocation == "file" else result["scope"]["surfaces"][0]["report"]
                requests = report["census"]["historyRequests"]
                assert requests and len(requests) == len({json.dumps(r) for r in requests}), requests
                # File inspection uses a fresh unit name, recorded in the declaration census.
                own_module = report["census"]["modules"][0]
                snapshots = [s for s in report["sourceBindings"] if s["moduleName"] == own_module]
                assert len(snapshots) == 1 and snapshots[0]["content"] == source, snapshots
                private_root = next(d["executableContract"]["root"] for d in report["declarations"]
                                    if d["name"] == name("privateContract"))
                assert any(r["name"] == private_root for r in report["execution"]), report["census"]
                assert [own_module, private_root] in report["census"]["declarations"], report["census"]
                unregistered = [d for d in report["declarations"] if d["name"][0] == ["str", "unregistered"]]
                assert len(unregistered) == 1 and unregistered[0]["private"], unregistered
                assert [own_module, unregistered[0]["name"]] in report["census"]["declarations"]
                assert all(r["name"] != unregistered[0]["name"] for r in report["execution"])
                assert any(r["name"] == [["str", "add"], ["str", "Nat"]]
                           and r["module"] != own_module for r in report["execution"]), report["census"]
                recursive_edges = []
                for root in report["execution"]:
                    closure = root["closure"]
                    nodes = {json.dumps(n) for n in closure["nodes"]}
                    assert nodes == {json.dumps(v["name"]) for v in closure["visits"]}
                    assert len(nodes) == len(closure["visits"])
                    edges = root["compilerEdges"] + sum([closure[k] for k in (
                        "logicalEdges", "candidateEdges", "historyEdges", "currentReplacementEdges", "helperEdges")], [])
                    for i, visit in enumerate(closure["visits"]):
                        parent = visit["parent"]
                        if parent is None:
                            assert i == 0 and visit["name"] == root["name"], visit
                        else:
                            assert 0 <= parent < i and [closure["visits"][parent]["name"], visit["name"]] in edges, visit
                    assert all(json.dumps(a) in nodes and json.dumps(b) in nodes for a, b in edges)
                    recursive_edges.extend(e for e in root["compilerEdges"] if e[0] == e[1] and "recursiveSum" in str(e))
                    if root["name"] == name("reference"):
                        assert [name("reference"), name("target")] in closure["currentReplacementEdges"], closure
                        if phase != "unsupported":
                            assert [name("reference"), name("earlier")] in closure["historyEdges"], closure
                            assert [name("reference"), name("earlier")] not in closure["currentReplacementEdges"], closure
                assert recursive_edges, "retained recursive IR calls were dropped"
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
                    if invocation == "project" and phase_index == 2:
                        check = subprocess.run(["lake", "env", "lean", "--run", "lean/StrictLean/Checker/HistoryQualification.lean", str(output)],
                            cwd=ROOT, env=env, text=True, capture_output=True, timeout=30)
                        assert check.returncode == 0, (check.stdout, check.stderr)
                        print(check.stdout, end="", flush=True)
                print(f"history {invocation}/{phase}: exact requests/source/outcome PASS", flush=True)


if __name__ == "__main__":
    main()
