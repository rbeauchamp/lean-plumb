# One-rule architecture experiment

PRODUCT-01 exercises existing **project-axiom** policy as **SL1001**, not the complete registry,
editor scheduler, acceptance proofs or public website. See the [architecture](../../docs/guides/linter-architecture.md)
and [complete map](../../docs/guides/rule-coverage.md) for successor contracts.

## Reproduce

From the repository root, provision its pinned dependencies per the contributor guide, then:

```sh
lake build axiomGate StrictLeanQualification +StrictLean.Qualification.Project:olean
cd examples/rule-reference-prototype/site
lake build verso/VersoManual
cd ../../..
lake env lean --run examples/rule-reference-prototype/Run.lean
```

The Lean driver has a single 600-second process-group deadline after setup and writes ignored
`generated/evidence.json`, `rule.json`, and `public/`. It is not a substitute for
`./scripts/verify.sh` (hard 420 seconds). The experiment's prior plan allowed 15 minutes for
setup and 10 minutes for execution: one rule, one violation/fix pair, native registration,
Lake dependency dispatch, one page and same-input static reproducibility. The decision concerned
actual API/toolchain integration, which a pure policy theorem cannot establish. All those
outcomes were required for go; a fallback required a concrete blocker. Verso met the criterion.

The generated files are under `generated/public/`; the landing page links to
`/strict-lean/dev/rules/SL1001/`. No Python HTTP server is part of the recipe.
Browser navigation requires an independently provided static-file host at that base;
no new server implementation or deployment is supplied here. The production HTTPS
destination is planned, not yet live.

## What is checked

1. Lean 4.33.1 compiles `Rule.lean` and `Probe.lean`; `Export.lean` exports the total one-rule
   descriptor. The probe registers a real command linter and emits a textual help URL. Its separate,
   explicitly named empty environment linter checks registration compatibility only, not detection.
2. Actual fixture files compile independently. The violation contains an unused axiom; the fix
   proves only `False → False`, not `False`. A generated client imports each completed fixture
   and triggers the hook, which reuses **existing** `StrictLean.Probe.environmentReport` and
   `StrictLean.Checker.Policy.reasonFor`. No duplicate project-axiom detector is written.
   The violation must emit exactly one effective error, with named kind
   `StrictLean.SL1001._namedError`, actual line 2 / columns 6–17, and derived help URL.
   Fixed controls emit no messages. Invalid sources stay isolated from positive source.
3. A disposable Core-only adopter uses `lintDriver = "strict_lean/axiomGate"` and
   `lintDriverArgs = ["--build-lint"]`. Actual `lake lint` invokes the public checker and completed
   logical admission on the same pair. Positive–negative–restored-positive controls each start
   with empty adopter output. Intended `project-axiom` rejection is required; generic failure
   cannot satisfy the assertion. No Mathlib module is compiled for this adopter.
4. The Lean driver includes exact checked source and Lean-exported metadata in generated Verso source.
   Its pure page constructor returns proof-bearing exact template output; the site-artifact
   contract preserves required/emitted IDs, route and observed checked-example conditions.
   These are presentation/transport contracts, not semantic detection or proofs of IO.
   Blocks render as text, without
   silent re-elaboration on documentation Lean 4.33.0. The full dependency lock is retained.
   Generated source is never manually edited or committed. Every page includes appropriate credit.
5. The output is assembled below the project base. Two renders at identical inputs must have
   identical relative file names and per-file bytes (no hash assumption). This is observed repeatability for these inputs, not a
   universal reproducible-build theorem or evidence of Lean correctness.

## Evidence and limits

The initial macOS run took **39.66 seconds** after provisioning, with **98 identical static
files** across two renders. This is one observation, not a performance promise. After changed
inputs the driver must pass again; generated evidence records the current outcomes/time.
The public checker accepted one module/one declaration for the restored fixed control.
The in-app browser rendered the rule page, actual sources and credits at the project base;
keyboard activation of **Explain SL1001** reached it from the diagnostic control. The Chrome
CLI bridge could not start and hidden-tab mouse actions timed out; keyboard navigation supplied
the successful browser observation. This is **not VS Code evidence**.

Actual Lean VS Code infoview widget interaction is **unverified here**, assigned to #14.
Current-document collection and scheduling belong to #13. The probe's explicit command takes
an imported module and supplied source filename; production must derive/validate source identity.
`Probe.ownedConstants` inventories imported module indices, so using it unchanged does not cover
current unserialized declarations. Editor snapshots cannot claim complete project conformance.

The former project-owned JavaScript widget has been removed under the Lean-only policy;
its earlier compilation/registration evidence is historical, not a current capability.
The textual URL and named kind remain verified. Direct `logMessage`
avoids `logAt` adding Lean's hard-coded manual link. No unsupported `codeDescription` field,
Lean fork or new language server is assumed. This operational metaprogram's compilation does
not prove its collector or policy universally correct; proof-bearing acceptance remains #4–#7.

## Pins and credit

- Checker/examples: Lean 4.33.1, compiler `819816b2e0a3bf405af45ae5c7af2491d8f5bee6`.
- Docs: Lean 4.33.0; [Verso](https://github.com/leanprover/verso/tree/3bdedf29bada13d8103e6c979001c51dcee210c8).
  Transitive revisions are in `site/lake-manifest.json`; do not update moving branches.
- **Lean FRO's con-leche**: [Installed.lean](https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Cached/Installed.lean)
  and [PropWhen.lean](https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Kernel/PropWhen.lean)
  motivate canonical metadata and proof-bearing boundaries. No con-leche code/proof is copied;
  this does not claim that con-leche proves Strict Lean correct.
- Lean authors supply [linter registration](https://github.com/leanprover/lean4/blob/819816b2e0a3bf405af45ae5c7af2491d8f5bee6/src/Lean/Elab/Command.lean)
  and the [message/widget pattern](https://github.com/leanprover/lean4/blob/819816b2e0a3bf405af45ae5c7af2491d8f5bee6/src/Lean/Log.lean).
  The diagnostic adapter is original API-use code informed by that pattern.
- Verso authors and David Thrane Christiansen's [package-docs template](https://github.com/leanprover/verso-templates/tree/76c9edf5a70f14d272af0f0f354ec833ac22c350/package-docs)
  inform separate documentation/example toolchains; template prose/code is not copied.
- [Microsoft CA1416](https://learn.microsoft.com/en-us/dotnet/fundamentals/code-analysis/quality-rules/ca1416)
  informs cause/fix/configuration/limits presentation. The Lean explanation is original.
- Con-ron is excluded. Dependencies retain their own licenses; repository code retains the
  repository license. Later copied code must preserve its actual notices.

## Shared registry migration

CATALOG-01 replaces the prototype-only descriptor with the product registry.
`Export.lean` emits the full schema-1 registry; the generator selects SL1001 from
that value and submits actual page/emitted-ID inventory to `axiomGate --validate-site`.
Native diagnostics use the same typed payload, source admission and renderer as
the checker. The experiment remains one page and an explicit imported-module
trigger. See [registry migration](../../docs/guides/rule-registry.md) for contracts,
con-leche attribution and evidence limits.
