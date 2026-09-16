# Full-branch review and focused repair verification

Both reviewers independently started with fresh contexts using Codex `gpt-6-astra`,
supported `high` effort, and the repository-local review skill. Neither edited files,
ran builds/tests, delegated, or controlled the pipeline. They inspected the complete
branch comparison against `b64747b7ce16d5850c11f9798d46dfa5fe5b9b17`, at HEAD
`f7dfff2531fc0076d2558242dffcd46018c81455` plus the frozen R4 working-tree repair.
Their assignments were full-branch reviews, distinct from the earlier R1–R3 repair contexts.

## Semantic/specification review

Reviewer: `/root/branch_semantic_review`.

Covered the full changed domain/admission/closure proofs, actual walk enqueue channels,
producer/decoder reconciliation, project/file/documentation snapshot lifetimes, worker
source-map ownership, qualification, guide and handoff claims. Relevant lenses were
specification/refinement, invariant APIs, foundations and claim/trust boundaries.

The initial review found a P2 classification defect: a captured configuration file made
unreadable escaped `configurationUnchanged` as raw IO and became SL2001 instead of SL2005.
It also observed the original-file bypass independently identified by the compiler reviewer.
A tentative generic decoder-prefix concern was withdrawn: the reviewer found no supported
public trigger without fabricated transport or an additional producer defect.

The proof review found no further defect. `discovery_induction` is conditional induction
over strictly earlier parent witnesses; `nodes_induction` transfers through the exact
node/visit relation; `admitExecution_preserves` concerns the executed admission definition,
with `admitExecution_exact` retaining acceptance for valid inputs. These do not establish
external extraction completeness, source authenticity, native execution or global Accepted.

Focused follow-up after the repairs: **CLEAN**. Configuration recheck errors now preserve
path/IO detail under the source-evidence classification; the original file uses the shared
guard; combined mode checks parent snapshots before returning worker failure. Qualification
uses single-fault mutations, exact IDs/status/reasons and restored positives. The prior
full-branch proof and claim review remains applicable; no proof definition changed.

## Lean/compiler/transport review

Reviewer: `/root/branch_compiler_review`, independently initialized from the semantic reviewer.

Covered the complete implementation diff: actual traversal/enqueue channels, root/code
obligations, replay admission, producer and decoder reconciliation, worker request binding,
file/group/documentation snapshots, public error paths and qualification. Inspection of the
pinned Lean 4.33.1 IR collector confirmed `collectDecl` retains genuine self calls and
initializers without inserting the synthetic self dependency of `collectUsedDecls`.

The initial review found two P2 classification defects:

1. `auditFile` directly reread the frozen original path. Missing or unreadable standalone
   source outside the configured inventory therefore escaped the shared normalization.
2. Combined documentation mode returned an unsuccessful declaration worker before checking
   the parent's frozen inputs. Source failure during the claimed build could leave canonical
   JSON at its empty incomplete placeholder instead of preserving SL2005 and the IO detail.

Focused follow-up after the repairs: **CLEAN**. The original-file read now uses
`SourceBinding.unchanged`. Parent source/configuration checks run after the joined declaration
worker and before its early return. The new file/build controls exercise both findings,
initial missing-source SL2001 and restored positives. The follow-up also checked the local
configuration exception normalization. No further validated compiler/closure defect was found.

## Scope and remaining gates

These full-branch reviews plus their focused repair follow-ups are static source review,
not a full repository-conformance verdict or an ENGINE-01/#13 completion claim. Their
compiler, imported-library, filesystem and undetected change-and-restore assumptions remain.
The earlier `/root/repair_semantics` and `/root/repair_transport` reviews remain labelled
focused reviews; they are not being reclassified as full-branch evidence. A separate focused
R4 review by `/root/repair_transport` confirmed the initial shared-source normalization.

[Current repair verification](issue-13-source-read-repair.md) records the actual parent-owned
focused build/qualification. Ordinary420, authoritative test/lint phases, signed pipeline
commits, exact-head CI and protected integration remain with the outer executor.
