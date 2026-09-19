# Lean 4.34.0 upgrade and issue 37

## Scope and pins

PR #36 upgrades the root checker, standalone build-lint example, and Verso site to
Lean 4.34.0, compiler `293d5d0c0c3f3dded4688b3ccd6a33939ac5102b`.
The root Mathlib release is `5ed2965256430c3649e86755f9576b54eca72435`;
Verso is `cad4b633e75ea769b851f12f9ca3b4f0dfcc625f` (v4.34.0).
Both dependency manifests retain the exact revisions from their upstream release manifests.

## Root cause

At starting HEAD `32c9b3bea5bd367e2213e11f1f26ce2536587071`, a direct
`lake exe axiomGate --with-docs --legacy-json-out ...` reproduced
`[VIOLATION[kernel-admission]] unowned module StrictLean.Contract imports an owned module`.
Thus the reported direct-versus-`lean --run` distinction was not reproducible on this checkout.

The upgrade attempt had added `public import StrictLean.MaterialClaim` to the otherwise
self-contained contract interface. `Environment.probeModuleNames` deliberately excludes
`StrictLean.Contract` from replay ownership, while the root package inventory includes
`StrictLean.MaterialClaim`. Importing Contract into the replay base would therefore bring an
owned module back into the trusted base. `Admission.validate` correctly refused that dependency.
Removing the unnecessary import restores the intended boundary. The `module` header and
`@[expose] public section` remain, and no admission or ownership check is weakened.

The inherited uncommitted `lake clean` attempt was preserved in a local patch and removed.
Fresh project admission already copies source to empty root-package output; `buildChecked`'s
mode string was not intended to implement freshness. No extra clean or unsupported Lake flag
is required.

The upgrade also updates three exact compiler guards, the prototype compiler check, proof/API
deprecations, Mathlib imports in source and checked documentation, current support prose,
and the site dependency lock. Historical evidence retains its original pins. Contract API
documentation removed by the earlier attempt is restored; unconditional debug output is removed.

## Compiler linkage and review

Independent source review compared the installed 4.33.1 and 4.34.0 toolchains. The recursive
helper transformation (`addAndCompilePartialRec`), retained IR collector (`collectDecl`),
CSimp/implemented-by attribute mechanisms, native-proof infrastructure, and generated brecOn
source retain the relevant behavior. The kernel replay migration calls the same algorithm
under `Lean.Kernel.Environment`; the former environment wrapper was unnecessary here.

Lean 4.34 additionally invokes `CSimp.replaceConstant` in `ToDecl.replaceLogicConstants`
before macro inlining, as well as later `ToLCNF` conversion. Module 8 now states one lookup
per invocation and both phases. The checker's conservative candidate closure already follows
replacement chains; runtime qualification remains separate from this source argument.

Two independent review assignments covered compiler/kernel/implementation risks and
proof/normative-documentation risks. The frozen patch was SHA256
`caf6d609f391908eeee8f173397acb8dcf17554d48ea9da25e6e3c8593874ba5` against
base `259ebee37fd41146596df1d169bab94dbdcd78f9`. Focused rereview closed the resulting
module 6/7 supported-pin and module 8 compilation-phase wording findings.

## Local execution evidence

The initial repaired run passed declaration admission but found 12 documentation failures:
obsolete Mathlib imports, one deprecated theorem name, and a missing local dependency artifact.
The imports/theorem references were migrated and pinned Mathlib artifacts provisioned.

Cold `./scripts/verify.sh`: **PASS, 215.35 seconds**, under the unchanged 420-second limit.
Root `.lake/build` was moved aside before the command; pinned dependency artifacts remained.
The later module 6/7/8 prose corrections changed no Lean source, fence source, or fence markers.

| Claimed Lake surface | Modules | Declarations |
| --- | ---: | ---: |
| StrictLeanPolicy | 17 | 3649 |
| StrictLeanVerification | 1 | 101 |
| StrictLeanQualification | 10 | 443 |
| Audit | 7 | 313 |
| AuditApp plus standalone Main (`auditApp`) | 5 | 196 |
| Total | 40 | 4702 |

