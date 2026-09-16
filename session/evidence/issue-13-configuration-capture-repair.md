# Initial configuration capture: R7 repair

Scope: review-phase repair against
`9b18ab42777d5717612cb70bbd58ffbd6b4d64a4`, relative to engine base
`0df758a92856b6a268882eada641773af5684d80`. No issue completion, integration,
ordinary acceptance, or hosted verification is claimed by this record.

R7 was an error-boundary defect: the initial configuration read could throw before
entering the shared terminal diagnostic handler. The handler is now shared by
initial capture and audit execution. Its original IO detail, manifest-error
classification and source-account serialization remain intact. Initial capture
failure has no frozen configuration or captured sources: it reports SL2001/incomplete
with an empty source account, without fabricating request/effective evidence.
After successful capture, the existing frozen-input guard still surrounds the audit
and retains its SL2005 refusal semantics. No admission predicate or pure proof changed.

## Focused evidence

Toolchain: Lean 4.33.1, compiler
`819816b2e0a3bf405af45ae5c7af2491d8f5bee6`. Root dependency resolution retained
Mathlib `0df444a360eaa60ab8c11dca51a86af692955474`; the disposable controls use
Core-only projects and do not claim Mathlib analysis.

- `lake build axiomGate`: PASS; final annotated handler rebuilt successfully.
  This compiles the changed operational owner, not a new universal IO proof or
  a declaration/axiom conformance audit.
- Original HEAD source executed through its public `main` with
  `lake env lean --run`: a directory-valued manifest reproduced exit failure with
  the original directory IO error, empty diagnostics, and the stale
  `audit has not completed` placeholder. The isolated source probe was removed.
- `python3 scripts/configuration_capture_checks.py`: six controls PASS. Both
  `freshProject` and `freshFile` exercise a positive, the isolated directory mutation,
  and a restored positive with fresh root build state. Negatives require SL2001,
  incomplete status, original directory IO detail in stderr and unresolved evidence,
  authentic project location, empty source account, and no request/effective account.
  Positives require completion, no findings, and exact source bytes at the emitted
  effective root. This is bounded path qualification, not all IO failures or modes.

Raw local logs are retained under `tmp/r7-review/`: `build.log`, `build-final.log`,
`before.log`, `before-result.json`, and `controls-qualified.log`. Two earlier control
runs failed assertions in the new harness and remain in `controls.log` and
`controls-final.log`: fresh-project sources correctly used an isolated effective root,
and the original directory IO detail did not include a filename. Those failed runs
are not PASS evidence. The corrected assertions retain exact source and IO evidence.

## Independent review and remaining gates

Fresh-context reviewer `/root/r7_review` was launched through the agent tool with
Codex model `gpt-6-astra` and reasoning effort `medium`. It read the local review skill
and returned scoped CLEAN for semantic/producer and operational error-path risks,
then confirmed the final handler annotation and control corrections. It performed
read-only review; the parent owned compilation and public controls. Applicable scope:
DECL-04, MUT-02 through MUT-04, and DOGFOOD-03; no full compliance verdict.

The earlier `117ec9fe` ordinary/hosted/corpus results in
[the corpus CI record](issue-13-corpus-ci-responsiveness.md) remain attributed to that
revision. They do not validate this changed initial-capture path. Existing source,
producer, corpus and pure-proof controls remain unchanged; unrun campaigns are not
relabelled PASS. Ordinary cold420 and exact-head hosted checks remain required in
their outer pipeline phases. Issue 13 reconciliation remains with Firstmate.
