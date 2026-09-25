module

public import PlumbCore.RuleId
public import PlumbPolicy.Foundation
public import PlumbPolicy.Intent

@[expose] public section

/-! Shared metadata. See RuleId for con-leche attribution and docs/guides/rule-registry.md
for the boundary between existing checker detection and planned product adapters. -/
namespace Plumb

abbrev EvidenceMode := PlumbPolicy.EvidenceMode
abbrev EvidenceMode.spelling (mode : EvidenceMode) : String := PlumbPolicy.EvidenceMode.spelling mode

/-- Retired IDs remain descriptors; replacement cannot be the retired ID itself. -/
inductive Lifecycle (id : RuleId) where
  | active (introduced : String)
  | retired (introduced version : String) (replacement : Option { other : RuleId // other ≠ id })

inductive RuleCategory where
  | foundation | declaration | execution | environment | configuration
  | elaboration | coverage | admission | documentation
  deriving Repr, BEq, DecidableEq

inductive Severity where
  | error | warning | information
  deriving Repr, BEq, DecidableEq

/-- The severity names used by the registry, diagnostics and the intent screen's configuration. -/
def Severity.spelling : Severity → String
  | .error => "error" | .warning => "warning" | .information => "information"

/-- Availability names the detector, not completion of every future adapter. -/
inductive Availability where
  | existingChecker | plannedEngine
  deriving Repr, BEq, DecidableEq

structure Attribution where
  project : String
  authors : String
  url : String
  revision : String
  idea : String
  copiedCode : Bool
  deriving Repr

def registryAttribution : Attribution := {
  project := "con-leche"
  authors := "Joachim Breitner and contributors, Lean FRO"
  url := "https://github.com/leanprover/con-leche/blob/c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0/ConLeche/Kernel/PropWhen.lean"
  revision := "c431b1ca1b7a93486dd3e0440d3ee82abe90ccd0"
  idea := "Canonical typed representation and complete indexed metadata; no imported correctness theorem"
  copiedCode := false }

inductive RuleScope where
  | declaration | project | executionRoot | documentationFence | module | materialDeclaration
  deriving Repr, BEq, DecidableEq

inductive EvidenceKind where
  | kernelAxioms | generatedRole | contractEvidence | environment | configuration
  | compilation | inventory | admission | executionClosure | fenceGrammar
  | checkedExample | metadataPresence
  deriving Repr, BEq, DecidableEq

def scopeFor : RuleId → RuleScope
  | .projectAxiom | .proofHole | .unknownAxiom | .compilerTrusting | .profileExceeded
  | .escapeHatch | .executableContract => .declaration
  | .environment | .configuration | .sourceBuild | .coverage | .admission => .project
  | .executionUnresolved | .executionBoundary => .executionRoot
  | .fenceStructure | .positiveExample | .negativeExample | .trustedExample => .documentationFence
  | .moduleDocumentation => .module
  | .materialDocumentation | .materialIntent => .materialDeclaration

def evidenceFor : RuleId → EvidenceKind
  | .projectAxiom | .proofHole | .unknownAxiom | .profileExceeded => .kernelAxioms
  | .compilerTrusting | .escapeHatch => .generatedRole
  | .executableContract => .contractEvidence
  | .environment => .environment
  | .configuration => .configuration
  | .sourceBuild => .compilation
  | .coverage => .inventory
  | .admission => .admission
  | .executionUnresolved | .executionBoundary => .executionClosure
  | .fenceStructure => .fenceGrammar
  | .positiveExample | .negativeExample | .trustedExample => .checkedExample
  | .moduleDocumentation | .materialDocumentation | .materialIntent => .metadataPresence

/-- The message of every rendered diagnostic of `id`: `Plumb.Diagnostic.text` is this line
followed by a newline and the rule's help URL. A detail can itself span several lines. -/
def messageLine (id : RuleId) (impact mode claim location subject detail : String) : String :=
  id.spelling ++ " [" ++ impact ++ "; " ++ mode ++ "; claim=" ++ claim ++ "; " ++ location ++ "]: " ++
    subject ++ ": " ++ detail

/-- The published message form: `messageLine` applied to placeholder names, so the registry
and site show the same definition the checker renders. -/
def messageForm (id : RuleId) : String :=
  messageLine id "{impact}" "{mode}" "{claim}" "{location}" "{subject}" "{detail}"

/-- Identity and route are projections of the index, never independent fields. -/
structure RuleDescriptor (id : RuleId) where
  title : String
  category : RuleCategory
  normativeClauses : List String
  applicability : String
  availability : Availability
  evidenceModes : List EvidenceMode
  lifecycle : Lifecycle id := .active "unreleased"
  defaultStrictSeverity : Severity := .error
  scope : RuleScope := scopeFor id
  evidenceKind : EvidenceKind := evidenceFor id
  attribution : Attribution := registryAttribution

namespace RuleDescriptor
def identity {id : RuleId} (_ : RuleDescriptor id) : RuleId := id
def helpRoute {id : RuleId} (_ : RuleDescriptor id) : String := id.route
/-- The message form is derived from the index, never an independent field. -/
def messageTemplate {id : RuleId} (_ : RuleDescriptor id) : String := messageForm id
end RuleDescriptor

def declarationModes : List EvidenceMode :=
  [.incrementalProject, .freshProject, .freshFile, .documentationExample]

/-- The modes of the completed-module documentation rules: the editor and whole-project audits.
Single-file and documentation-example audits have no documentation-presence stage. -/
def projectModes : List EvidenceMode := [.editorSnapshot, .incrementalProject, .freshProject]

/-- Total bridge from the executed policy decision to the single rule registry. -/
def ruleForFailure : PlumbPolicy.DeclarationFailure → RuleId
  | .projectAxiom => .projectAxiom | .proofHole => .proofHole
  | .unknownAxiom => .unknownAxiom | .escapeHatch => .escapeHatch
  | .compilerTrusting => .compilerTrusting | .executableContract => .executableContract
  | .profileExceeded => .profileExceeded | .invalidInventory => .coverage

/-- Distinct policy failures reach distinct rules, so the rule preserves the failure category. -/
theorem ruleForFailure_injective : Function.Injective ruleForFailure := by
  intro a b h
  cases a <;> cases b <;> first | rfl | cases h

/-- Total bridge from the executed material-documentation classification
(`PlumbPolicy.materialDocumentationFailure`) to the single rule registry. -/
def ruleForMaterialDocumentation : PlumbPolicy.MaterialDocumentationFailure → RuleId
  | .missingDocstring => .materialDocumentation
  | .missingIntent => .materialIntent

/-- The two material-documentation failures reach distinct rules. -/
theorem ruleForMaterialDocumentation_injective : Function.Injective ruleForMaterialDocumentation := by
  intro a b h
  cases a <;> cases b <;> first | rfl | cases h

/-- Finding detail for each material-documentation failure, prefixed by its rule's applicability. -/
def materialDocumentationDetail : PlumbPolicy.MaterialDocumentationFailure → String
  | .missingDocstring => "material-documentation: document the claim, assumptions and evidence at this declaration"
  | .missingIntent => "material-intent: add a nonempty `# Intent` section stating the requirement this claim must meet"

/-- Total metadata for the reserved vocabulary. Planned detectors never claim availability. -/
def descriptor : (id : RuleId) → RuleDescriptor id
  | .projectAxiom => {
      title := "Project logical axioms are forbidden", category := .foundation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.5"]
      applicability := "project-axiom"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .proofHole => {
      title := "Proof holes are forbidden", category := .foundation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.5"]
      applicability := "hole"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .unknownAxiom => {
      title := "Unknown transitive axioms are forbidden", category := .foundation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.5"]
      applicability := "unknown-axiom"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .compilerTrusting => {
      title := "Compiler-trusting proofs require separate classification", category := .foundation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.5"]
      applicability := "compiler-trusting"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .profileExceeded => {
      title := "Transitive axioms must fit the selected profile", category := .foundation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.5"]
      applicability := "label-exceeds-claim"
      availability := .existingChecker
      evidenceModes := [.editorSnapshot, .incrementalProject, .freshProject, .freshFile] }
  | .escapeHatch => {
      title := "Unsafe and partial declarations require exact helper authentication", category := .declaration
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.4"]
      applicability := "escape-hatch"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .executableContract => {
      title := "Executable contracts require supported closed evidence", category := .execution
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.12", "docs/standard/8-tooling-and-machine-audit.md §8.5"]
      applicability := "executable-contract"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .environment => {
      title := "The declared Lean environment must be available", category := .environment
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.1"]
      applicability := "environment"
      availability := .existingChecker
      evidenceModes := [.incrementalProject, .freshProject, .freshFile] }
  | .configuration => {
      title := "Configuration must classify the complete Lake surface", category := .configuration
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.2"]
      applicability := "configuration"
      availability := .existingChecker
      evidenceModes := [.editorSnapshot, .incrementalProject, .freshProject, .freshFile] }
  | .sourceBuild => {
      title := "Claimed source must elaborate warning-free", category := .elaboration
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.3"]
      applicability := "source-build"
      availability := .existingChecker
      evidenceModes := [.incrementalProject, .freshProject, .freshFile] }
  | .coverage => {
      title := "Owned coverage must match the exact Lake inventory", category := .coverage
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.2"]
      applicability := "coverage"
      availability := .existingChecker
      evidenceModes := [.incrementalProject, .freshProject] }
  | .admission => {
      title := "Required admission and source evidence must be complete", category := .admission
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.3"]
      applicability := "admission"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .executionUnresolved => {
      title := "Execution closure must have no unresolved paths", category := .execution
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.6"]
      applicability := "execution-unresolved"
      availability := .existingChecker
      evidenceModes := [.incrementalProject, .freshProject, .freshFile] }
  | .executionBoundary => {
      title := "Checked execution requires admitted correspondence", category := .execution
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.6"]
      applicability := "execution-trusted-boundary"
      availability := .existingChecker
      evidenceModes := [.incrementalProject, .freshProject, .freshFile] }
  | .fenceStructure => {
      title := "Documentation fences must have a valid classification", category := .documentation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.7"]
      applicability := "fence-structure"
      availability := .existingChecker
      evidenceModes := [.documentationExample] }
  | .positiveExample => {
      title := "Positive examples require warning-free elaboration and admission", category := .documentation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.7"]
      applicability := "positive-example"
      availability := .existingChecker
      evidenceModes := [.documentationExample] }
  | .negativeExample => {
      title := "Negative examples require completed intended rejection", category := .documentation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.7"]
      applicability := "negative-example"
      availability := .existingChecker
      evidenceModes := [.documentationExample] }
  | .trustedExample => {
      title := "Teaching examples require authenticated compiler classification", category := .documentation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.7"]
      applicability := "trusted-example"
      availability := .existingChecker
      evidenceModes := [.documentationExample] }
  | .moduleDocumentation => {
      title := "Claimed modules require module documentation", category := .documentation
      normativeClauses := ["docs/standard/5-documentation-standards.md §5.3"]
      applicability := "module-documentation"
      availability := .existingChecker
      evidenceModes := projectModes }
  | .materialDocumentation => {
      title := "Registered public material declarations require docstrings", category := .documentation
      normativeClauses := ["docs/standard/5-documentation-standards.md §5.1"]
      applicability := "material-documentation"
      availability := .existingChecker
      evidenceModes := projectModes }
  | .materialIntent => {
      title := "Registered public material declarations require an Intent section", category := .documentation
      normativeClauses := ["docs/standard/5-documentation-standards.md §5.2"]
      applicability := "material-intent"
      availability := .existingChecker
      evidenceModes := projectModes }

end Plumb
