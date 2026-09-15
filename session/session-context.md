# Session context: Strict Lean Project 8

**Date:** 2026-09-15
**DESIGN-01 starting basis:** public `main`, `79851f567ac8c1000575b707630e7ea593bfccb0` (CATALOG-01 PR #19).
**Persistence / resume authority:** this handoff accompanies the DESIGN-01 delivery PR. Resume from the resulting public `main` after that PR merges; the starting basis above is not the eventual handoff HEAD.
**Working root:** `/Users/richard/Developer/github/strict-lean`.
**Repository:** `origin` is now `https://github.com/rbeauchamp/strict-lean.git`.
**Resume focus after this delivery merges:** [#5 policy-domain types](https://github.com/rbeauchamp/strict-lean/issues/5). #5–#7 implement the POLICY-01 policy types, proofs and complete-result integration; #13 also requires #5.

## Plan and completed work

[Project 8](https://github.com/users/rbeauchamp/projects/8) and the full live issue bodies are authoritative. Native dependencies govern prerequisites. #5 follows #4, #12 and #20 and is next in project order after this delivery. Optional #8/#9 never replace the core unit. Verify the completing POLICY-01, CATALOG-01 and DESIGN-01 PRs are integrated with passing checks/reviews before beginning #5.

POLICY-01 supplies `docs/guides/policy-acceptance.md`: actual success/data flow, independent claim/census/job coverage, noncircular policy predicates, pure `StrictLeanPolicy` library plan, typed role/codec boundaries and successor assignments. Independent semantic and source-flow reviews passed after repairs for documentation presence, policy-negative website examples and FreshChecker plan-only completion. New theorems remain planned; no whole-checker/runtime proof is claimed. Successor handoffs are copied to issue bodies before integration. Read the completing PR for final CI/review evidence.

PR #17 was a handoff-only change. Its negated closing phrase accidentally triggered issue #4 closure; the user authorized reopening and actual delivery. Avoid closing keywords next to issue references unless automatic closure is intended. PRODUCT-01 remains delivered through PR #16, source `e5bc6267fa44d03a174c10ba3711e9c32545dff2`, merge `6e3c68c2b93bfa874b5deb9e956befd366a2de0a`.

Maintained sources of technical decisions:

- [Linter architecture](../docs/guides/linter-architecture.md): typed registry/diagnostics, native integration, modes, trust boundaries, versioned links, selected Verso stack and delivery phases.
- [Policy acceptance](../docs/guides/policy-acceptance.md): exact planned predicates, identities, trust boundary, mandatory stages and migration.
- [Rule coverage](../docs/guides/rule-coverage.md): all 20 selected diagnostics, nine residual obligations and reconciliation of all 53 compliance rows.
- [Prototype instructions](../examples/rule-reference-prototype/README.md): actual commands, pinned dependencies, bounded experiment, evidence and limitations.
- [Original research archive, issue #3](https://github.com/rbeauchamp/strict-lean/issues/3): full original con-leche/con-ron report, retained as historical reference with current scope overriding obsolete recommendations.

PRODUCT-01 evidence: two independent fresh-context scoped reviews clean; focused successor handoff review clean after adding missing reproduction commands/evidence. Local ordinary acceptance passed within the enforced 420-second deadline (12 owned modules, 510 declarations, Audit/AuditApp Standard-Logical profiles, 70 positive examples, 23 intended negative failures, one trusted classification). Tool/fixture exclusions remain explicit. One-rule prototype and exact-head CI passed. This is scoped evidence, not full-linter completion or universal metaprogram correctness. No implementation changes occurred after the reviewed head before merge.

## Consolidation and local preservation

The root previously pointed to `strict-lean-preparation` at `9671c9678b724f2214400ca9d3122d601beb6957`. The public delivery lived in `tmp/issue11-delivery`. All tracked delivery docs/code were already integrated in public main, so switching root to public main brought them in without manual copying.

Preparation PR #1 remains open remotely; it was not closed, merged or deleted during consolidation. Its head `b35921dc587869c4baae36afdd0b3b3dde1fca3f` and old main are preserved in local `archive/preparation-pr-1` / `archive/preparation-main` branches and a verified complete `.local-state/session-2026-09-14/preparation.bundle`. Comparison found no unique Lean implementation or scripts to port from that PR (only later public additions, documentation and CI changes).

The clean delivery, Verso and Verso-template temporary clones were removed after preserving evidence. Root `.lake/packages` was the shared dependency target and was retained; the documentation dependency cache was moved into the root prototype's ignored site cache. Generated outputs and former build caches are not new verification evidence for changed inputs.

Local-only `.local-state/session-2026-09-14/` contains copied issue/project snapshots, acceptance log, prototype evidence/rendered output, review record, preparation bundle and a snapshot of `.lavish/`. Original `.lavish/con-leche-con-ron.md`, HTML, sources and project JSON remain at root. Original `tmp/axiom-report.json` and `tmp/detailed-report.json` were preserved. These local archives are not required to implement #5; its full live issue and maintained repository guides are authoritative. No unrelated artifacts belong in the handoff commit. Local research/archives are excluded using `.git/info/exclude`, not deleted or published.

## Ruled out and still unresolved

- Con-ron is excluded by the user; no Rust/Aeneas/Charon integration or automatic later phase.
- The product must be an actual Lean-native strict linter and linked website, not only prose and examples. Do not duplicate already-correct detectors or build a separate Lean parser.
- GitHub Pages from this repository and pinned Verso were selected. The bounded experiment succeeded; Docusaurus fallback is unnecessary, and no GitHub Wiki/manual site catalog should be introduced.
- Documentation Lean 4.33.0 and checker/example Lean 4.33.1 are deliberately separate. Exact checked fixture source is initially rendered as text; rendering does not recheck examples under the documentation semantics.
- `Probe.ownedConstants` inventories imported modules, not live current-document declarations. Production collection/scheduling remains #13. The retained prototype uses an explicit imported-module trigger.
- Lean's built-in named-error widget hardcodes Lean manual URLs; unsupported LSP `codeDescription` is not an available shortcut. The package widget compiles/registers and the textual URL is verified. Actual VS Code infoview interaction remains #14. Browser keyboard activation succeeded; Chrome CLI bridge startup and hidden-tab mouse actions failed. Browser evidence must not be relabeled editor evidence.
- No public rule website was deployed. Production Pages integration remains #15, integrated adopter experience #10. Optional con-leche external checking (#8/#9) does not gate core delivery.

## Standing user constraints

- “Preserve public repository’s 420 seconds.” This overrides stale supplied 360-second instructions for ordinary `./scripts/verify.sh`; no overrides, partitioning or grace periods. Website checks have a separate named budget.
- The 2026-09-15 attribution clarification supersedes blanket con-leche credit requirements. Preserve specific registry/policy design citations and actual adapted-code notices; unrelated issues/deliverables need no con-leche mention. See `docs/guides/design-influences.md`. Core issues use linter/policy terminology; #8/#9 remain optional con-leche research, and #3 is linked historical background outside the project board.
- “as you proceed through the project, update its status and the issue statuses and dependencies as needed.” Keep successor bodies self-contained; copy newly settled requirements before unblocking successors. Done requires integrated acceptance, not a plan or partial PR.
- “An ounce of math is worth a pound of computation.” Prefer invariant-preserving types/construction and proofs about executing definitions. Distinguish mathematical, machine-checked, observed, assumed and unresolved claims. Do not replace admission/qualification controls without accounting for their purpose.
- Standing authorization permits requested PR publication and merge after applicable checks/review and exact-head CI, without repeated approval. Preserve unrelated work and protections. No software release, visibility change, custom domain, paid service, or Lean fork is authorized by this handoff.

## CATALOG-01 delivery and evidence

The completing delivery supplies one closed twenty-rule registry, indexed diagnostics with validated source ranges and structural Lean names, schema-1 registry/result codecs, native/text/JSON consumers, website artifact validation and a migrated real prototype. `docs/guides/rule-registry.md` is the maintained API/migration contract; successor issue bodies receive its settled interface before integration. `--json-out` is the versioned result; `--legacy-json-out` preserves the old export. Full declaration/execution inventories remain in new results. `completed` describes the existing mechanical observation, not POLICY-01's future `Accepted` result or full semantic conformance.

Three independent fresh-context reviews covered registry/proofs, executing integration and delivery/adopter boundaries; focused repair reviews were clean. Nine public theorem dependencies were checked: two axiom-free, three using only `propext`, route injectivity using `propext` and `Quot.sound`, and rule/structural-name codec proofs within Standard-Logical. Operational controls are distinct from those universal theorems.

Final local ordinary acceptance passed in 84.26 seconds under the hard 420-second deadline: Lean 4.33.1, Mathlib `0df444a360eaa60ab8c11dca51a86af692955474`, Audit/AuditApp, 12 owned modules, 510 declarations, 70 positive examples, 23 intended negative examples and one trusted example. Registry and malformed-CLI controls passed. The migrated prototype passed in 28.74 seconds; documentation remains pinned to Lean 4.33.0/Verso. A separate non-Git adopter rebuilt the checker and exercised positive/negative file results and incremental project results, including checker-source revision identity. Exact-head CI and integration are recorded on the completing PR; verify them live. Optional long diagnostic campaigns were not rerun or claimed PASS. Production collection/editor UX, policy `Accepted` proofs and website deployment remain successor work.

## DESIGN-01 research delivery

Issue #20 added comparative ecosystem research and a concrete developer-experience contract.
Read `docs/guides/ecosystem-design.md` and `docs/guides/developer-experience.md` with the
maintained architecture. Lean already has native linters; the design combines local hooks,
semantic environment inspection and a Lake project driver, using the existing language
server/infoview. CA1416, Ruff and Pyrefly are illustrative references, alongside Clippy,
ESLint, HLint/HLS and Lean/Batteries/Mathlib; none is an exact-copy requirement.

Retain the twenty rules, pure policy/registry boundaries and Verso. New decisions cover
explicit configuration explanation, Mathlib-driver coexistence, scope-correct Lake arguments,
concise human rendering with lossless evidence, stale/pending feedback, searchable accessible
rule pages and no initial automatic source rewriting. Reuse established definitions and their
proofs where semantics match; use intended extension APIs and qualify any specialized internal
adapter. Move existing neutral diagnostic definitions out of the probe-only import chain before
public editor reuse, preserving the probe contamination guard. The guides distinguish source evidence,
the observed pinned API check, design inference and unverified production/user behavior.
Successor issue bodies receive settled decisions before integration; verify #20's completing
PR/reviews/CI and closure live before starting #5. No full-user study or new latency guarantee
is claimed. The ordinary 420-second deadline remains unchanged.

## Immediate next action and evidence gate

1. Verify origin, checkout/current main and worktree ownership. Read the full live #5 and its
   native blockers #4/#12/#20; confirm their completing PRs are integrated. Read AGENTS and
   maintained architecture, ecosystem-design, developer-experience, registry, coverage and
   policy-acceptance guides.
2. Implement #5's exact pure policy-domain contract on a scoped `codex/` branch. Keep diagnostic
   IDs separate from policy categories; preserve claim/snapshot/configuration origins without
   admitting presentation or configuration-query completion as policy authority.
3. Preserve full POLICY-01 predicates and the intentional fresh-file warning change. Empty
   diagnostics, worker/plan-only completion and a clean buffer never establish project acceptance.
4. Complete independent review, applicable proof/compiler checks, hard 420-second acceptance
   and exact-head CI; integrate and reconcile successors and Project 8. Stop after #5 unless
   scope is expanded.

**Mission-leverage card:** N/A; no separate card or active goal object is used.

## Attribution clarification after DESIGN-01

DESIGN-01 is integrated through PR #21, merge `b43553693f16c061e2e9214116339304c7f93ae0`.
The attribution follow-up narrows project labeling and blanket credit requirements, preserving
specific design precedents and optional #8/#9 research. It changes no linter semantics or
proof guarantees. #5 remains next; verify this follow-up is integrated before resuming.
