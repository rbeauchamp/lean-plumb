# CI timeout repair: execution admission

Subject: the CI-phase repair over `dab4ac2080798ebe1f6bd50826daa4c7b994a224`
for PR #30, check `verify` / `104646826775`. Publication and hosted rechecking
belong to the outer pipeline; this record does not claim a new reviewed commit or
passing hosted CI.

## Cause and unchanged contract

The supplied Linux run reached its hard 420-second deadline after collecting the
`StrictLeanPolicy` declaration report. A three-second local native stack sample
identified repeated array membership scans inside `admitExecution`, especially
execution-closure validity. Endpoint and discovery checks repeatedly searched the
same arrays.

`StrictLeanPolicy/Admission.lean` now constructs local `Std.ExtHashSet.ofList`
indices before repeated queries. Each `decidable_of_iff` uses
`Std.ExtHashSet.mem_ofList` and lawful structural equality to produce a decision
for the **original** array-membership proposition. `DiscoveryOK`, closure/root
`Valid`, canonical ordering, duplicate refusal, retained observations and public
transport remain unchanged. Hash collisions do not authorize membership. Generated
C inspection confirmed that indices are shared outside their query loops.
Compiler/runtime execution, including Lean's native name hashing, remains trusted.
The workflow and 420-second limit are unchanged.

## Final evidence

- Lean 4.33.1, commit `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`,
  `arm64-apple-darwin24.6.0`; Mathlib source/lock revision
  `0df444a360eaa60ab8c11dca51a86af692955474`.
- `lake build StrictLeanPolicy axiomGate docFenceAudit +StrictLean.Checker.HistoryQualification:olean`:
  PASS, 100 jobs.
- Compiler `#print axioms`: the three changed decision instances
  (`instDecidableDiscoveryOK`, `instDecidableValid`,
  `instDecidableExecutionRootValid`) use exactly `propext`, `Classical.choice`,
  `Quot.sound`. `discovery_induction` retains exactly `propext`, `Quot.sound`;
  `nodes_induction` and `admitExecution_preserves` retain the three Standard-Logical
  axioms. No native-proof shortcut or project axiom was introduced.
- `python3 scripts/history_checks.py`: PASS, 17 public project/incremental/file
  controls and 17 actual transport mutation/restoration records. These qualify
  operational refusal paths; the decision types establish membership preservation
  for arbitrary supplied records.
- `./scripts/verify.sh`: PASS in **239.368 seconds**, exit 0, after removing root
  `.lake/build` from the build path and provisioning the pinned dependency cache.
  All 109 build jobs, registry controls, 36 native bridge controls, fresh owned
  declaration/axiom admission and all 94 fences completed. Fence results:
  70/70 conforming positives, 23/23 intended negatives, 1/1 classified teaching.
  Complete declaration audit: 79.906 seconds; policy declaration inspection:
  44.103 seconds. These are observations on this Mac, not Linux timing guarantees.
- Fresh-context Codex/gpt-6-astra reviewer `ci_repair_review`, high effort:
  focused final hash-index repair review CLEAN. It inspected exact membership
  equivalence, lawful equality/hash assumptions, generated-code sharing and axiom
  evidence. Its earlier tree-index prototype review is superseded. This is not
  another full-branch review or a full semantic-conformance claim.

Fresh acceptance covered these exact Lake-owned modules:

| Surface | Modules | Declarations | Execution roots |
| --- | --- | ---: | ---: |
| Audit | Audit, Audit.Research, Audit.Basic, Audit.Economy, Audit.Server, Audit.DocPrelude, Audit.DocClaims | 313 | 111 |
| AuditApp | AuditApp, AuditApp.Limiter, AuditApp.Refinement, AuditApp.Demo, Main | 197 | 42 |
| StrictLeanPolicy | StrictLeanPolicy, StrictLeanPolicy.Specification, StrictLeanPolicy.Identity, StrictLeanPolicy.Claim, StrictLeanPolicy.Decision, StrictLeanPolicy.Pattern, StrictLeanPolicy.Foundation, StrictLeanPolicy.Execution, StrictLeanPolicy.Admission, StrictLeanPolicy.Domain, StrictLeanPolicy.RoleSpecification, StrictLeanPolicy.Plan, StrictLeanPolicy.Collections, StrictLeanPolicy.Codec, StrictLeanPolicy.Observation, StrictLeanPolicy.ResultState, StrictLeanPolicy.Acceptance | 3639 | 1423 |

The initial local acceptance attempt was stopped during dependency rebuilding and
was not acceptance evidence. An intermediate qualification run overlapped binary
rebuilding and failed application-path resolution; the final uninterrupted run
above supersedes it. No incomplete run is counted as PASS. Exact-head hosted CI
remains required after the outer executor records the repair.
