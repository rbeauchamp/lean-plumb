# CI main integration and inventory collision disposition

## Integrated identity

Assigned CI/ci-1 only in owning run `01M2QNJRBW9M8WC4ZNZ3QQHG8G`.
Starting clean HEAD: `6d40b592ac139e418c5b1a981e1f17e686fe44fe`.
Read-only `git ls-remote origin refs/heads/main` and local `origin/main` both
identified `259ebee37fd41146596df1d169bab94dbdcd78f9` at phase start.

Signed two-parent merge: `9f4734636ec8f4b60121258ee0e4d870b9ad6e74` (signature `G`).
Parents, in order: `6d40b592ac139e418c5b1a981e1f17e686fe44fe` and
`259ebee37fd41146596df1d169bab94dbdcd78f9`. Both ancestry checks passed.
No rebase, squash, reset, pipeline controls, publication, or caller edits occurred.

The only conflict was `lean/StrictLeanVerification.lean`: retained separate
producer/history recipes and adopted upstream's combined registry/native dispatch.
Ordinary420, separate producer420/history420, corpus, and site remain scheduled.
Fresh-context integration source review found no blocking defect. No unresolved
index entries remained and staged whitespace checks passed before committing.

Fixer observed PID 55192 argv: `codex exec -m gpt-6-astra -c
model_reasoning_effort="medium" ...`. Reviewer requested configuration was
gpt-6-astra/medium; the collaboration API exposed no distinct child launch argv.
Do not equate the enclosing process's argv with an observed child launch.

## Source diagnosis and semantic stop

The previous 332.41-second failure remains at
`tmp/ci-main-integration/cold420.log`; it was not a deadline failure.

`Acceptance.freeze` concatenates `report.declarations` from all independently
elaborated surfaces before `Policy.admitScope`. `InventoryValid` requires
`uniqueNames (decls.map (·.name))`; module qualification does not distinguish
these inventory keys. Both positively claimed modules define literal global
`main`: `StrictLeanVerification` and executable root `Main` (AuditApp).
The former arrived in upstream's Lean tooling migration; the premerge branch
had only the latter among its claimed surfaces. Each separately valid inventory
can therefore have an invalid union. This is a source-established conflict,
not yet a captured offending producer packet from the failed cold run.

Independent source diagnosis confirms that making either entrypoint private or
namespaced does not preserve behavior: pinned Lean's native EmitC.hasMainFn and
interpreter run_main select literal `main`. Interpreter source at the pinned
commit: https://raw.githubusercontent.com/leanprover/lean4/819816b2e0a3bf405af45ae5c7af2491d8f5bee6/src/library/ir_interpreter.cpp .

Changing uniqueness alone to `(module,name)` is insufficient: downstream policy,
role, and dependency lookups use name identity inside an admitted environment.
An implementation supporting both independent environments must preserve that
environment boundary through admission and proof-bearing composition. That is
a substantive acceptance-model decision, not a local inventory filter.

Per the explicit stop-on-new-semantic-choice instruction, no inventory predicate,
manifest, census, or acceptance behavior was weakened. No behavioral correction,
regression PASS, or machine-checked closure is claimed. The candidate counterfactual
is that either surface admits alone and their union refuses with duplicate main;
runtime confirmation remains INCOMPLETE. No new cold acceptance was attempted.

## Probe setup and evidence limitations

`tmp/ci-inventory-fix/` retains logs and the final Lean probe. The probe uses the
existing declaration-report worker and preserves requests/packets when produced.
It selects two suspected modules only; it does not claim full Lake census coverage.
Failed setup attempts are distinguished from substantive checker evidence:

- `probe-before.log`: interpreted Lake workspace access hit an interpreter
  assertion before input collection. Replaced this setup with explicit targeted
  module paths; did not change production discovery.
- `probe-before-2.log`: calling Environment.loadReport from `lean --run` could
  not locate the trusted checker library relative to that executable. Switched
  to the existing built axiomGate worker interface.
- `probe-before-3.log`: malformed structure-literal layout in the probe; fixed
  its indentation without changing the requested modules.
- `probe-before-4.log`: probe attempted Repr on an outcome without that instance;
  replaced the setup error rendering with a fixed refusal and raw packet retention.
- `probe-before-5.log`: required StrictLeanVerification root olean was absent.
  The earlier cold gate built that surface in its disposable project, not here.
  Started `lake build StrictLeanVerification +Main` to provision these targeted
  outputs. No full campaign was retried.

The probe has not yet captured the full failure witness. Input and source paths,
compiler/runtime extraction, external worker identity, filesystem freshness, and
compiled execution remain trusted operational boundaries. Counts and matching
source names do not establish admitted coverage.

The targeted build's fresh preflight found no compiler contention. Another fleet
then started Lean v4.34.0 (Lake PID 87867) while owned Lake PID 85792 was active.
After identifying the substantive semantic stop, sent SIGTERM only to the remaining
owned compiler PID 60133 and its Lake parent 85792. The build returned exit 143;
it is INTERRUPTED/INCOMPLETE, not a correctness or timing result. Earlier owned
compiler PIDs 92594, 92597, and 26096 had already exited. Final process checks found
none of those owned processes. Compiler allocation is released; no external
compiler was signaled. `target-build.log` retains partial progress. No further
producer probe, regression, diagnostic, or cold gate was launched.

## Remaining phase outcome

Merge conflict resolved; CI acceptance remains unresolved. A substantive decision
is needed on composing independently elaborated environments without weakening
identity or full coverage. Focused behavioral reproduction, implementation-linked
proof review, one changed-final-head cold420, and required diagnostics/hosted checks
remain outstanding. Outer executor alone owns subsequent phases/publication.
