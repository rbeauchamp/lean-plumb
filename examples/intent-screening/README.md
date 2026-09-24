# Intent-screening calibration evidence

Evidence for the opt-in [intent screen](../../docs/guides/intent-screening.md) (issue #58).
Nothing here is used in acceptance, and no file contains an API key.

| File | Content |
| --- | --- |
| `calibration.json` | Configuration of the calibration runs: pinned model `jev-1.13.0` and this cache. |
| `screen.json` | Sample screening configuration. It sets thresholds only for the judgments that met the pre-registered criteria. |
| `test-report.md`, `test-records.json` | Report and per-answer evidence rows of the single test-split run, recomputed offline after the disclosed label erratum. The runner writes everything except the first line, which records the live run's spend by hand; an offline rerun prints its own cache-only usage line there. |
| `test-report-as-run.md` | The test report exactly as the live run wrote it, before the erratum. |
| `dev-report.md`, `dev-records.json` | The same for the development split, used only to debug the runner and wording. |
| `cache/` | One file per request, named by the SHA-256 of the exact request. Each file holds the request (model, state, questions) and the service's response. |

The cached answers let anyone reproduce the reports without a key or a network call:

```text
lake exe intentScreen calibrate --config examples/intent-screening/calibration.json --split test --report out.md --records out.json
```

The corpus and its labels are in [`lean/Plumb/Screen/Corpus.lean`](../../lean/Plumb/Screen/Corpus.lean).
