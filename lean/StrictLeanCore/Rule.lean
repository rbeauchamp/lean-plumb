module

public import StrictLeanCore.RuleId
public import StrictLeanPolicy.Foundation

@[expose] public section

/-! Shared metadata. See RuleId for con-leche attribution and docs/guides/rule-registry.md
for the boundary between existing checker detection and planned product adapters. -/
namespace StrictLean

abbrev EvidenceMode := StrictLeanPolicy.EvidenceMode
abbrev EvidenceMode.spelling (mode : EvidenceMode) : String := StrictLeanPolicy.EvidenceMode.spelling mode

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
  | .materialDocumentation => .materialDeclaration

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
  | .moduleDocumentation | .materialDocumentation => .metadataPresence

/-- Identity and route are projections of the index, never independent fields. -/
structure RuleDescriptor (id : RuleId) where
  title : String
  category : RuleCategory
  normativeClauses : List String
  applicability : String
  messageTemplate : String
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
end RuleDescriptor

def declarationModes : List EvidenceMode :=
  [.incrementalProject, .freshProject, .freshFile, .documentationExample]

/-- Total bridge from the executed policy decision to the single rule registry. -/
def ruleForFailure : StrictLeanPolicy.DeclarationFailure → RuleId
  | .projectAxiom => .projectAxiom | .proofHole => .proofHole
  | .unknownAxiom => .unknownAxiom | .escapeHatch => .escapeHatch
  | .compilerTrusting => .compilerTrusting | .executableContract => .executableContract
  | .profileExceeded => .profileExceeded | .invalidInventory => .coverage

/-- Distinct policy failures reach distinct rules, so the rule preserves the failure category. -/
theorem ruleForFailure_injective : Function.Injective ruleForFailure := by
  intro a b h
  cases a <;> cases b <;> first | rfl | cases h

/-- Total metadata for the reserved vocabulary. Planned detectors never claim availability. -/
def descriptor : (id : RuleId) → RuleDescriptor id
  | .projectAxiom => {
      title := "Project logical axioms are forbidden", category := .foundation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.5"]
      applicability := "project-axiom", messageTemplate := "SL1001:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .proofHole => {
      title := "Proof holes are forbidden", category := .foundation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.5"]
      applicability := "hole", messageTemplate := "SL1002:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .unknownAxiom => {
      title := "Unknown transitive axioms are forbidden", category := .foundation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.5"]
      applicability := "unknown-axiom", messageTemplate := "SL1003:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .compilerTrusting => {
      title := "Compiler-trusting proofs require separate classification", category := .foundation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.5"]
      applicability := "compiler-trusting", messageTemplate := "SL1004:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .profileExceeded => {
      title := "Transitive axioms must fit the selected profile", category := .foundation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.5"]
      applicability := "label-exceeds-claim", messageTemplate := "SL1005:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .escapeHatch => {
      title := "Unsafe and partial declarations require exact helper authentication", category := .declaration
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.4"]
      applicability := "escape-hatch", messageTemplate := "SL1006:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .executableContract => {
      title := "Executable contracts require supported closed evidence", category := .execution
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.6"]
      applicability := "executable-contract", messageTemplate := "SL1007:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .environment => {
      title := "The declared Lean environment must be available", category := .environment
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.1"]
      applicability := "environment", messageTemplate := "SL2001:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := declarationModes }
  | .configuration => {
      title := "Configuration must classify the complete Lake surface", category := .configuration
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.2"]
      applicability := "configuration", messageTemplate := "SL2002:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .sourceBuild => {
      title := "Claimed source must elaborate warning-free", category := .elaboration
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.3"]
      applicability := "source-build", messageTemplate := "SL2003:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := declarationModes }
  | .coverage => {
      title := "Owned coverage must match the exact Lake inventory", category := .coverage
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.2"]
      applicability := "coverage", messageTemplate := "SL2004:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := declarationModes }
  | .admission => {
      title := "Required admission and source evidence must be complete", category := .admission
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.3"]
      applicability := "admission", messageTemplate := "SL2005:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .executionUnresolved => {
      title := "Execution closure must have no unresolved paths", category := .execution
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.6"]
      applicability := "execution-unresolved", messageTemplate := "SL3001:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := [.incrementalProject, .freshProject, .freshFile] }
  | .executionBoundary => {
      title := "Checked execution requires admitted correspondence", category := .execution
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.6"]
      applicability := "execution-trusted-boundary", messageTemplate := "SL3002:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := [.incrementalProject, .freshProject, .freshFile] }
  | .fenceStructure => {
      title := "Documentation fences must have a valid classification", category := .documentation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.7"]
      applicability := "fence-structure", messageTemplate := "SL4001:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := [.documentationExample] }
  | .positiveExample => {
      title := "Positive examples require warning-free elaboration and admission", category := .documentation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.7"]
      applicability := "positive-example", messageTemplate := "SL4002:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := [.documentationExample] }
  | .negativeExample => {
      title := "Negative examples require completed intended rejection", category := .documentation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.7"]
      applicability := "negative-example", messageTemplate := "SL4003:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := [.documentationExample] }
  | .trustedExample => {
      title := "Teaching examples require authenticated compiler classification", category := .documentation
      normativeClauses := ["docs/standard/8-tooling-and-machine-audit.md §8.7"]
      applicability := "trusted-example", messageTemplate := "SL4004:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := [.documentationExample] }
  | .moduleDocumentation => {
      title := "Claimed modules require module documentation", category := .documentation
      normativeClauses := ["docs/standard/5-documentation-standards.md §5.3"]
      applicability := "module-documentation", messageTemplate := "SL5001:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }
  | .materialDocumentation => {
      title := "Registered public material declarations require docstrings", category := .documentation
      normativeClauses := ["docs/standard/5-documentation-standards.md §5.1"]
      applicability := "material-documentation", messageTemplate := "SL5002:{subject}:{detail}"
      availability := .existingChecker
      evidenceModes := .editorSnapshot :: declarationModes }

end StrictLean
