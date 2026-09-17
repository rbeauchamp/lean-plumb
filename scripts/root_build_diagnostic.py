#!/usr/bin/env python3
"""Temporary allocation083 harness. Root-build evidence only; never acceptance.

Hosted-only execution: setup is bounded by the workflow's remaining total300;
measure is owned by one GNU timeout --signal=KILL 420s process group. A child
has a 120s alarm that kills the entire diagnostic group. Incomplete status is written BEFORE any fallible work.
Remove this file and the temporary workflow job after the authorized collection.
"""
import hashlib
import json
import math
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import time

A = "0d2d6142192967f4873305cbf1ec5d8227607a36"
B = "6c8835a57d0d6f8ab0479a0e6304b7736f6ca1f8"
RUNS = (("A1", A), ("B", B), ("A2", A))
BASE = Path("tmp/root-build-diagnostic").absolute()
RECEIPTS = BASE / "receipts"
SOURCE = Path("diagnostic-source").absolute()
PINS = ("lean-toolchain", "lake-manifest.json", "lakefile.lean")
BUILD = ["lake", "build", "StrictLeanPolicy", "axiomGate", "docFenceAudit",
         "+StrictLean.Checker.CheckerSelftest:olean",
         "+StrictLean.Checker.FreshChecker:olean", "+StrictLean.RegistryChecks:olean",
         "+StrictLean.Linter:olean", "+StrictLean.Checker.ProducerQualification:olean",
         "+StrictLean.Checker.HistoryQualification:olean",
         "+StrictLean.Checker.RuleExamples:olean",
         "+StrictLean.Checker.RuleExampleQualification:olean"]


def write(name, value):
    # Only status is replaced; individual receipts are never used as cached results.
    (RECEIPTS / f"{name}.json").write_text(json.dumps(value, sort_keys=True) + "\n")


def command(args, cwd=None):
    return subprocess.check_output(args, cwd=cwd, text=True).strip()


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def source_digest(root):
    """Hash all non-build inputs, including ignored/untracked source/config bytes.

    .git is separately observed. .lake contains generated configuration/artifacts
    and separately observed dependencies. No fixed Lean module list is inferred.
    """
    result = hashlib.sha256()
    count = 0
    for directory, dirs, files in os.walk(root):
        dirs[:] = sorted(d for d in dirs if d not in (".git", ".lake"))
        if any((Path(directory) / d).is_symlink() for d in dirs):
            raise RuntimeError("source directory symlink cannot be inventoried")
        for name in sorted(files):
            path = Path(directory) / name
            if path.is_symlink():
                raise RuntimeError(f"unbounded source symlink: {path}")
            result.update(str(path.relative_to(root)).encode() + b"\0")
            result.update(bytes.fromhex(digest(path)))
            count += 1
    return {"sha256": result.hexdigest(), "files": count}


def identity(root, revision):
    head = command(["git", "rev-parse", "HEAD"], root)
    dirty = command(["git", "status", "--porcelain", "--untracked-files=all"], root)
    if head != revision or dirty:
        raise RuntimeError(f"unexpected revision/dirty state at {root}: {head} {dirty}")
    dependencies = {}
    manifest = json.loads((root / "lake-manifest.json").read_text())
    package_root = root / manifest["packagesDir"]
    expected = {p["name"] for p in manifest["packages"]}
    if {p.name for p in package_root.iterdir()} != expected:
        raise RuntimeError("dependency inventory differs from pinned manifest")
    for package in manifest["packages"]:
        dep = package_root / package["name"]
        if dep.is_symlink():
            raise RuntimeError("shared mutable dependency symlink")
        dep_head = command(["git", "rev-parse", "HEAD"], dep)
        dep_dirty = command(["git", "status", "--porcelain", "--untracked-files=all"], dep)
        if dep_head != package["rev"] or dep_dirty:
            raise RuntimeError(f"dependency pin/dirty mismatch: {package['name']}")
        dependencies[package["name"]] = {
            "head": dep_head, "dirty": dep_dirty, "source": source_digest(dep)}
    return {"head": head, "tree": command(["git", "rev-parse", "HEAD^{tree}"], root),
            "dirty": dirty, "source": source_digest(root),
            "pins": {p: digest(root / p) for p in PINS}, "dependencies": dependencies}


