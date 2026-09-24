import PlumbCore.Account

/-! # Rule explanations for the rule-reference site

`guide` is the explanatory prose for every rule, as one exhaustive definition over the closed
`RuleId`: adding a rule without its explanation is a compile error, and the site generator
renders a page from `guide id` together with the registry descriptor `descriptor id` and
the checked example evidence of that rule. Nothing here is a second rule vocabulary: rule
identity, title, category, clauses, modes and routes come from `descriptor`.

## Main declarations

- `Guide`: the required sections of a rule explanation.
- `guide`: the explanation of each registered rule.
- `Guide.WellFormed`, `guide_wellFormed`: every required field of every rule is a nonempty
  string or list, and each rule names at least one residual obligation and one source. Content
  adequacy is review.

## Boundaries

The prose is original Lean-specific explanation written against `docs/standard/` and the
checker sources it names. Its fidelity to the standard and to the detectors is semantic
review (R-DOC, R-INTENT); nonemptiness is the only mechanical property checked here. Text
uses Verso inline markup. A link target `@repo/PATH` denotes `PATH` in this repository at the
revision the site is built from; the generator requires each such file to exist.
Presentation structure follows Microsoft's CA1416 page as one illustrative reference
(cause, rationale, fix, configuration, examples); no content is copied from it.
-/

namespace Plumb.Site

open Plumb.Checker.Account (Residual)

/-- The explanation sections of one rule page, in page order. `residuals` are the
`rule-coverage.md` obligations a result of this rule never discharges; `checklist` names the
chapter 9 rows the rule contributes to; `sources` are repository paths of its detector,
policy and proof modules. -/
structure Guide where
  problem : String
  action : String
  trigger : List String
  rationale : List String
  fixes : List String
  proofShape : List String
  established : List String
  notEstablished : List String
  configuration : List String
  limitations : List String
  correction : String
  residuals : List Residual
  checklist : List String
  sources : List String

/-- Every required section has content and the page names its open obligations and sources. -/
def Guide.WellFormed (g : Guide) : Prop :=
  g.problem ≠ "" ∧ g.action ≠ "" ∧ g.trigger ≠ [] ∧ g.rationale ≠ [] ∧ g.fixes ≠ [] ∧
  g.proofShape ≠ [] ∧ g.established ≠ [] ∧ g.notEstablished ≠ [] ∧ g.configuration ≠ [] ∧
  g.limitations ≠ [] ∧ g.correction ≠ "" ∧ g.residuals ≠ [] ∧ g.checklist ≠ [] ∧
  g.sources ≠ []

instance (g : Guide) : Decidable g.WellFormed := by
  unfold Guide.WellFormed; infer_instance

/-- Shared statement: what Plumb's local linter options change in project runs. -/
private def localOptions : String :=
  "`set_option linter.plumb false` and `plumb.localFoundation` never waive it: `lake lint`, the build-lint `policy` target and `axiomGate` still apply the rule. Where Plumb's local linter reports a finding during a project build (`axiomGate` and the `policy` target keep it on by default; under `lake lint` a source `set_option linter.plumb true` turns it back on), that finding is a build warning, so the result is INCOMPLETE under PL2003 instead of carrying this rule's finding. Switching the local linter off changes which finding is reported, never whether the result is accepted. Hiding the diagnostic does not establish the property it checks."

/-- Shared statement: local options never create a strict exception. -/
private def noLocalException : String :=
  "No source option, attribute or command-line flag makes this rule pass on a claimed surface. " ++ localOptions

/-- Shared statement for the rules scoped by `@[plumb_material]`, where the registration
attribute selects the checked declarations. -/
private def noLocalOption : String :=
  "No source option or command-line flag makes this rule pass on a claimed surface. " ++ localOptions

/-- Shared statement: where the rule runs. -/
private def projectCommands : String :=
  "Project enforcement runs through `lake lint` (incremental), `lake lint -- --fresh` and `lake exe axiomGate` (fresh whole-project audits from empty build output), and the build-lint `policy` target. See the [adoption guide](@repo/docs/guides/adoption.md)."

/-- Shared statement: foundation labels. -/
private def foundationTable : String :=
  "The three logical labels are Kernel-only (no axioms), Choice-Free (a subset of `propext` and `Quot.sound`) and Standard-Logical (additionally `Classical.choice`). A surface's `claim` in `foundation_manifest.json` is the upper bound; each declaration is labeled from its own exact axiom set."