The [module inventory](issue-37-module-coverage.json) records every exact Lake module,
per-surface declaration count and axiom union from the emitted declaration report.
Raw local outputs are in `tmp/lean-upgrade-37/`; the full declaration report is
`tmp/axiom-report.json`.

Every owned declaration received axiom inspection; the union was exactly
`{propext, Quot.sound, Classical.choice}`, within the manifested Standard-Logical profiles.
This union does not say that every declaration uses all three axioms. Native/runtime and IO
boundaries remain explicitly reported, not proved by the source contracts.
All 94 documentation fences passed: 70 conforming positives, 23 intended negatives, and one
separately classified trusted-compiler example. Registry checks, seven configuration-output
invalidation controls, and 36 native source controls also passed.

Verso 4.34.0 dependency provisioning (`lake build verso/VersoManual`): **PASS**.
ShellCheck, actionlint on the CI workflow, and whitespace checks: **PASS**.
Further CI recipes and focused diagnostics follow.

- `./scripts/verify.sh diagnostics producers`: **PASS, 274.49 seconds**. This includes
  documentation producer, standalone-executable, source admission, and replacement-history
  positive/mutation/restored controls through fresh, incremental and file paths.
- The first rule-example invocation stopped on an untracked macOS `examples/rules/.DS_Store`
  binary file, which the source snapshot tried to decode as UTF-8 (5.96 seconds).
  That metadata file was moved intact to `tmp/lean-upgrade-37/rules.DS_Store`; no source or
  acceptance predicate was changed to bypass the failure.
- `./scripts/verify.sh diagnostics rule-examples`: **PASS, 317.66 seconds** after that
  local metadata cleanup. All 20 rules qualified their positive, intended negative (or
  explicitly unavailable-analysis demonstration), and restored-positive cases.
- `lake env lean --run examples/rule-reference-prototype/Run.lean`: **PASS, 55.14 seconds**.
  The root and site reported exactly the same 4.34.0 compiler; actual policy, native diagnostics,
  Lake dependency dispatch, fixture correction, Verso rendering, site-artifact validation and
  same-input static byte equality passed. Editor interaction remains a separate unrun claim.
- `./scripts/verify.sh diagnostics fixtures`: **PASS, 174.15 seconds**. Sixty compiled
  fixtures, declaration inspection in fourteen collision groups, 28 in-process Markdown
  corpus cases, and eleven execution-policy cases completed within this partition.
- The extra compiler-path campaign initially failed because its generated packages had no
  Lake manifest before immutable configuration capture, and no module docstrings. The harness
  now runs Lake configuration setup first and emits neutral module documentation. No checker
  guard or expected-reason predicate changed. Independent focused rereview cleared the repair.
  This excluded diagnostic module changes no claimed declaration or documentation fence;
  the earlier cold-acceptance timing remains attributed to its actual pre-repair snapshot.
- Rebuilt `checkerSelftest` after the harness repair: **PASS**. The complete focused
  `gtimeout --signal=KILL 420s lake exe checkerSelftest --compiler-paths-only` command
  then returned zero in **150.81 seconds**, completing all fourteen positive/mutation/fresh
  restoration cases. The original failure and manifest-only intermediate failure are retained
  separately from this final result in the local log directory.
- `./scripts/verify.sh diagnostics build-policy`: **PASS, 184.41 seconds**. Ordinary
  Lake build policy controls completed positive, intended mutation, and fresh restoration
  checks; this remains a separate diagnostic partition, not ordinary acceptance.

## Evidence boundaries

This is a scoped upgrade review: relevant DECL, FOUND, COMP, DOC, MUT and DOGFOOD rows,
plus the affected explicit contracts and build-adoption path. Command success and source
review do not establish full repository semantic conformance or a proof of Lean's compiler,
filesystem, process mechanisms, or external runtime. No optional serialized-graph or complete
diagnostic-campaign result is claimed. Hosted reviewed-head CI and merged-main CI are separate
delivery gates.