def toolchain():
    pin = (SOURCE / "lean-toolchain").read_text().strip()
    if pin != "leanprover/lean4:v4.33.1":
        raise RuntimeError("unexpected toolchain pin")
    binary_dir = Path.home() / ".elan/toolchains/leanprover--lean4---v4.33.1/bin"
    for name in ("lean", "lake"):
        if not (binary_dir / name).is_file():
            raise RuntimeError("required pinned toolchain cache unavailable")
    os.environ["PATH"] = str(binary_dir) + os.pathsep + os.environ["PATH"]
    return {name: {"sha256": digest(binary_dir / name),
                   "version": command([str(binary_dir / name), "--version"])}
            for name in ("lean", "lake")}


def setup():
    started = float((BASE / "setup-start").read_text())
    pins = {p: (SOURCE / p).read_bytes() for p in PINS}
    for label, revision in RUNS:
        root = BASE / label
        # New independent repositories, objects and writable dependency copies.
        subprocess.run(["git", "clone", "--no-hardlinks", "--no-checkout",
                        str(SOURCE), str(root)], check=True)
        subprocess.run(["git", "checkout", "--detach", revision], cwd=root, check=True)
        if any((root / p).read_bytes() != pins[p] for p in PINS):
            raise RuntimeError("A/B setup pins differ; no cross-pin cache fallback")
        (root / ".lake").mkdir()
        shutil.copytree(Path(".lake/packages"), root / ".lake/packages", symlinks=False)
        if (root / ".lake/build").exists():
            raise RuntimeError("root build must be absent")
        write(f"{label}-setup", identity(root, revision))
    write("toolchain", toolchain())
    elapsed = time.time() - started
    if elapsed >= 300:
        raise RuntimeError("total setup300 exhausted")
    write("setup", {"status": "COMPLETE", "elapsed_seconds": elapsed})
    write("status", {"status": "INCOMPLETE", "phase": "awaiting root-only measurement"})


def resources():
    # Record the effective hierarchy, not just the leaf quota: an ancestor may cap it.
    groups = Path("/proc/self/cgroup").read_text().splitlines()
    relative = next(line[3:] for line in groups if line.startswith("0::"))
    mount = Path("/sys/fs/cgroup")
    leaf = mount / relative.lstrip("/")
    if not leaf.is_relative_to(mount) or not leaf.exists():
        raise RuntimeError("cgroup v2 metrics unavailable")
    quotas = {}
    for group in [leaf, *leaf.parents]:
        if not group.is_relative_to(mount):
            break
        # The cgroup root has no cpu.max; it has no parent-imposed quota.
        quotas[str(group)] = {"cpu.stat": (group / "cpu.stat").read_text(),
                              "cpu.max": ((group / "cpu.max").read_text()
                                          if group != mount else "root: no parent quota")}
    return {"cgroups": quotas, "affinity": sorted(os.sched_getaffinity(0)),
            "observations": {str(p): p.read_text() for p in
                             [Path("/proc/stat"), Path("/proc/diskstats"),
                              Path("/proc/meminfo"), Path("/proc/loadavg"),
                              Path("/proc/pressure/cpu"), Path("/proc/pressure/io"),
                              Path("/proc/pressure/memory")]}}