/-- The explanation of each rule. -/
def guide : RuleId → Guide
  | .projectAxiom => {
      problem := "A declaration owned by a claimed module is a logical `axiom`. Lean accepts an axiom without evidence, so every theorem that uses it is only conditional on an assumption that no proof discharges."
      action := "Turn the assumption into a hypothesis (a binder or a proof-bearing structure field) of the results that need it, or replace the axiom with a proof."
      trigger := [
        "The checker inspects every constant attributed to an owned module in the completed Lean environment. A `ConstantInfo.axiomInfo` there is rejected with applicability `project-axiom`.",
        "The rule applies whether or not any other declaration uses the axiom, and to private, protected, internal-looking and generated names alike. A name or namespace never exempts it."]
      rationale := [
        "An axiom extends Lean's logic for everything that imports it. An assumption that is false, or inconsistent with other axioms, makes every downstream theorem vacuous, and the kernel cannot tell. A hypothesis keeps the assumption visible in each theorem's type, so every use must supply it.",
        "Lean 4 has no `constant` command; an `opaque` definition with a body is kernel-checked and is classified separately, not as an axiom."]
      fixes := [
        "If the statement is provable, prove it: replace `axiom name : P` by `theorem name : P := proof`.",
        "If it is a genuine assumption of a model, make it a parameter: `theorem result (h : P) : Q`, or a field of a structure that bundles the model and its laws.",
        "If it states an open research target, define it as a `Prop` (`def Target : Prop := P`) and state results conditionally on it; do not assert it."]
      proofShape := [
        "A conditional result must carry the assumption in its type, for example `∀ (h : P), Q`, so the exact theorem statement shows what it depends on. Its transitive axiom set must then fit the surface's foundation profile."]
      established := [
        "No owned constant of the checked modules is a logical axiom (the complete inventory itself is PL2004).",
        "The rule is evaluated from Lean's elaborated environment after checked admission, not from source text."]
      notEstablished := [
        "That the hypotheses replacing an axiom are satisfiable or appropriate: that is the claim's intent and non-vacuity review.",
        "Anything about axioms of imported, unowned dependencies; those are reported through the transitive axiom sets of PL1003 and PL1005."]
      configuration := [
        noLocalException,
        "Authenticated native-proof axioms generated by `native_decide` are not project axioms: they are classified as compiler-trusting and rejected by PL1004 instead.",
        projectCommands]
      limitations := [
        "The editor linter reports this rule for completed declarations of the current file (`editorSnapshot`); a clean editor buffer is not a project result.",
        "A metaprogram that adds declarations still produces owned constants; they are inspected like authored ones."]
      correction := "The correction proves the same `∀ n : Nat, n = n` by `rfl` instead of assuming it, under the unchanged Kernel-only claim."
      residuals := [.intent, .nonvacuity]
      checklist := ["FOUND-01", "TYPE-04", "THEOREM-09"]
      sources := ["lean/PlumbCore/Policy.lean", "lean/PlumbPolicy/Decision.lean", "lean/Plumb/Findings.lean", "docs/standard/3-logic-proof-patterns.md"] }
  | .proofHole => {
      problem := "The declaration depends on `sorryAx`: a `sorry`, an `admit`, an unfinished tactic proof, or an imported declaration with such a hole occurs in its transitive axiom set. The proposition is not proved."
      action := "Complete the proof. If the statement is an open problem, define it as a `Prop` and state results conditionally on it instead of asserting it."
      trigger := [
        "The checker computes the exact transitive axiom set of every owned declaration with Lean's `collectAxioms`. If `sorryAx` belongs to it, the declaration is rejected with applicability `hole`.",
        "Theorems, proof-valued definitions and instances, and data definitions are all inspected; alternate syntax (`admit`, a tactic `sorry`, an elaboration error recovered as `sorry`) is caught because the kernel term contains `sorryAx`."]
      rationale := [
        "`sorryAx` proves every proposition. A declaration that depends on it has no evidence, even if Lean elaborated the file, and every theorem that uses it inherits the gap."]
      fixes := [
        "Replace the `sorry` or `admit` with a complete proof.",
        "If the hole comes from an imported declaration, fix or replace that dependency; imported holes are not exempt.",
        "For an open target, write `def Target : Prop := …` and prove `Target → Result`, which states exactly what is established."]
      proofShape := [
        "The completed declaration keeps the same statement. Weakening the proposition until it is easy to prove changes the requirement and is a semantic review failure, even though this rule then passes."]
      established := [
        "No owned declaration of the checked scope has `sorryAx` in its exact transitive axiom set."]
      notEstablished := [
        "That the completed proof proves the intended statement; the proposition itself is reviewed against its intent.",
        "Lean's own warning for `sorry` is a separate compiler diagnostic (see PL2003); this rule does not depend on it."]
      configuration := [noLocalException, projectCommands]
      limitations := [
        "In the editor the rule is reported for completed declarations of the current snapshot. A cancelled collection reports nothing for that declaration; a failed one is reported as PL2005 (incomplete), never as an invented PL1002."]
      correction := "The correction fills the same reflexivity proof with `rfl`. The checked violation records Lean's original `sorry` warning as well; the corrected file passes the ordinary warning-rejecting gate."
      residuals := [.qualify, .intent]
      checklist := ["FOUND-02", "THEOREM-06"]
      sources := ["lean/PlumbCore/Policy.lean", "lean/PlumbPolicy/Decision.lean", "lean/Plumb/Findings.lean"] }
  | .unknownAxiom => {
      problem := "A declaration's exact transitive axiom set contains an axiom outside Lean's standard logical foundation (`propext`, `Quot.sound`, `Classical.choice`) that is neither `sorryAx` nor a compiler-trusting axiom (Lean's built-in `Lean.trustCompiler`, `Lean.ofReduceBool` and `Lean.ofReduceNat`, or an authenticated `native_decide` axiom)."
      action := "Find where the axiom enters (often an imported dependency), and replace that dependency or its axiom with a proof or a hypothesis."
      trigger := [
        "Each axiom in the transitive set is classified. One that is not a standard logical axiom, `sorryAx` (PL1002) or a compiler-trusting axiom (PL1004) is unknown, and the declaration is rejected with applicability `unknown-axiom`.",
        "Imported axioms are not exempt: an owned theorem that uses a dependency's axiom is rejected even though the axiom is declared elsewhere."]
      rationale := [
        "A foundation label summarizes exactly which assumptions a result rests on. An unclassified axiom has no label, so no profile claim about the declaration can be true.",
        foundationTable]
      fixes := [
        "Inspect the declaration's axiom list in the diagnostic or with `#print axioms`, and follow it to the declaration that introduces the axiom.",
        "Replace the axiom in the dependency with a proof, or make it a hypothesis of the results that need it.",
        "If the dependency cannot change, do not claim the affected declarations on a conforming surface."]
      proofShape := [
        "After the fix, the exact transitive axiom set is a subset of `propext`, `Quot.sound` and `Classical.choice` and fits the surface claim (PL1005)."]
      established := [
        "Every axiom in the transitive set of each owned declaration is either a standard logical axiom or rejected by a more specific rule."]
      notEstablished := [
        "Anything about the unowned dependency beyond its axioms; imported declarations are a declared trust boundary, identified by the exact dependency state (PL2001)."]
      configuration := [noLocalException, projectCommands]
      limitations := [
        "Classification uses exact constant names and authenticated compiler evidence, not name patterns; a lookalike name gets no special treatment."]
      correction := "The client file is unchanged. The dependency supplies a proof of the same reflexivity statement instead of declaring it as an axiom."
      residuals := [.qualify]
      checklist := ["FOUND-03"]
      sources := ["lean/PlumbCore/Policy.lean", "lean/PlumbPolicy/Foundation.lean", "lean/PlumbPolicy/Decision.lean"] }
  | .compilerTrusting => {
      problem := "A declaration on a positive surface depends on a compiler-trusting axiom: a native-proof axiom generated by `native_decide`, or Lean's built-in `Lean.trustCompiler`, `Lean.ofReduceBool` or `Lean.ofReduceNat`. Its proof trusts compiled code and the Lean compiler, not the kernel."
      action := "Prove the same statement with a kernel-checked proof, for example `decide` (kernel reduction), `rfl` or an ordinary proof."
      trigger := [
        "`native_decide` evaluates a decision procedure with compiled code and adds an axiom asserting the result. When the checker authenticates that axiom and its parent (exact axiom type `@decide P inst = true`, exact parent proof, native replay and fresh-frontend origin), both are classified compiler-trusting and rejected with applicability `compiler-trusting`. The built-in axioms `Lean.trustCompiler`, `Lean.ofReduceBool` and `Lean.ofReduceNat` in a transitive axiom set are compiler-trusting by their exact identity.",
        "Final environment metadata cannot authorize a generated native-proof axiom; fresh re-elaboration of the exact source establishes it. An unauthenticated axiom that only looks native is not compiler-trusting."]
      rationale := [
        "Compiled evaluation is outside the kernel's checking. A compiler or runtime defect could make a false proposition \"proved\". Compiler-trusting is therefore not one of the three logical labels and never counts as conforming evidence."]
      fixes := [
        "Replace `by native_decide` with `by decide` when kernel reduction of the decision procedure is feasible.",
        "Otherwise give a structural proof, or prove a smaller lemma that `decide` can handle and combine the pieces.",
        "If the example exists only to teach the mechanism, keep it in documentation as a trusted-compiler teaching fence (PL4004), never on a claimed surface."]
      proofShape := [
        "The replacement proof proves the same proposition. Kernel reduction (`decide`, `rfl`) is permitted, subject to the surface's foundation profile."]
      established := [
        "No positive declaration depends on a compiler-trusting axiom: an authenticated native-proof axiom or the built-in `Lean.trustCompiler`, `Lean.ofReduceBool` or `Lean.ofReduceNat`."]
      notEstablished := [
        "Performance of the kernel replacement proof; cost claims are separate (R-COST)."]
      configuration := [
        noLocalException,
        "Authenticated native proofs are reported separately in documentation teaching mode (`lean-trusted-compiler` fences) and remain excluded from conforming positives.",
        projectCommands]
      limitations := [
        "The editor may defer authentication and report a pending result; the project command completes it.",
        "An unauthenticated axiom that merely looks native is not compiler-trusting; it is rejected as an unknown axiom (PL1003) or project axiom (PL1001)."]
      correction := "The correction proves the same concrete equality `(2 : Nat) = 2` by `rfl`. The violation reports both the generated axiom and its parent theorem."
      residuals := [.qualify, .cost]
      checklist := ["FOUND-05", "FOUND-03", "THEOREM-10"]
      sources := ["lean/PlumbPolicy/Decision.lean", "lean/Plumb/Checker/Frontend.lean", "lean/PlumbCore/Policy.lean"] }
  | .profileExceeded => {
      problem := "A declaration's exact transitive axiom set is admissible, but its least foundation label is stronger than the claim of the surface it belongs to."
      action := "Prove the same statement with fewer axioms, or deliberately raise the surface's claim in `foundation_manifest.json` and update its rationale."
      trigger := [
        "Each declaration receives the least label containing its exact axiom set. If that label exceeds the surface maximum, the declaration is rejected with applicability `label-exceeds-claim`.",
        foundationTable]
      rationale := [
        "A profile claim tells readers which logical principles every result on the surface may use. One declaration above the bound makes the claim false for the whole surface."]
      fixes := [
        "Find the axiom that raises the label in the diagnostic's axiom list, then find the lemma or tactic that introduces it (for example `simp` lemmas using `propext`, or classical reasoning using `Classical.choice`).",
        "Prove the statement constructively or with a narrower lemma so the exact set fits the claim.",
        "If the stronger foundation is intended, change the surface's `claim` and rationale explicitly; this changes the published claim and needs review."]
      proofShape := [
        "The replacement proves the same proposition. Classical, erased proofs are permitted when the surface claims Standard-Logical; executable behavior is a separate account (PL1007, PL3001, PL3002)."]
      established := [
        "Every declaration's exact axiom set is within the selected surface maximum."]
      notEstablished := [
        "Which label a declaration should have: the claim is a project decision, reviewed with its rationale."]
      configuration := [
        noLocalException,
        "The surface maximum is the `claim` of its entry in `foundation_manifest.json`; `axiomGate --file F --claim PROFILE` audits one file under an explicit profile. In the editor, `plumb.localFoundation` selects local feedback only.",
        projectCommands]
      limitations := [
        "The label is computed from the exact transitive set; a proof that merely could avoid an axiom still carries it until rewritten."]
      correction := "The correction proves the same universally quantified reflexivity with an empty axiom set, under the unchanged Kernel-only claim, instead of routing through `propext`."
      residuals := [.qualify]
      checklist := ["FOUND-03", "FOUND-04", "BUILD-02"]
      sources := ["lean/PlumbPolicy/Foundation.lean", "lean/PlumbCore/Policy.lean", "docs/standard/4-mathematical-foundations.md"] }
  | .escapeHatch => {
      problem := "An owned declaration is marked `unsafe` or `partial` and is not the exactly authenticated code-generation helper of a safe recursive definition."
      action := "Write a safe, terminating definition (structural recursion or `termination_by`), or move the unsafe/partial code out of the claimed surface."
      trigger := [
        "Authored `unsafe` and `partial` declarations are escape hatches: an unsafe declaration is checked only in Lean's unsafe mode, cannot be used by safe declarations or proofs and is not replayed as logical evidence, and a partial definition has no termination proof. They are rejected with applicability `escape-hatch`.",
        "The only exception is the range-less partial helper Lean generates for a safe, termination-checked recursive `def`, admitted when every condition of standard §8.4 holds, including fresh-frontend attribution of the exact source."]
      rationale := [
        "A positive proof surface must consist of kernel-checked definitions. Unsafe and partial code can be executed, but it cannot serve as logical evidence, and reasoning about it silently depends on its runtime behavior."]
      fixes := [
        "Remove an unnecessary `unsafe` marker.",
        "Replace `partial def` by a definition with structural recursion or a `termination_by` measure and `decreasing_by` proof.",
        "If the computation must stay unsafe or partial, move it to a separate, unclaimed dependency package; a claimed module cannot import an excluded module of its own package (PL2004). Where a claimed executable reaches it, it is reported as a trusted `unsafe-computation` or `partial-computation` boundary, which fails under checked execution (PL3002)."]
      proofShape := [
        "A total replacement keeps the same domain and result type; if it changes behavior, state and prove the relation to the intended function."]
      established := [
        "No authored unsafe or partial declaration is on the claimed surface; every admitted generated helper satisfied all §8.4 conditions."]
      notEstablished := [
        "That unsafe or partial code elsewhere is logically unsound; the rule concerns evidence, not a claim that such code is wrong.",
        "Termination proofs' adequacy for cost claims."]
      configuration := [
        noLocalException,
        "`partial_fixpoint` helpers are not covered by the recursive-helper exception.",
        projectCommands]
      limitations := [
        "The helper exception is conservative: elaborators defined in the audited module, `run_tac` or `by_elab` in the recursion's proofs make the checker reject a definition Lean accepts.",
        "Editor feedback may be pending until the project command completes the fresh-frontend check."]
      correction := "The correction keeps identity's domain and body and removes the unnecessary `unsafe` marker."
      residuals := [.qualify, .cost, .intent]
      checklist := ["COMP-02", "THEOREM-05"]
      sources := ["lean/PlumbPolicy/Decision.lean", "lean/Plumb/Checker/Frontend.lean", "lean/PlumbCore/Policy.lean"] }
  | .executableContract => {
      problem := "A closed `ExecutableContract f R` registration does not have the supported shape: it is not closed, it names no complete implementation constant, or the implementation is not an eligible executable definition."
      action := "Register the named implementation itself and put its complete domain inside the predicate: `theorem c : ExecutableContract f (fun g => ∀ x, P (g x))`."
      trigger := [
        "The checker recognizes declarations of type `Plumb.ExecutableContract f R` as executable promises about `f`. It rejects, with applicability `executable-contract`, a registration with free parameters, a partially applied or term-parameterized implementation, or an implementation that is missing, noncomputable, unsafe, partial, proposition-valued, type-producing or not an executable definition.",
        "Lean's type checker separately checks the supplied proof of `R f`."]
      rationale := [
        "A contract is useful only if it constrains the code callers run. A registration over `f n` for a fixed parameter, or over an ineligible constant, says nothing about the executable definition across its domain."]
      fixes := [
        "Move the quantified parameters into the predicate: replace `theorem c (n : Nat) : ExecutableContract (f n) (fun v => v = n)` by `theorem c : ExecutableContract f (fun g => ∀ n, g n = n)`.",
        "Name the computable, safe, non-partial definition that callers use; route callers through `c.run`.",
        "Universe-polymorphic implementations are supported; explicit universe instantiation is recorded."]
      proofShape := [
        "`ExecutableContract f R` for a named constant `f` with `R : type-of-f → Prop` stating the full-domain requirement. The proof inhabits exactly `R f`; a weaker `R` changes the requirement and is a review failure."]
      established := [
        "The registration is closed, names an eligible executable constant, and Lean checked a proof of the stated predicate about it."]
      notEstablished := [
        "That `R` expresses the intended behavior (R-INTENT) and that every caller uses the contracted implementation (R-INVARIANT). Every accepted account lists these as open for each reported contract.",
        "Behavior of compiled code beyond the Lean definition; execution boundaries are PL3001 and PL3002."]
      configuration := [noLocalException, projectCommands]
      limitations := [
        "Term-parameterized and partial-application registrations are unsupported shapes, not proofs of incorrectness; restate them as closed full-domain contracts."]
      correction := "The correction moves the complete natural-number domain inside the identity contract's predicate, retaining the same pointwise equality."
      residuals := [.intent, .invariant, .qualify]
      checklist := ["BUILD-03", "THEOREM-07", "DOGFOOD-05"]
      sources := ["lean/Plumb/Contract.lean", "lean/Plumb/Probe.lean", "lean/PlumbCore/Policy.lean"] }
  | .environment => {
      problem := "The declared Lean environment could not be loaded or identified, so the requested audit could not run. The result is INCOMPLETE, not a violation of the source."
      action := "Repair the workspace so Lake can load it with its exact toolchain and dependencies, then rerun the same command."
      trigger := [
        "Setup checks load the Lake workspace, resolve dependencies to exact source states, and establish the compiler assumptions the audit needs. A failure (for example `lake-workspace-load-failed` when a required package directory is missing) is reported with impact `incomplete`."]
      rationale := [
        "Every conformance claim is about one exact elaboration environment: toolchain, dependency revisions and source state. A result under an unknown or different environment is not evidence for the declared one."]
      fixes := [
        "Read the original setup error in the diagnostic detail and fix it: a missing path dependency, an unresolvable Git revision, or a toolchain that does not match `lean-toolchain`.",
        "Provision pinned dependencies (for example `lake exe cache get` for Mathlib) before auditing; provisioning is setup, not verification.",
        "Rerun the audit; a new run produces new, complete evidence."]
      proofShape := [
        "No proof obligation: the rule concerns the availability of the environment. The corrected run must then pass the applicable declaration and project rules."]
      established := [
        "A passing result was produced in the declared environment: Lake loaded the workspace with the exact toolchain and resolved dependency state the result reports. An unavailable or unidentified environment is incomplete and never accepted."]
      notEstablished := [
        "That a dependency checkout matches its recorded revision's content: dependency acquisition is a trusted mechanism.",
        "Anything about the source; no declaration was inspected."]
      configuration := [
        "There is no configuration that turns an incomplete setup into a pass.",
        projectCommands]
      limitations := [
        "This page's example is a diagnostic demonstration: the violating run is INCOMPLETE by design and is not accepted negative evidence. Its corrected counterpart passed a completed positive check."]
      correction := "The correction removes the unavailable Lake dependency from the configuration; the requested reflexivity source is unchanged."
      residuals := [.qualify]
      checklist := ["DECL-01", "DECL-04"]
      sources := ["lean/Plumb/Checker/Workspace.lean", "lean/Plumb/Checker/Lake.lean", "lean/Plumb/Checker/ResultProtocol.lean"] }
  | .configuration => {
      problem := "The surface manifest (`foundation_manifest.json`, schema 2) is invalid or does not classify every root-package library and executable exactly once."
      action := "Fix the manifest: exactly the four top-level keys, one entry per root `lean_lib` and `lean_exe` (claimed or excluded with a rationale), and valid `claim` and `execution` values."
      trigger := [
        "The checker parses the manifest and reconciles it with Lake's elaborated root package. Unknown keys, duplicates, a wrong schema version, an unknown `execution` value, an empty `surfaces` array, a missing rationale, an unclassified or unknown target, and claimed/excluded conflicts are rejected (`manifest-schema`, `manifest-incomplete` and related subreasons).",
        "In the editor, an invalid local request (for example an unknown `plumb.localFoundation` value) is reported under this rule for the current file only."]
      rationale := [
        "Coverage is only meaningful against a complete, exact classification. Silently ignoring an unknown key or an unclassified target would let modules escape the audit or let a typo change the claim."]
      fixes := [
        "Remove or correct unknown keys and invalid values; the diagnostic names them.",
        "Add each root library and executable to `surfaces` or to the matching exclusion array, with a rationale.",
        "A claimed executable must be a standalone root such as `Main`; its root module cannot belong to a manifested library.",
        "Run `lake lint -- --explain-config` to see the manifest, scope, profiles and stages the driver would use, without auditing."]
      proofShape := [
        "No proof obligation: the rule concerns configuration. At least one nonempty library surface is required by the schema."]
      established := [
        "The manifest has the exact schema and classifies every root-package library and executable exactly once."]
      notEstablished := [
        "That the chosen claims and exclusions are appropriate for the project; that is reviewed with each rationale.",
        "Exclusions do not permit a claimed module to import an excluded one (PL2004)."]
      configuration := [
        "The manifest is the configuration; there is no flag that accepts an invalid manifest. `--manifest PATH` and `--project DIR` select which files are audited, not how strictly.",
        "`lake lint` exits 2 (INVALID CONFIGURATION) when only this rule rejects."]
      limitations := [
        "Executable-only packages are valid Lean projects but unsupported by manifest schema 2.",
        "The editor never guesses an omitted project scope."]
      correction := "The correction removes the unknown manifest key without changing the selected source, profile or execution requirement."
      residuals := [.qualify, .intent, .invariant]
      checklist := ["DECL-04", "SCOPE-05", "BUILD-04"]
      sources := ["lean/Plumb/Checker/Manifest.lean", "lean/Plumb/Checker/Lake.lean", "lean/Plumb/Findings.lean"] }
  | .sourceBuild => {
      problem := "The claimed source did not elaborate warning-free under the audit's build: the build failed or emitted a warning."
      action := "Fix the compiler diagnostic at its source. Do not disable the warning or linter that reported it."
      trigger := [
        "The audit builds the claimed targets itself and checks both the exit status and every emitted diagnostic. Any warning fails, including when the source sets `warningAsError` to false locally. The original compiler message is preserved in the finding.",
        "In project runs (`lake lint`, `axiomGate`, the build-lint `policy` target) a warning or failed build stops the audit before policy inspection, so the finding is incomplete and the result INCOMPLETE (`lake lint` exit 3). A single-file `axiomGate --file` audit reports a completed source rejection as a violation, as in the example below."]
      rationale := [
        "Warnings often mark real defects (unused hypotheses, deprecated semantics, unreachable cases). Treating them as failures keeps the elaborated statements exactly those the author intended, and prevents a local option from changing what conformance means."]
      fixes := [
        "Read the preserved compiler message, fix the cause and rebuild.",
        "Remove dead bindings or rename intentionally unused ones only when the name was genuinely unused; do not rename a variable that should have been used.",
        "Do not add `set_option linter.… false`: disabling a linter hides its warning but does not discharge the property it checks."]
      proofShape := [
        "The fix must not change the proposition or behavior being claimed; if it does, review the statement again."]
      established := [
        "Every claimed module elaborated from source without errors or warnings under the audit's build."]
      notEstablished := [
        "Fresh source elaboration unless the run is fresh: `lake lint` without `--fresh` is incremental and trusts Lake's build cache."]
      configuration := [
        "`warningAsError := false` in the source cannot hide a warning from the audit. Disabling a linter (for example `set_option linter.unusedVariables false`) can stop it from emitting, which makes this rule pass without discharging the property the linter checks; do not do it.",
        projectCommands]
      limitations := [
        "`lake lint` builds with `linter.plumb` weakly off, so Plumb's own local findings are not build warnings there and its policy stages report those rules; a source `set_option linter.plumb true` turns the local linter back on (issue #69). `axiomGate` and the build-lint `policy` target keep ordinary options, so in a module that imports `Plumb.Linter` a local Plumb finding is a build warning and makes the result INCOMPLETE under this rule."]
      correction := "The correction removes a dead lambda binding while preserving identity's complete natural-number behavior. No warning or linter is disabled."
      residuals := [.qualify]
      checklist := ["DECL-01", "BUILD-01"]
      sources := ["lean/Plumb/Checker/Lake.lean", "lean/Plumb/Checker/Diagnostics.lean", "lean/Plumb/Checker/ResultProtocol.lean"] }
  | .coverage => {
      problem := "The exact module and declaration inventory from Lake does not match the owned coverage: a claimed library imports an excluded or checker-probe module, a module is outside every manifested library, or ownership cannot be determined."
      action := "Remove the forbidden import, or add the module to the intended claimed library's globs, so every owned module belongs to exactly one classified target."
      trigger := [
        "Module inventory comes from Lake's elaborated configuration and Lean's recorded module indices, not from file lists or name prefixes. The checker resolves each imported root-package module's origin and rejects unexpected project modules, imports of excluded modules into claimed ones, and unknown ownership (`unexpected-project-module` and related subreasons)."]
      rationale := [
        "A conformance claim covers an exact set of modules. A module imported into a claimed library but outside every surface would contribute declarations nobody classified, and an umbrella import alone does not define that set."]
      fixes := [
        "Delete imports of excluded modules (for example checker or fixture modules) from claimed code.",
        "Use a glob with the intended meaning, such as ``.andSubmodules `Lib`` in `lakefile.lean` or `[\"Lib\", \"Lib.+\"]` in `lakefile.toml`, so every intended module is in the library.",
        "Classify any new root library or executable in the manifest (PL2002)."]
      proofShape := [
        "No proof obligation: the rule concerns the declaration inventory. The removed import must not have supplied evidence the claim still relies on."]
      established := [
        "The claimed modules are exactly Lake's configured modules for the claimed targets, and every owned constant is attributed to one of them."]
      notEstablished := [
        "That the chosen library boundaries are the ones the project intends to claim; that is reviewed with the manifest rationale."]
      configuration := [noLocalException, projectCommands]
      limitations := [
        "Whole-project scope only: the editor is explicitly partial and does not report this rule."]
      correction := "The correction removes an unused forbidden reporter import; the reflexivity statement and its assumptions are unchanged."
      residuals := [.qualify]
      checklist := ["DECL-02", "DECL-03", "DOGFOOD-02"]
      sources := ["lean/Plumb/Checker/Lake.lean", "lean/Plumb/Probe.lean", "lean/Plumb/Checker/AxiomGate.lean"] }
  | .admission => {
      problem := "Required evidence is missing, incomplete, unsupported or invalid: owned declarations did not pass kernel admission, a frozen source changed during the audit, or authentication the result needs could not complete. The result is INCOMPLETE."
      action := "Remove the construction that bypasses kernel checking (or the source change during the run), then run the project command that collects the missing evidence."
      trigger := [
        "Before accepting proof evidence the checker replays every owned logical declaration and its owned dependencies through Lean's kernel (`Admission.validate`). A declaration that fails replay, source bytes that changed after they were frozen, or a required authentication that failed is reported here with impact `incomplete`.",
        "In the editor, this rule marks results that need fresh evidence only the project command collects, and names `lake lint`."]
      rationale := [
        "Successful elaboration alone is not checked admission: metaprograms and debug options can store declarations the kernel never checked. An accepted result must rest on kernel-checked evidence for the exact frozen sources."]
      fixes := [
        "Remove uses of `debug.skipKernelTC`, `addDecl` with unchecked values, or other metaprograms that add unchecked declarations; state and prove the theorem normally.",
        "Do not edit sources while an audit runs; rerun it.",
        "For an editor pending result, run `lake lint` (or `lake lint -- --fresh`)."]
      proofShape := [
        "The replayed declaration must type-check in the kernel with exactly its stated type and value."]
      established := [
        "Every owned logical declaration and its owned dependencies passed kernel replay, and the frozen sources were unchanged during the audit. A failed admission or changed source is incomplete and never accepted."]
      notEstablished := [
        "Imported, unowned dependencies are not replayed; they remain the declared trusted base.",
        "Incremental admission does not establish fresh source elaboration."]
      configuration := [
        "No option waives admission. A failed generated-role authentication cannot waive PL1001 or PL1006.",
        projectCommands]
      limitations := [
        "This page's example is a diagnostic demonstration: the violating run is INCOMPLETE by design and is not accepted negative evidence. Its corrected counterpart passed a completed positive check."]
      correction := "The correction replaces ill-typed unchecked evidence with a checked proof of the same reflexivity statement."
      residuals := [.qualify]
      checklist := ["DECL-01", "DECL-02", "FOUND-05"]
      sources := ["lean/Plumb/Checker/Admission.lean", "lean/Plumb/Checker/SourceAudit.lean", "lean/Plumb/Checker/SourceBinding.lean"] }
  | .executionUnresolved => {
      problem := "The conservative execution closure of an executable root has a path the checker could not resolve: a missing compiled body, unavailable replacement history, an unsupported evaluator, or a cycle of replacement edges. The execution claim is INCOMPLETE."
      action := "Remove the construction that prevents the analysis (for example a custom evaluator command in the module), or make the missing compiled code available, then rerun."
      trigger := [
        "For every owned executable root the checker follows retained compiler edges, logical value dependencies, `csimp` candidates, observed `implemented_by` choices and partial helpers. Anything it cannot resolve or classify is reported with applicability `execution-unresolved` and impact `incomplete`, in both `report` and `checked` execution modes.",
        "Replacement history is reconstructed by fresh re-elaboration; metaprogramming commands such as `run_cmd`, `run_elab` or module-local elaborators make it unavailable."]
      rationale := [
        "An execution account that silently skipped an unresolved path would overstate what the compiled program is known to run."]
      fixes := [
        "Remove metaprogramming commands from modules whose `implemented_by` history must be authenticated, or move them elsewhere.",
        "Ensure every dependency's compiled code is available in the build.",
        "Break cycles consisting only of replacement edges."]
      proofShape := [
        "No proof obligation for this rule; once resolved, checked execution may require correspondence proofs (PL3002)."]
      established := [
        "Every path in each owned executable root's conservative closure was resolved and classified; an unresolved path is incomplete and never accepted."]
      notEstablished := [
        "That the conservative closure is the program's actual runtime call graph: candidates and historical choices overapproximate it, and a safe program can be rejected."]
      configuration := [
        "No execution mode waives an unresolved path.",
        projectCommands]
      limitations := [
        "This page's example is a diagnostic demonstration: the violating run is INCOMPLETE by design and is not accepted negative evidence. Its corrected counterpart passed a completed positive check.",
        "The editor may defer execution analysis to the project command."]
      correction := "The correction removes a no-effect custom evaluator command that prevents history authentication; the reference, replacement and correspondence theorem are unchanged."
      residuals := [.qualify, .invariant, .intent]
      checklist := ["COMP-03", "SCOPE-05"]
      sources := ["lean/Plumb/Probe.lean", "lean/PlumbCore/Policy.lean", "lean/Plumb/Checker/RuleDiagnostics.lean"] }
  | .executionBoundary => {
      problem := "On a surface claiming `\"execution\": \"checked\"`, a reachable boundary other than a toolchain native-runtime primitive lacks kernel-checked correspondence: for example an `implemented_by` replacement without an admitted equality proof, an external `extern`, or unsafe or partial computation."
      action := "Prove the replacement equal to its reference on the complete domain, or remove the trusted boundary, or claim `report` execution instead and keep the boundary reported."
      trigger := [
        "Each reached boundary gets a kind and a correspondence state. Under checked execution, a boundary that is `trusted` rather than `checked` (other than origin-checked `Init` runtime primitives) is rejected with applicability `execution-trusted-boundary`.",
        "A correspondence is checked only when a closed proof of `∀ xs, f xs = g xs` over the reference's complete elaborated domain passes kernel admission, with only standard logical axioms and no extra premises."]
      rationale := [
        "`@[implemented_by g] def f` makes the kernel reason about `f` while compiled code runs `g`. Without a proof relating them, theorems about `f` say nothing about the program's behavior."]
      fixes := [
        "State and prove `theorem f_eq (x) : f x = g x` (either direction, any prefix of the domain with congruence) for the full domain, including implicit and instance arguments.",
        "Replace `implemented_by` with a proof-backed `@[csimp]` equality where it fits.",
        "If an external boundary is intended (an `extern` implementation, or unsafe or partial code in an unclaimed dependency), claim `report` execution, where it is reported as trusted and not failed. An owned `unsafe` or `partial` declaration on a claimed surface still fails PL1006 in either mode."]
      proofShape := [
        "`∀ xs, f.{us} xs = g.{us} xs` over the reference's complete dependent domain, closed, with no additional hypotheses, admitted by the kernel. An actual domain hypothesis is legitimate; an extra premise such as `False` is not."]
      established := [
        "Every reached non-native-runtime boundary of a checked surface has kernel-admitted correspondence."]
      notEstablished := [
        "Correctness of native-runtime primitives, the compiler or external code; a Lean equality does not prove external machine code. These stay trusted and reported.",
        "That the executable roots are the ones the project intends to cover (R-INVARIANT)."]
      configuration := [
        "`execution` in the surface manifest (`report` or `checked`), or `--execution checked` for a single-file audit, selects the mode. `report` mode reports trusted boundaries without failing them; it is not a fix for a checked claim.",
        projectCommands]
      limitations := [
        "Proof search is deliberately incomplete: a candidate whose remaining premises cannot be instantiated supplies no evidence, and the boundary stays trusted."]
      correction := "The correction adds the missing equality between the reference and its replacement on the full natural-number domain, keeping the checked execution claim and both implementations."
      residuals := [.intent, .invariant, .qualify]
      checklist := ["COMP-03", "COMP-04", "SCOPE-03"]
      sources := ["lean/Plumb/Probe.lean", "lean/PlumbCore/Policy.lean", "docs/standard/8-tooling-and-machine-audit.md"] }
  | .fenceStructure => {
      problem := "A Markdown file in the checked documentation tree has a malformed Lean fence classification: an orphan, misplaced, duplicated or misspelled marker, an invalid expected-error pattern, or an unclosed fence."
      action := "Put each `lean-fail` or `lean-trusted-compiler` marker immediately before the `lean` fence it classifies, with a valid pattern, and close every fence."
      trigger := [
        "The documentation scanner classifies every Lean fence in every Markdown file of the selected tree. An unmarked `lean` fence is positive; an immediately adjacent `<!-- lean-fail: PATTERN -->` makes the next fence negative; `<!-- lean-trusted-compiler -->` marks a teaching example. Anything else that looks like a marker, or a structural error, is rejected with applicability `fence-structure`.",
        "The pattern grammar is small: `|` separates alternatives, `.*` separates ordered literal fragments, and an optional leading `(?s)` is accepted for compatibility; other regex syntax is rejected."]
      rationale := [
        "A misspelled or misplaced marker must not silently turn a negative example into a positive one or hide a fence from checking. Fail-closed structure keeps every documented Lean claim checked as intended."]
      fixes := [
        "Move the marker so no blank line or other content separates it from its fence.",
        "Delete orphan markers, or add the fence they were meant to classify.",
        "Use the exact marker spelling; write non-Lean sketches with another fence language."]
      proofShape := [
        "No proof obligation: the rule concerns document structure. Each classified fence is then checked by PL4002, PL4003 or PL4004."]
      established := [
        "Every Lean fence in the checked tree has exactly one valid classification."]
      notEstablished := [
        "That the prose around a fence describes it faithfully (R-DOC)."]
      configuration := [
        "The checked tree is the documentation tree the audit selects (`docs/` for `lake exe docFenceAudit`). There is no per-fence opt-out.",
        "This rule is a documentation-mode rule; it is not reported by the per-declaration editor linter."]
      limitations := [
        "Only Markdown structure is checked here; elaboration results belong to PL4002–PL4004."]
      correction := "The correction removes the orphan marker; the positive reflexivity fence is unchanged."
      residuals := [.qualify, .doc]
      checklist := ["DOC-03"]
      sources := ["lean/Plumb/Checker/Documentation.lean", "lean/Plumb/Checker/Diagnostics.lean", "lean/PlumbPolicy/Pattern.lean"] }
  | .positiveExample => {
      problem := "A positive Lean fence in the documentation did not elaborate verbatim and warning-free, or it did and then failed admission or the declaration and axiom rules."
      action := "Make the example correct as printed: fix its errors or warnings, and make its declarations satisfy the same rules as project code."
      trigger := [
        "Each positive fence is elaborated exactly as printed, with no inserted imports or wrappers, against a fresh build of the claimed libraries. It must be warning-free, pass checked admission, and pass the declaration and axiom rules under Standard-Logical. The fence failure is reported here together with the underlying finding (for example PL1001 for an axiom in the example)."]
      rationale := [
        "Readers copy documented examples and trust them. A positive example that does not elaborate, or that proves its claim with an axiom, teaches a false claim."]
      fixes := [
        "Fix the underlying finding shown with this diagnostic (for example prove the statement instead of declaring an axiom).",
        "If the example is meant to fail, mark it with an exact `lean-fail` marker instead (PL4003).",
        "Import what the example needs inside the fence; the checker inserts nothing."]
      proofShape := [
        "The fence proves exactly the claim the surrounding prose states. A narrower foundation or an execution claim in the prose needs its own evidence; fence success establishes only Standard-Logical admission."]
      established := [
        "The positive fence elaborated verbatim, warning-free, passed owned admission and the declaration and axiom rules."]
      notEstablished := [
        "That the prose describes the fence faithfully (R-DOC, R-INTENT), or any narrower foundation claim."]
      configuration := [
        "No marker makes a failing positive example acceptable; changing it to `lean-fail` changes what the documentation claims.",
        "Run `lake exe docFenceAudit` (or `./scripts/verify.sh docs` in this repository)."]
      limitations := [
        "Examples are checked under the declared toolchain only."]
      correction := "The correction proves the same reflexivity claim in the positive fence; the violation reports the PL1001 underlying rejection alongside PL4002."
      residuals := [.intent, .qualify]
      checklist := ["DOC-04"]
      sources := ["lean/Plumb/Checker/Documentation.lean", "lean/Plumb/Checker/SourceAudit.lean", "lean/Plumb/Checker/Admission.lean"] }
  | .negativeExample => {
      problem := "A fence marked `lean-fail` did not fail as specified: it elaborated successfully, failed for a different reason, or the worker crashed or timed out."
      action := "Make the example fail for exactly the documented reason, adjust the pattern to match one real error message, or remove the marker if the example is valid."
      trigger := [
        "A negative fence must complete with a source rejection, and one effective error message must match the entire expected pattern. Informational output, a pattern matched across several messages, a crash, a timeout or a successful elaboration does not pass."]
      rationale := [
        "A negative example documents what Lean rejects. If it stops failing, or fails for another reason, the documentation claims a rejection that no longer holds."]
      fixes := [
        "If the example is actually valid, remove the `lean-fail` marker so it is checked as positive.",
        "If it should fail, edit the example so it fails for the documented reason, and write a pattern that matches that one error message.",
        "Keep patterns to literal fragments joined by `.*` and alternatives separated by `|`."]
      proofShape := [
        "No proof obligation: the example demonstrates a rejection. Its pattern is part of the claim and is reviewed with the prose."]
      established := [
        "The negative fence completed with a source rejection whose single error message matches the whole pattern."]
      notEstablished := [
        "That the rejection happens for the conceptual reason the prose explains beyond the matched message text."]
      configuration := [
        "The marker and its pattern are the configuration; there is no option that accepts a non-failing negative example."]
      limitations := [
        "Plumb policy rejections of documentation examples can follow successful elaboration; this rule concerns compiler rejection patterns of `lean-fail` fences."]
      correction := "The correction labels an already valid reflexivity proof as a positive example instead of inventing a compiler failure."
      residuals := [.qualify, .doc]
      checklist := ["DOC-05"]
      sources := ["lean/Plumb/Checker/Diagnostics.lean", "lean/PlumbPolicy/Pattern.lean", "lean/Plumb/Website.lean"] }
  | .trustedExample => {
      problem := "A fence marked `lean-trusted-compiler` did not elaborate warning-free with an authenticated compiler-trusting declaration: it contains no native proof, or authentication failed."
      action := "Use the marker only for an example that demonstrates `native_decide` (or another authenticated compiler-trusting mechanism); otherwise remove it."
      trigger := [
        "A teaching fence must elaborate warning-free and the checker must authenticate at least one compiler-trusting declaration in it, using the same fresh-frontend evidence as PL1004. If none is found, or authentication fails, the fence is rejected with applicability `trusted-example`."]
      rationale := [
        "Conforming claims reject compiler-trusting proofs (PL1004). A teaching fence is how the documentation shows one: it is classified and never counts as a conforming positive. A marker on an ordinary example would hide it from positive checking."]
      fixes := [
        "Remove the marker from an example that is an ordinary kernel proof; it is then checked as a positive example.",
        "For a genuine teaching example, keep the `native_decide` proof and import only the module that provides it (for example `import Init`)."]
      proofShape := [
        "No proof obligation: the example demonstrates a compiler-trusting mechanism and is excluded from conforming evidence."]
      established := [
        "The teaching fence elaborated warning-free and contains an authenticated compiler-trusting declaration."]
      notEstablished := [
        "Any conformance of the teaching example; it is classified, never counted as a positive proof."]
      configuration := [
        "There is no name-based allowlist for native proofs; authentication is required for every teaching fence."]
      limitations := [
        "Teaching fences are re-elaborated for authentication, so their imports are paid twice; keep them small."]
      correction := "The correction labels the same kernel proof as a positive example rather than as native teaching."
      residuals := [.qualify]
      checklist := ["DOC-05"]
      sources := ["lean/Plumb/Checker/Documentation.lean", "lean/Plumb/Checker/Frontend.lean", "lean/PlumbPolicy/Decision.lean"] }
  | .moduleDocumentation => {
      problem := "A module in a claimed surface has no module docstring (`/-! … -/` or Verso module documentation)."
      action := "Add a module docstring that identifies the module's material declarations and assumptions."
      trigger := [
        "When a claimed module finishes elaborating, the checker asks Lean for its module documentation. A module without any is rejected with applicability `module-documentation`. Empty modules are included."]
      rationale := [
        "Module documentation tells a reader which declarations carry the module's claims and under which assumptions, so the claims can be reviewed without reading every proof."]
      fixes := [
        "Add `/-! … -/` at the top of the module, after the imports.",
        "Follow the template in standard §5.3: purpose, main declarations with their results and hypotheses, assumptions and dependencies, design notes. Keep only sections that help."]
      proofShape := [
        "No proof obligation: the rule checks presence of documentation."]
      established := [
        "Every claimed module has module documentation metadata."]
      notEstablished := [
        "That the documentation identifies all material declarations and assumptions, or describes them faithfully (R-DOC). Presence says nothing about content; no headings or layout are imposed."]
      configuration := [noLocalException, projectCommands]
      limitations := [
        "The editor reports this rule only when the module has finished elaborating."]
      correction := "The correction adds module documentation to the unchanged reflexivity evidence."
      residuals := [.doc]
      checklist := ["DOC-01"]
      sources := ["lean/Plumb/Linter/Documentation.lean", "lean/Plumb/Checker/AxiomGate.lean", "docs/standard/5-documentation-standards.md"] }
  | .materialDocumentation => {
      problem := "A public declaration registered with `@[plumb_material]` as evidence for a material normative claim has no docstring."
      action := "Add a docstring stating the declaration's formal purpose, domain and hypotheses, result and boundary, with a labelled `# Intent` section (PL5003)."
      trigger := [
        "The checker selects public declarations carrying the persistent `@[plumb_material]` registration and asks Lean for their docstrings (`findDocString?`, which includes inherited documentation). A registered declaration without one is rejected with applicability `material-documentation`.",
        "Unregistered declarations are not selected; there is no name heuristic."]
      rationale := [
        "A material claim must be readable without reconstructing it from the proof: the docstring states what the declaration establishes and under which assumptions, and binds the written intent to that exact declaration."]
      fixes := [
        "Add `/-- … -/` immediately before the declaration, stating purpose, domain and hypotheses, result and boundary (standard §5.1).",
        "Include a `# Intent` section with the requirement the claim must meet (standard §5.2); a missing Intent section is PL5003."]
      proofShape := [
        "No proof obligation: the rule checks presence. The docstring must describe the elaborated statement faithfully."]
      established := [
        "Every registered public material declaration has a docstring."]
      notEstablished := [
        "That every material declaration is registered, or that the docstring is faithful and adequate (R-DOC); registration completeness is semantic review.",
        "Docstrings of unregistered, private or trivial declarations, which the standard recommends but does not require."]
      configuration := [
        noLocalOption,
        "Registration is `@[plumb_material]` from `Plumb.MaterialClaim`. Removing a registration from a material declaration changes the reviewed claim, not only this rule's result.",
        projectCommands]
      limitations := [
        "Lean's broader `linter.missingDocs` checks all public declarations; this rule deliberately covers only registered material evidence."]
      correction := "The correction adds the registered theorem's docstring, including its `# Intent` section; registration, proposition and proof are unchanged."
      residuals := [.doc]
      checklist := ["DOC-01"]
      sources := ["lean/Plumb/MaterialClaim.lean", "lean/PlumbPolicy/Intent.lean", "lean/Plumb/Linter/Documentation.lean"] }
  | .materialIntent => {
      problem := "A registered public material declaration has a docstring without a nonempty labelled Intent section."
      action := "Add a heading whose text is exactly `Intent` to the docstring, followed by the requirement the claim must meet, stated from the source mathematics or specification."
      trigger := [
        "An Intent section is an ATX heading line whose text is exactly `Intent` (one to six `#`, no closing sequence), followed before the next heading of equal or higher level by at least one non-heading line with text. Text under deeper subsection headings counts. A registered docstring without such a section is rejected with applicability `material-intent`.",
        "A declaration with no docstring at all is PL5002 only; the two rules partition the failures."]
      rationale := [
        "The explanation states what the formal statement says; the intent states what it is required to say. Comparing the two, and both with the declaration, exposes statements that are faithfully explained but wrong (standard §5.2)."]
      fixes := [
        "Add `# Intent` with the requirement in your own words, derived from the source mathematics or program specification, not from the Lean statement.",
        "Prefer a level-one heading; a top-level Verso docstring header must be `#`."]
      proofShape := [
        "No proof obligation: the rule checks presence. The Intent text is compared with the declaration in review."]
      established := [
        "Every registered public material declaration's docstring has a nonempty labelled Intent section, decided by the proved classifier `PlumbPolicy.materialDocumentationFailure`."]
      notEstablished := [
        "That the intent states what the requirement owner needs, or that the declaration meets it (R-INTENT, R-DOC). There is no intent detector, length threshold or similarity check.",
        "Code fences in the docstring are not tracked: a `# Intent` line inside a fenced block counts as an Intent heading."]
      configuration := [
        noLocalOption,
        "The rule checks only declarations registered with `@[plumb_material]` from `Plumb.MaterialClaim`. Removing a registration from a material declaration changes the reviewed claim, not only this rule's result.",
        projectCommands]
      limitations := [
        "Setext headings and closing sequences such as `# Intent #` are not recognized as Intent headings."]
      correction := "The correction adds a nonempty `# Intent` section, structured with a `## Requirement` subsection, to the registered theorem's existing docstring; the explanation, registration, proposition and proof are unchanged."
      residuals := [.intent, .doc]
      checklist := ["DOC-02"]
      sources := ["lean/PlumbPolicy/Intent.lean", "lean/Plumb/MaterialClaim.lean", "lean/Plumb/Linter/Documentation.lean"] }

/-- Every rule's explanation has all required sections, checked exhaustively over the closed
registry by kernel evaluation. -/
theorem guide_wellFormed : ∀ id, (guide id).WellFormed := by
  intro id; cases id <;> decide +kernel

end Plumb.Site
