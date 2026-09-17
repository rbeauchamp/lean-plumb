# Review and closure

## Freeze the subject

Record the checkout, intended changes, and exact commit or comparison when available.
For a repository without commits, identify the staged tree; do not create a commit or
remote to satisfy review bookkeeping. Consult an issue only when one governs the task.
Use AGENTS.md for required reading, independent review, and verification policy.

For a diff, cover changed claims and their dependencies. Include a baseline defect when
it contradicts the claimed result; unrelated defects do not turn a scoped review into a
repository-wide audit. Full compliance covers every applicable module 9 row and surface.

## Independent review

For delivery PRs, assign the independent review required by AGENTS.md. Give reviewers the
frozen subject, requested outcome, raw artifacts, and relevant [lenses](lean-lens-contracts.md).
Keep discovery independent of the author's findings or earlier verdicts. For focused repair
verification, supply the finding and repair so the reviewer can check closure.

Reviewers do not edit shared files or delegate further. Separate materially distinct risks;
coordinate expensive commands through one owner to avoid competing builds. Collect assigned
reviews before modifying their frozen subject. If independent review is unavailable, report
that gate as incomplete while completing unaffected authorized work.

## Evidence and repairs

Check findings against the exact Lean claim and supported pin. A checker bypass repair needs
a positive control, an independent single-fault mutation rejected for the intended reason
through the public entry point, and a restored positive control. Wrong-reason failures do
not close the finding. Qualification observations do not prove universal checker correctness.

Keep prose, definitions, and checker policy aligned where they encode the same claim.
Preserve module 8's assurance boundary: custom or ambiguous evaluator paths cannot justify
generated-role exemptions; arbitrary process or trusted-plugin compromise is outside scope.

Choose checks from AGENTS.md and the applicable checklist rows:

| Changed claim | Evidence focus |
| --- | --- |
| Lean definitions or proof claims | Relevant compiler/proof checks and semantic review. |
| Settled conformance | Complete acceptance command plus applicable semantic rows. |
| Checker behavior or detection claims | Focused qualification of affected capabilities and invocation paths. |
| Optional serialized-graph claim | Supported fresh-checker evidence for that exact graph. |
| Instructions or editorial changes with unchanged Lean claims and inputs | References, instruction behavior, and scoped review. |

Reuse prior semantic or diagnostic evidence when its relevant inputs, toolchain, and claim
remain unchanged; identify the earlier snapshot and why it still applies. CI is a separate
exact-PR-head gate. AGENTS.md owns commands, deadlines, and integration requirements.
After integration, locate and await the main push workflow for the exact merge SHA.
Record its terminal outcome separately from reviewed-head/synthetic-merge checks;
failed, skipped or unfinished required stages leave delivery reconciliation open.

## Report and stop

For each finding, give its location, failed claim, evidence, applicable row when relevant,
and closure criterion. Distinguish standard nonconformance, Lean quality, and repository
quality. Optional teaching improvements are not automatically normative defects.

Report coverage and missing evidence at the requested scope. CLEAN means no validated defect
was found within that coverage. Apply the checklist Result Rule: demonstrated violations
are FAIL; missing or unfinished required evidence is INCOMPLETE when no violation is known.
PASS requires all applicable evidence. A full audit reports every applicable
row, supported pins, declaration/axiom coverage, execution boundaries, and relevant controls.

Finish authorized repairs and their verification. Do not confuse review success with merged
delivery, create new publication authority, or pass an explicit user stopping point. Name
any remaining gate and preserve the reviewed work when blocked.
