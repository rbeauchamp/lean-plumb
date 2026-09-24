# Design influences and attribution scope

Plumb for Lean is a Lean-native linter and rule-reference website. This account was checked
against `b43553693f16c061e2e9214116339304c7f93ae0` on 2026-09-15. The
[ecosystem study](ecosystem-design.md) explains the broader selection of tools and APIs.

## What con-leche contributes

| Relationship | Actual scope | Treatment |
| --- | --- | --- |
| Design inspiration | `PropWhen` illustrates an invariant-bearing canonical representation with laws at its API boundary. `InstalledEnv`/`FullyChecked` illustrates acceptance bound to a specific installed input and all required record checks. | Keep precise citations in registry/policy design documentation and relevant source attribution. |
| Current code or proof dependency | Root and prototype package manifests contain no con-leche dependency; the linter does not import its modules or invoke its checker. Existing registry attribution explicitly marks copied code false. | Do not describe Plumb as built on con-leche or claim its correctness theorem applies here. |
| Rule detection and developer experience | The actual semantic host is Lean; native hooks, Lake, infoview, Std/library facilities and the cross-language UX references have their own roles. | Credit those facilities and examples where used. Con-leche does not supply the linter rules, editor adapter or website UX. |
| Optional future external checking | #8 investigates export/toolchain fidelity; #9 may implement an adapter only after a supported feasibility decision. Neither is delivered or a core linter prerequisite. | Retain these explicitly optional issues with the `con-leche` topic label. A research no-go is a legitimate result. |

The concrete precedents are [PropWhen][propwhen] and [Installed][installed], pinned at
`c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0`. Their universe-zero representation and
checker-specific environment are specialized implementations, not generic linter components
to import. Plumb's existing closed `RuleId`/indexed descriptors and [policy
assembly](policy-acceptance.md) apply related ideas to different predicates. Ordinary
dependent types, canonical forms and complete indexing are broader techniques; con-leche is a documented example,
not their origin or an exclusive source. Prefer matching Core/Std/Lean definitions and laws
before writing a new implementation.

The [policy acceptance guide](policy-acceptance.md) owns the implemented assembly and
its delivery evidence. Registry laws concern Plumb's own definitions. Neither
inspiration nor those laws establish extraction fidelity, whole-checker correctness or native runtime behavior. No source copy or imported con-leche
proof was found in the inspected linter surfaces.

## Lean and Lake interfaces used by adoption

The adoption adapters are built on interfaces by the Lean 4 and Lake authors (Lean FRO and
contributors), used through the pinned `v4.34.0` toolchain as dependencies. No code is copied.
Lake's `lintDriver` package field and `lake lint` dispatch (`Lake.CLI.Main`, `Package.lint` in
`Lake.CLI.Actions`) run `lint`. Lean's `errorDescriptionWidget` in `Lean.Log`, the
builtin widget behind named errors, renders the editor's **View explanation** link with Plumb's
registry URL. The VS Code Lean 4 extension and infoview (leanprover/vscode-lean4) host
these messages. These are dependencies, not design influences on Plumb's policy.

## Keep attribution proportionate

Credit actual copied/adapted code with its applicable license/notices. Cite identifiable design
influences at the component/design boundary, distinguishing inspiration from dependencies and
proof reuse. Do not require every unrelated issue, code module, rule page, CI change or PR to
mention con-leche. A shared metadata credit may link to this account; it is not a claim that
con-leche authored every rule or detector. Preserve meaningful existing attribution without
repeating it as product branding.

Core project issues use linter/policy terminology and do not carry the `con-leche` topic label.
Policy issues #4–#7 use POLICY-01–04; older CL-01–04 references identify the same issue numbers.
The label remains appropriate for actual con-leche research/adapter work and its historical archive.

[#3](https://github.com/rbeauchamp/lean-plumb/issues/3) preserves the original con-leche/con-ron
research. Keep it linked as historical background, outside the linter project's work-item list.
Its original report is not edited retroactively or treated as the controlling product plan.
Con-ron adoption remains outside scope. Project 8 and the current issue contracts govern delivery.

[propwhen]: https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Kernel/PropWhen.lean
[installed]: https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Cached/Installed.lean