def measure():
    # GNU timeout is our process-group leader. No descendant creates another group.
    if os.getpgrp() != os.getppid():
        raise RuntimeError("measure must be a direct child of the outer GNU timeout")
    signal.signal(signal.SIGALRM, lambda *_: os.killpg(os.getpgrp(), signal.SIGKILL))
    if json.loads((RECEIPTS / "setup.json").read_text())["status"] != "COMPLETE":
        raise RuntimeError("missing complete setup")
    if toolchain() != json.loads((RECEIPTS / "toolchain.json").read_text()):
        raise RuntimeError("toolchain changed")
    # Check ALL roots before the first build; never accept a prior root trace.
    for label, _ in RUNS:
        if (BASE / label / ".lake/build").exists():
            raise RuntimeError("preexisting root outputs")
    timings = []
    for label, revision in RUNS:
        root = BASE / label
        write("status", {"status": "INCOMPLETE", "phase": label})
        before = identity(root, revision)
        if before != json.loads((RECEIPTS / f"{label}-setup.json").read_text()):
            raise RuntimeError("inputs changed since setup")
        write(f"{label}-before", {"identity": before, "resources": resources()})
        metrics = RECEIPTS / f"{label}-time.txt"
        # GNU time waits for Lake; wait4 accounting includes its reaped descendants.
        # A 120s alarm kills the same outer group, including all compiler children.
        # No nested timeout group can escape the outer420 kill.
        start = time.monotonic()
        signal.setitimer(signal.ITIMER_REAL, 120)
        with (RECEIPTS / f"{label}-build.log").open("w") as log:
            completed = subprocess.run(
                ["/usr/bin/time", "-f", "%e %U %S %M %x", "-o", str(metrics), *BUILD],
                cwd=root, stdout=log, stderr=subprocess.STDOUT)
        signal.setitimer(signal.ITIMER_REAL, 0)
        elapsed = time.monotonic() - start
        write(f"{label}-exit", {"returncode": completed.returncode, "wall_seconds": elapsed})
        if completed.returncode != 0:
            raise RuntimeError(f"{label} build failed; stopping")
        after = identity(root, revision)
        write(f"{label}-after", {"identity": after, "resources": resources()})
        if completed.returncode != 0 or after != before:
            raise RuntimeError(f"{label} failed/timed out or inputs changed; stopping")
        values = metrics.read_text().split()
        if len(values) != 5:
            raise RuntimeError("incomplete process-tree resource metrics")
        wall, user, system, rss, exit_code = map(float, values)
        if not all(math.isfinite(v) for v in (wall, user, system, rss, exit_code)) or \
                wall <= 0 or user <= 0 or system < 0 or rss <= 0 or exit_code != 0:
            raise RuntimeError("invalid process-tree resource metrics")
        producer_path = RECEIPTS / f"{label}-producer.json"
        subprocess.run([str(root / ".lake/build/bin/axiomGate"), "--registry-out",
                        str(producer_path)], cwd=root, check=True)
        producer = json.loads(producer_path.read_text())
        if producer["sourceRevision"] != revision or producer["toolchain"] != "4.33.1" \
                or not producer["producerVersion"]:
            raise RuntimeError("actual built producer identity mismatch")
        write(f"{label}-measurement", {
            "wall_seconds": wall, "process_tree_user_seconds": user,
            "process_tree_system_seconds": system, "peak_single_process_rss_kib": rss,
            "binary_sha256": digest(root / ".lake/build/bin/axiomGate"),
            "producer": {k: producer[k] for k in
                         ("sourceRevision", "producerVersion", "toolchain")}})
        timings.append(wall)
    a1, b, a2 = timings
    write("status", {"status": "COLLECTED", "scope": "root-only; not acceptance",
                     "wall_seconds_A_B_A": timings,
                     "endpoint_ratio": max(a1, a2) / min(a1, a2),
                     "B_over_A1": b / a1, "B_over_A2": b / a2,
                     "B_over_bracket_mean": b / ((a1 + a2) / 2),
                     "interpretation": "PENDING resource comparability review by outer worker"})


if __name__ == "__main__":
    try:
        if sys.argv[1:] == ["setup"]:
            setup()
        elif sys.argv[1:] == ["measure"]:
            measure()
        else:
            raise RuntimeError("expected setup or measure")
    except Exception as error:
        # SIGKILL cannot execute this handler: the preceding INCOMPLETE remains.
        write("status", {"status": "INCOMPLETE", "reason": str(error)})
        if sys.argv[1:] == ["measure"] and os.getpgrp() == os.getppid():
            os.killpg(os.getpgrp(), signal.SIGKILL)
        raise
