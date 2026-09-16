#!/usr/bin/env python3
"""Paired launcher qualification on already-built inputs; not ordinary acceptance.

Run under an external 180-second process-group deadline. Baseline-first order is
not a controlled estimate of all cache/scheduler effects or a future time bound.
"""
from __future__ import annotations

import contextlib
import hashlib
import json
from pathlib import Path
import platform
import shutil
import subprocess
import sys
import tempfile
import time
import types

sys.dont_write_bytecode = True
import native_linter_checks as native


class RecordedLauncher(native.LeanLauncher):
    def __init__(self, legacy: bool) -> None:
        super().__init__()
        self.legacy = legacy
        self.records: list[dict] = []
        self.observed_environments: list[tuple[dict[str, str], str]] = []
        self.capture_seconds = 0.0

    def environment(self) -> tuple[dict[str, str], str]:
        start = time.monotonic()
        result = super().environment()
        self.capture_seconds += time.monotonic() - start
        return result

    def run(self, args: list[str]) -> subprocess.CompletedProcess[str]:
        # Baseline captures are instrumentation only; its child still runs through
        # the original Lake path. Compare full environments only in memory.
        environment = self.environment()
        start = time.monotonic()
        if self.legacy:
            result = subprocess.run(["lake", "env", "lean", *args], cwd=native.ROOT,
                                    text=True, capture_output=True, timeout=30)
        else:
            result = super().run(args)
        self.records.append({
            "label": Path(args[-1]).stem, "args": args,
            "sourceSha256": hashlib.sha256(Path(args[-1]).read_bytes()).hexdigest(),
            "returncode": result.returncode, "stdout": result.stdout, "stderr": result.stderr,
            "seconds": time.monotonic() - start,
        })
        self.observed_environments.append(environment)
        return result

    def lean_path(self) -> str:
        if self.legacy:
            return subprocess.run(["lake", "env", "printenv", "LEAN_PATH"], cwd=native.ROOT,
                                  text=True, capture_output=True, check=True, timeout=30).stdout.strip()
        return super().lean_path()


def main() -> None:
    report: dict = {"platform": platform.platform(), "runs": [], "equivalent": False,
                    "outcome": "INCOMPLETE"}
    output = native.ROOT / "tmp/native-launcher-diagnostic.json"
    output.unlink(missing_ok=True)
    launchers = []
    original_tempfile = native.tempfile
    started = time.monotonic()
    try:
        with tempfile.TemporaryDirectory(prefix="launcher-pair-", dir=native.ROOT / "tmp") as raw:
            controls = Path(raw) / "controls"

            @contextlib.contextmanager
            def scratch(**_kwargs):
                controls.mkdir()
                try:
                    yield str(controls)
                finally:
                    shutil.rmtree(controls)

            native.tempfile = types.SimpleNamespace(TemporaryDirectory=scratch)
            for legacy in (True, False):
                launcher = RecordedLauncher(legacy)
                launchers.append(launcher)
                run = {"legacy": legacy, "controls": launcher.records}
                report["runs"].append(run)
                start = time.monotonic()
                try:
                    native.main(launcher)
                finally:
                    run["seconds"] = time.monotonic() - start
                    run["captureSeconds"] = launcher.capture_seconds
                assert len(launcher.records) == 36, "control count changed"
            baseline, candidate = launchers
            for a, b in zip(baseline.records, candidate.records):
                for field in ("label", "args", "sourceSha256", "returncode", "stdout", "stderr"):
                    assert a[field] == b[field], (a["label"], field)
            assert baseline.observed_environments == candidate.observed_environments, \
                "effective environment/executable mismatch"
            report["equivalent"] = True
            # Remove only the baseline's extra observation cost; candidate capture
            # remains part of its real launch cost. No retries on slower results.
            before, after = report["runs"]
            report["baselineSecondsWithoutProbes"] = before["seconds"] - before["captureSeconds"]
            report["savedSeconds"] = report["baselineSecondsWithoutProbes"] - after["seconds"]
            report["outcome"] = "PASS"
            print(f"launcher diagnostic: PASS (36 exact controls; observed saving {report['savedSeconds']:.3f}s)")
    except BaseException:
        report["outcome"] = "FAIL"
        raise
    finally:
        native.tempfile = original_tempfile
        report["totalSeconds"] = time.monotonic() - started
        output.write_text(json.dumps(report, indent=2) + "\n")


if __name__ == "__main__":
    main()
