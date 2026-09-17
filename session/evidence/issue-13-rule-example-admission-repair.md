# Rule-example admission repair: R1, R2, R3

Review-phase scope: worktree changes on `bc78fc1ea9e59e3ed531f822ffa36a02bee3bf9b`,
relative to base `0df758a92856b6a268882eada641773af5684d80`.
No pipeline control, commits, push, PR, CI, merge or ordinary acceptance was performed here.

## Findings and contracts

- R1 was valid: source membership and caller before/after equality did not establish
  the producer's effective claim, execution requirement or configuration. The producer
  now captures the actual parsed request and separately records effective configuration
  before auditing. Early terminal failures retain any effective configuration already
  captured. Qualification requires exact typed request equality, configuration equality
  under explicit project-root correspondence, and actual file/surface claim/execution
  agreement. Configuration absence and Lake package overrides are included. Combined
  `--with-docs` and configuration-relocation transformations are outside this example
  qualifier's admitted request domain. Ordinary checker support is not removed.
- R2 was valid: a successful documentation driver exit can mean positive, negative or
  trusted teaching. The driver now exposes actual per-fence classifications. Producer
  and qualifier share `admitPositiveClassifications`, requiring a nonempty array whose
  every member is positive, passing and complete. Negative/trusted successes remain
  classified; incomplete outcomes remain distinguishable.
- R3 was valid: the selected corpus rule was absent from demonstration admission.
  `DemonstrationRequest.rule` and `DemonstrationOK` now require an actual incomplete
  finding for that rule, preserving the entire diagnostic list. The existing four
  accepted-example kinds and separate diagnostic demonstrations remain unchanged.

These are contracts of the executed admission definitions, not claims of compiler,
filesystem, serialization or process authentication. Existing source positions, frozen
snapshots and trust boundaries remain. Full project `Accepted` is not constructed.

## Independent review

Two fresh-context reviewer launches explicitly selected `gpt-6-astra`, effort `high`;
launches were accepted by the collaboration tool.

- `pure_repair_review`: CLEAN for request equality, positive-classification admission,
  selected-rule demonstration admission and their actual-definition proofs.
- `operational_review`: CLEAN after repairs for early effective-configuration receipts,
  combined-mode identity, and SL1003's fixture dependency. The latter uses an absolute
  dependency path and preserves dependency source/configuration snapshots.

Relevant scoped checklist obligations: SCOPE-02/03/05, TYPE-01/02, THEOREM-01/03/06/07,
FOUND-02/03, DOC-04/05, MUT-01/02/03/04 and DOGFOOD-03. This is not a full matrix result.

## Focused verification

Pinned Lean: 4.33.1, compiler `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`.
Pinned Mathlib: `0df444a360eaa60ab8c11dca51a86af692955474`; the focused checker build
uses Lean/Core/Std, not a whole-Mathlib compilation or admission claim.

Command, with dependency provisioning inside the worktree:

```sh
lake build axiomGate ruleExamples +StrictLean.Checker.RuleExampleQualification:olean
python3 scripts/rule_example_checks.py --evidence tmp/rule-example-repair.json
```

The build passed. It includes Website and Documentation proof compilation and the
qualifier's nine named theorem-dependency checks against the Standard-Logical ceiling.
It does not establish full owned-declaration/axiom coverage for the repository.

The first three build attempts stopped before fixture execution: two request-constructor
syntax errors, then a missing namespace qualification and an inferred-Prop mode guard.
They were corrected without changing the intended contracts. Failure logs remain in
`tmp/rule-example-repair.log`, `tmp/rule-example-repair-round2.log` and
`tmp/rule-example-repair-round3.log`; the current run is
`tmp/rule-example-repair-round4.log`.

The focused command exited 0. The complete rule-example corpus passed all 60 phases
(fixed, intended violation/demonstration, and fresh restored positive for each of 20 IDs).
Eight additional control receipts were retained: authentic Standard-Logical output refused
against a Kernel-only request and a fresh restoration; authenticated trusted teaching and
a completed compiler-negative fence refused as positive corrections and a fresh restoration;
and selected-rule relabelling refused for each of SL2001, SL2005 and SL3001, with their
original receipts readmitted unchanged. The qualifier also ran its transport/request
mutations on every corpus record. Full observed receipt data is in
`tmp/rule-example-repair.json`; the final log ends in
`rule example campaign: PASS (20 selected rules; diagnostic evidence only)`.

The operational reviewer independently confirmed that the small compiler corrections
preserved the reviewed constructor field order, theorem reference and Boolean mode guard.
No implementation or fixture-runner input changed after the successful build/campaign.

Full ordinary cold-root acceptance under the unchanged hard 420-second deadline and
exact-head CI remain the outer executor's responsibility. No focused command substitutes
for those gates, and no full-repository conformance claim is made here.
