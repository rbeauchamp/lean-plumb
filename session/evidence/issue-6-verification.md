# Issue 6: executable policy proof verification

This is scoped delivery evidence, not full semantic conformance or an accepted-result
certificate. [The inventory](issue-6-inventory.json) records exact owned modules,
declarations and observed transitive axiom sets, plus rendered elaborated types and
universe parameters for pure-policy theorems. Its display names and hashes are
observations, not structural input keys or proof of extraction authenticity.

## Scope and checks

- Lean 4.33.1, compiler `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`;
  Mathlib `0df444a360eaa60ab8c11dca51a86af692955474`.
- Final `./scripts/verify.sh`: PASS in 157.72 seconds, within the unpartitioned
  420-second deadline, including the added outcome proofs. Documentation passed
  70/70 conforming positive, 23/23 negative and 1/1 teaching examples.
- Current fresh declaration census: 3 positive libraries, 1 associated executable,
  29 owned modules and 4,022 declarations. StrictLeanPolicy contributes 17 modules
  and 3,512 declarations, including generated declarations and empty umbrella modules.
  Every observed axiom is in `propext`, `Quot.sound`, `Classical.choice`.
- `./scripts/verify.sh diagnostics fixtures`: PASS in 125 seconds, all 60 fixtures,
  scanner and 28 Markdown corpus cases, plus 11 execution-policy cases. This uses
  the actual generated-role validators, declaration/execution decisions and matcher.
  Subsequent changes added proofs and new acceptance relations, leaving these
  exercised detector definitions and fixtures unchanged; this scoped evidence is reused.
- Init/Std-only policy import boundary retained; operational checker remains excluded.
  The manifest is Standard-Logical as an upper bound. The JSON reports exact sets
  separately for each declaration; explicit theorem assumptions are in their types.

## Guarantees and implementation linkage

The [proof guide](../../docs/guides/policy-proofs.md) maps actual declarations and
callers. Machine-checked families cover least foundation/minimality and set
extensionality; six-way classifier outcomes; generated-role iff relations;
declaration success and exact first-failure priority; execution success iff;
result insertion/refusal/frame; fixed-plan acceptance soundness/completeness and
exact report identity; and the restricted diagnostic pattern relation.

The independent specifications state named requirements. The actual role validators
decide them; declaration acceptance uses the actual decision through its iff proof.
ExactlyOne's singleton-head decision has a proved correspondence and avoids repeated
witness scans. Current classifier/diagnostic outcome equivalence is universal over
its stated domain. Prior-role guard equivalence on admitted unique-name inventories
is source review plus focused qualification; no old-loop equivalence on malformed
arrays or universal renderer-string/summary-count theorem is claimed.

## Independent review

Separate fresh contexts reviewed generated-role guard preservation, acceptance
semantics, operational consumers, and foundation/decision/state/capstone proofs.
Focused re-review closed repeated witness scans, omitted registered roots, excluded
root imports, history source substitution, and grouped-example transcript binding.
Final proof review also required and verified exact rejected-outcome/precedence
relations. These reviews found no remaining scoped semantic/implementation defect.
Documentation/rule-ID traceability and successor handoff reviews are also CLEAN.
The #7/#10 bodies contain reviewed self-contained signatures, domains, actual
callers, evidence and remaining integration obligations.

Reviewed checklist concerns include applicable SCOPE-02/03/05, TYPE-01–05,
THEOREM-01/03/04/06/07, FOUND-03/04, DECL-03/04, COMP-01/03/04,
BUILD-03, DOC-01/02/04/05 and DOGFOOD-03/04. The fixture campaign supplies affected
MUT qualification; unrun broader campaigns are not PASS. Hosted CI on the reviewed
PR head remains a separate integration gate recorded on GitHub.

## Remaining boundaries

POLICY-04 (#7) must acquire/freeze truthful complete external census, populate the
concrete plan/observations, validate completed worker packets and make every audit
success renderer/exit consume Accepted.report, with same-snapshot project/docs
composition. #13 retains ordinary-root selector/closure qualification, including
the existing concern about source-supplied auxiliary/matcher/noConfusion metadata.
Recorded contract roots now have forward plan coverage; this does not establish
all ordinary roots were observed. Registry identities and real diagnostic locations
still require the #7/#12/#13 adapter.

Compiler observations, replay/defeq truth, files, processes, JSON parsing, source
coordinates and native-runtime trust remain explicit operational boundaries.
All applicable residual semantic accounts remain required. No new normative rule,
rule ID, website page, full-audit claim or optional graph claim is introduced.
The optional serialized-graph and long transport/adopter/environment/build campaigns
were not run for this scope. Existing controls remain; no check was retired.
