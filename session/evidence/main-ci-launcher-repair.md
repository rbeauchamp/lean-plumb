# Main CI native-control launcher repair

2026-09-16 implementation checkpoint, based on
`2f57d2e2b6a42db4b6c3c3923e39b10050458127` (tree
`9f098ddf0bb375e45f45d252cdf5217d4ec157e0`). This is a CI repair before issue7,
not implementation of its global Accepted boundary. Its tooling-census design
decision remains open. No Lean policy, source-admission, rule or acceptance-mode
contract changes here.

## Failure and scope

The [main run](https://github.com/rbeauchamp/strict-lean/actions/runs/35123572354)
was killed at420s during documentation inspection. The
[passing run](https://github.com/rbeauchamp/strict-lean/actions/runs/35120672150)
checked out synthetic merge `c142c3c4582c8276622e1dac5380f33d1796ff2d` for head
`59daadd0f096bcf6141dd9ad43cabed57bbf4bbc`. All three source trees match. Passing
ordinary acceptance took approximately396.198s; main accumulated22.926s more
before fence inspection and then progressed more slowly through that phase.
Exit137 and the timeout log identify deadline exhaustion, not an established OOM,
cache, runner or source-regression cause. The physical cause remains unresolved.

The original native-control script ran36 independent `lake env lean` commands
and one `lake env printenv LEAN_PATH`. The repair captures actual Lake output via
the existing `/usr/bin/env -0` on supported Ubuntu/macOS, preserving arbitrary
value delimiters without logging inherited values. Reuse is confined to one
launcher instance and keyed by the full parent environment; the workspace and
pins must remain fixed while these sequential controls run. The imported controls
create a second environment, including Lake's original repeated path prefixes.
Relative executable lookup is evaluated at the child's cwd; the captured child
environment is unchanged. Original printenv whitespace consumption is retained.

Each control still writes its source and launches a distinct Lean process with
the original arguments, options, output path,30s timeout, JSON/error/warning checks
and restoration behavior. Captures also have30s caps; missing or malformed capture,
missing executable, child failure or timeout cannot yield a cached success.
No verdict, elaboration or shared mutable Lean environment is reused. The proof
and OS/runtime trust boundaries are unchanged; no theorem about launcher timing
or compiled process semantics is claimed.

## Focused evidence

Pinned Lean4.33.1, Mathlib `0df444a360eaa60ab8c11dca51a86af692955474`;
local host macOS27 arm64. On existing built inputs, the production-launcher pair:

```sh
gtimeout --signal=KILL 180s python3 scripts/native_launcher_diagnostic.py
```

completed in75.427s. Both passes ran all36 original controls and original
assertions. The diagnostic compared exact source hashes, Lean argument arrays,
effective environments/executables, exit statuses, stdout and stderr. All matched.
Baseline52.922s excludes its extra environment-observation probes; candidate16.001s
includes required captures, an observed36.920s reduction. Raw local records are
`tmp/native-launcher-diagnostic.json`; they contain control diagnostics, not inherited
environment values. Both skill validators, Python syntax and whitespace checks passed. All13 original
assertion ASTs are unchanged against the baseline. Local raw-report SHA256:
`ea47d7d118bea7b86e18710a9e0c365e64820988c07a5b9f999007f0bb8cec68`.
Subsequent edits retain the original whitespace stripping and ensure a failed/killed
diagnostic cannot leave an earlier successful report at its output path; neither changes
the measured control inputs or launch process for the observed whitespace-free paths.

This baseline-first comparison is not randomized or a fresh-source acceptance run.
Page-cache, scheduler and ordering effects are not separately isolated. Do not infer
Linux savings or a universal deadline guarantee from it. An earlier scratch prototype
also passed36 exact controls (88.731s total;62.784s versus19.175s); that observation
does not replace qualification of this production implementation.

## Remaining delivery gates

Ordinary PR/main CI retains all36 original functional controls inside complete
cold-root acceptance and all pre-existing required qualification. The paired diagnostic
is retained for focused repair qualification under the separate180s process-group cap;
it is not a recurring CI step. It refuses control or environment mismatches and reports
timing separately, without requiring a positive delta for functional PASS. Scheduling
and platform effects limit timing observations; a nonpositive delta is not a correctness
failure. Linux paired speedup remains **UNRUN**. Actual Linux functional controls and
the full required gate must qualify the repair; no cross-platform speedup or historical
physical attribution is established by the local pair.

Full no-mistakes independent review, a complete cold-root `./scripts/verify.sh`
within its unchanged420s deadline, exact-head hosted checks and integrated-main push
CI are pending. No external-adopter or broad diagnostic capability changed; unrun
campaigns are not PASS. Firstmate owns merge and reconciliation. The continuation
handoff must be updated through delivery to distinguish closed13, this repair and
the still-open issue7 contract decision; historical checkpoints are not current status.
