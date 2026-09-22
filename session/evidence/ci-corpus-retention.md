# Corpus admission retention repair

Review-phase repair over `a35426fae553dac8d7e32a2f85ccc2d10cf7c6dd`,
2026-09-22. The reported defect was present: exceptional scratch cleanup deleted
the current admission envelope, while the initial receipt omitted the selected
rules and captured checker sources.

`RuleExamples.check` now saves one `INCOMPLETE` baseline immediately after
`checkerBefore` capture and before scratch allocation. It records the exact
validated selection, full-selection flag, attempt, raw directory and initial
checker snapshot. The pre-setup invalidation remains. `admitRecord` now saves
its single `current.json` under that attempt's durable raw directory before
invoking the unchanged qualifier. Fresh `checkerAfter`, record contents and
refusal order are unchanged. There are no growing-prefix writes.

An independent fresh-context source review found no remaining defect within
this repair. It traced exceptional producer joins and scratch cleanup, expected
refusal/restoration order, final qualification, raw validation and PASS after
cleanup. The full campaign still structurally requires 65 productions,
79 admissions and 72 raw validations. Those counts were not exercised here.

## Focused verification

`lake build StrictLean.Qualification.RuleExamples ruleExampleQualification`
passed (118 jobs). Lean was 4.34.0, compiler
`293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`, arm64-apple-darwin24.6.0.
Resolved Mathlib was `5ed2965256430c3649e86755f9576b54eca72435`.

A temporary native Lean probe executed an unchanged copy of the repaired
module with appended IO assertions, allowing access to its private adapter
without changing production visibility. Both observations below passed:

- Public `check`, on an isolated two-rule fixture, replaced an old PASS with
  the exact baseline for both an explicit one-rule selection and selection
  `none`. A directory deliberately supplied where a configuration file was
  required caused error 21 after capture. Exact JSON readback established the
  retained selection, full-selection flag, attempt and checker snapshot;
  scratch was absent after the failure. This was not a complete corpus run.
- Actual `admitRecord`, with ordinary and derived inputs, submitted a changed
  checker snapshot to the native `ruleExampleQualification --record` entrypoint.
  It refused with `checker sources changed`. After exceptional scratch cleanup,
  exact JSON readback established the original `checkerBefore`, actual changed
  `checkerAfter`, submitted record, and derived control's origin/mutation record.

The probe's initial five unsuccessful attempts are retained as
`tmp/retention-focused-behavior-attempt1.log` through `attempt5.log`: two probe
elaboration errors, a failed setup assertion, an interpreter assertion while
loading the fixture workspace, and an overly specific expected-error assertion.
The corrected native probe exited 0. No attempt reached its time limit; production
source remained unchanged throughout these probe corrections. Temporary probe
sources, native build and fixtures were removed; logs remain.

Input and successful log SHA256s:

- `lean/StrictLean/Qualification/RuleExamples.lean`:
  `1f551e704b4c5a10197aecf8e8f0589cdfcbcbfdaa74836c237239aa1b655cfe`.
- `tmp/retention-focused-build.log`:
  `385d5f2e49c096a4cda9f24d9d0a6469c3cc9c311a0747d5df23fea65b5f8ef9`.
- `tmp/retention-focused-behavior.log`:
  `c3be1da7bb60fbc461c540217d359a12d41f643fc33158e0e6ae615afd7904bd`.

This is operational retention evidence under the existing filesystem/process
trust boundary, not a new universal IO theorem or declaration/axiom audit.
Previous successful and failed campaign receipts retain their original request
identities. They are not promoted to this changed input. Full corpus, cold
ordinary acceptance and exact-head CI remain with the outer pipeline; this
review phase ran none of those gates and changed no deadline or policy check.
