import StrictLeanPolicy.Specification

/-! Actual generated-role validators and declaration decisions over admitted observations.
Role receipts carry equality to these executed validators for the exact inventory.
Independent predicate equivalence and least-foundation theorems belong to #6. -/
namespace StrictLeanPolicy
open Lean (Name)
open Frontend

/-- Semantic failures are mapped to the one diagnostic registry by the adapter. -/
inductive DeclarationFailure where
  | projectAxiom | proofHole | unknownAxiom | escapeHatch | compilerTrusting
  | executableContract | profileExceeded | invalidInventory
  deriving Repr, DecidableEq

/-- Inspection and teaching cannot serve as a positive conformance profile. -/
inductive InspectionRequest where
  | classification | teaching | conforming (profile : ConformingProfile)
  deriving Repr, DecidableEq

def ConformingProfile.permits : ConformingProfile → Name → Bool
  | .kernelOnly, _ => false
  | .choiceFree, n => n == `propext || n == `Quot.sound
  | .standardLogical, n => n == `propext || n == `Quot.sound || n == `Classical.choice

def standardLogicalAxiom (name : Name) : Bool :=
  ConformingProfile.permits .standardLogical name

def builtinCompilerAxiom (name : Name) : Bool :=
  name == `Lean.trustCompiler || name == `Lean.ofReduceBool
    || name == `Lean.ofReduceNat

private def arraySubset (values allowed : Array Name) : Bool :=
  values.all allowed.contains

private def nativeParent? : Name → Option Name
  | .str (.str (.str parent "_native") "native_decide") suffix => do
      guard (parent != .anonymous && suffix.startsWith "ax_")
      let numbers := (suffix.drop 3).toString.splitOn "_"
      guard (!numbers.isEmpty && numbers.all fun n => !n.isEmpty && n.toList.all Char.isDigit)
      return parent
  | _ => none

/-- Only declaration kinds that could receive a generated-role exception need
the extra fresh frontend transcript. This core works over primitive fields so
a batched harness can apply the identical predicate to raw environment
constant records before paying any environment load. -/
def declarationNeedsTranscript (isUnsafe isPartial : Bool) (kind : DeclarationKind) (name : Name) : Bool :=
  isUnsafe || isPartial || (kind == .«axiom» && (nativeParent? name).isSome)

/-- Only declaration kinds that could receive a generated-role exception need
the extra fresh frontend transcript. -/
def needsFrontendTranscript (decls : Array Declaration) : Bool :=
  decls.any fun decl =>
    declarationNeedsTranscript decl.isUnsafe decl.isPartial decl.kind decl.name

private def positionLE (a b : Position) : Bool :=
  a.line < b.line || (a.line == b.line && a.column <= b.column)

private def declarationRange? (decl : Declaration) : Option SyntaxRange := do
  let ranges ← decl.ranges
  return { start := ranges.range.start, «end» := ranges.range.«end» }

private def commandForDecl (transcripts : Array Transcript)
    (moduleName declarationName : Name) : Option Command := Id.run do
  let mut found : Array Command := #[]
  for transcript in transcripts do
    if transcript.«module» == moduleName then
      for command in transcript.commands do
        if command.added.contains declarationName then
          found := found.push command
  if found.size == 1 then found[0]? else none

private def nativeCommandForAxiom (transcripts : Array Transcript)
    (ax : Declaration) (parentName : Name) : Option Command := Id.run do
  let mut found : Array Command := #[]
  for transcript in transcripts do
    if transcript.«module» == ax.«module» then
      for command in transcript.commands do
        let roleMatches := command.addedDeclarations.filter fun added =>
          nativeParent? added.name == some parentName
            && added.kind == .«axiom» && added.«type» == ax.«type»
        if roleMatches.size == 1 then found := found.push command
  if found.size == 1 then found[0]? else none

private def declarationElaborator := `Lean.Elab.Command.elabDeclaration
private def namespacedDeclarationElaborator :=
  `Lean.Elab.Command.expandNamespacedDeclaration
private def declarationKind := `Lean.Parser.Command.declaration
private def nativeDecideElaborator := `Lean.Elab.Tactic.evalNativeDecide
private def nativeDecideKind := `Lean.Parser.Tactic.nativeDecide

structure EvaluatorKey where
  role : EvaluatorRole
  elaborator : Name
  kind : Name
  deriving Repr, BEq

private def key (value : Evaluator) : EvaluatorKey :=
  { role := value.role, elaborator := value.elaborator, kind := value.kind }

private def nativeDecideChain : Array EvaluatorKey := #[
  ⟨.command, declarationElaborator, declarationKind⟩,
  ⟨.tactic, .anonymous, `Lean.Parser.Term.byTactic⟩,
  ⟨.tactic, .anonymous, `by⟩,
  ⟨.tactic, `Lean.Elab.Tactic.evalTacticSeq, `Lean.Parser.Tactic.tacticSeq⟩,
  ⟨.tactic, `Lean.Elab.Tactic.evalTacticSeq1Indented,
    `Lean.Parser.Tactic.tacticSeq1Indented⟩,
  ⟨.tactic, nativeDecideElaborator, nativeDecideKind⟩
]

private def literalDeclarationCommand (command : Command)
    (declRange : SyntaxRange) : Bool :=
  command.commandKind == declarationKind && command.commandRange == some declRange
    && (command.commandElaborator == declarationElaborator
      || (command.commandElaborator == namespacedDeclarationElaborator
        && (command.evaluators.filter fun evaluator =>
          evaluator.role == .command
            && evaluator.elaborator == declarationElaborator
            && evaluator.kind == declarationKind
            && evaluator.range == some declRange).size == 1))

private def evaluatorChain (command : Command) : Array EvaluatorKey :=
  (command.evaluators.filter (·.role != .term)).map key

private def supportedEvaluator (evaluator : Evaluator) : Bool :=
  evaluator.pinned && evaluator.elaborator != `Lean.Elab.Tactic.evalRunTac
    && evaluator.elaborator != `Lean.Elab.Term.elabRunElab

/-- Recognize one built-in declaration command at any namespace depth with any
`termination_by`/`decreasing_by` block: the command is Lean's literal
declaration elaborator for the base's exact range, every recorded evaluator is
pinned to the toolchain, an imported library, or a pure syntax macro, and no
evaluator is `run_tac` or `by_elab`, which execute audited-source metaprograms inside
the declaration command. -/
private def supportedRecursiveCommand (command : Command)
    (base : Declaration) (declRange : SyntaxRange) : Bool :=
  let nested := do
    let outer ← command.commandRange
    let ranges ← base.ranges
    let selection : SyntaxRange := {
      start := ranges.selectionRange.start, «end» := ranges.selectionRange.«end» }
    pure <| literalDeclarationCommand command outer &&
      positionLE outer.start declRange.start && positionLE declRange.«end» outer.«end» &&
      command.bindings.any (fun binding => binding.name == base.name && binding.range == some selection)
  (literalDeclarationCommand command declRange || nested.getD false)
    && command.evaluators.all supportedEvaluator

private def supportedNativeCommand (command : Command)
    (declRange : SyntaxRange) : Bool :=
  literalDeclarationCommand command declRange
    && command.evaluators.all supportedEvaluator
    && evaluatorChain command == nativeDecideChain

private def findDecl? (decls : Array Declaration) (name : Name) :
    Option Declaration :=
  decls.find? (·.name == name)

/-- Authenticate native proof axioms by exact semantics and fresh built-in
frontend attribution. -/
private def authorizedNativeAxioms (decls : Array Declaration)
    (transcripts : Array Transcript := #[]) : Array Name := Id.run do
  let mut authorized : Array Name := #[]
  for ax in decls do
    let some parentName := nativeParent? ax.name | continue
    if ax.kind != .«axiom» || !ax.internal || !ax.isProp
        || ax.isUnsafe || ax.isPartial || ax.implementedBy.isSome
        || ax.«extern» || !ax.nativeBoolShape
        || ax.nativeReplay != some true || !ax.axioms.contains ax.name
        || !ax.axioms.all (fun name => name == ax.name || standardLogicalAxiom name) then
      continue
    let some parent := findDecl? decls parentName | continue
    if !parent.isProp || !#[DeclarationKind.theorem, .opaque, .definition].contains parent.kind
        || parent.«module» != ax.«module» || !parent.axioms.contains ax.name
        || ax.nativeUseParents != #[parent.name] || parent.isUnsafe
        || parent.isPartial || parent.implementedBy.isSome || parent.«extern» then
      continue
    let directUsers := decls.filter fun decl => decl.valueConstants.contains ax.name
    let some directUser := directUsers[0]? | continue
    if directUsers.size != 1 || directUser.name != parent.name then continue
    let some parentRange := declarationRange? parent | continue
    let some axRange := declarationRange? ax | continue
    if !positionLE parentRange.start axRange.start
        || !positionLE axRange.«end» parentRange.«end» then continue
    let some command := nativeCommandForAxiom transcripts ax parent.name | continue
    let some parentCommand := commandForDecl transcripts parent.«module» parent.name | continue
    if command != parentCommand || !supportedNativeCommand command parentRange
        || !command.added.contains parent.name then continue
    let nativeEvaluators := command.evaluators.filter fun evaluator =>
      evaluator.role == .tactic && evaluator.elaborator == nativeDecideElaborator
        && evaluator.kind == nativeDecideKind
    let some nativeEvaluator := nativeEvaluators[0]? | continue
    if nativeEvaluators.size != 1 || nativeEvaluator.range != some axRange then
      continue
    authorized := authorized.push ax.name
  authorized

/-- Authenticate only Lean's exact range-less helper for a safe recursive base. -/
private def authorizedUnsafeRecHelpers (decls : Array Declaration)
    (transcripts : Array Transcript := #[]) : Array Name := Id.run do
  let mut authorized : Array Name := #[]
  for helper in decls do
    let some baseName := helper.unsafeRecBase | continue
    let some base := findDecl? decls baseName | continue
    if base.kind != .«definition» || helper.kind != .«definition»
        || helper.«module» != base.«module» || !helper.internal
        || helper.ranges.isSome || !helper.isPartial || helper.isUnsafe
        || helper.hints != some .opaque || helper.implementedBy.isSome
        || helper.«extern» then continue
    if helper.unsafeRecValueOrigin.isNone
        || helper.unsafeRecValueExact != some true
        || helper.unsafeRecValueDefeq != some true
        || helper.unsafeRecEquationExact != some true
        || helper.unsafeRecEquationDefeq != some true then continue
    let some equationAxioms := helper.unsafeRecEquationAxioms | continue
    if !equationAxioms.all (fun name =>
        standardLogicalAxiom name || base.axioms.contains name) then continue
    if base.isPartial || base.isUnsafe || base.hints != some .regular
        || !base.recursive || base.implementedBy.isSome || base.«extern»
        || helper.«type» != base.«type» || helper.levelParams != base.levelParams
        || !arraySubset helper.axioms base.axioms || base.all.isEmpty then continue
    let expectedHelpers := base.all.map (fun n => Name.str n "_unsafe_rec")
    if helper.all != expectedHelpers || !expectedHelpers.contains helper.name
        || !helper.valueConstants.contains helper.name then continue
    let some baseRange := declarationRange? base | continue
    let some command := commandForDecl transcripts helper.«module» helper.name | continue
    let some baseCommand := commandForDecl transcripts base.«module» baseName | continue
    if command != baseCommand || !supportedRecursiveCommand command base baseRange
        || !base.all.all command.added.contains
        || !expectedHelpers.all command.added.contains then continue
    authorized := authorized.push helper.name
  authorized

private def compilerAxiom (native : Array Name) (name : Name) : Bool :=
  builtinCompilerAxiom name || native.contains name

private def labelOf (axioms : Array Name) (native : Array Name := #[]) : FoundationClass :=
  if axioms.contains `sorryAx then .hole
  else if axioms.any fun name => !standardLogicalAxiom name && !compilerAxiom native name then
    .unknownAxiom
  else if axioms.any (compilerAxiom native) then .compilerTrusting
  else if axioms.isEmpty then .kernelOnly
  else if axioms.all (ConformingProfile.permits .choiceFree) then .choiceFree
  else .standardLogical

private def declarationFailure (decl : Declaration) (claim : InspectionRequest)
    (native : Array Name := #[]) (unsafeHelpers : Array Name := #[]) :
    Option DeclarationFailure :=
  if decl.kind == .«axiom» then
    if native.contains decl.name then
      if claim == .teaching then none else some .compilerTrusting
    else some .projectAxiom
  else if decl.axioms.contains `sorryAx then some .proofHole
  else if decl.axioms.any fun name =>
      !standardLogicalAxiom name && !compilerAxiom native name then some .unknownAxiom
  else if (decl.isUnsafe || decl.isPartial) && !unsafeHelpers.contains decl.name then
    some .escapeHatch
  else if decl.axioms.any (compilerAxiom native) && claim != .teaching then
    some .compilerTrusting
  else if decl.executableContract.any (·.failure.isSome) then some .executableContract
  else match claim with
    | .conforming profile =>
        if decl.axioms.all fun name => compilerAxiom native name || ConformingProfile.permits profile name
        then none else some .profileExceeded
    | .classification | .teaching => none


/-- Inventory-bound observations of the actual role validators. Supplying arbitrary
name arrays cannot authorize a role: both equations must be proved for this inventory. -/
structure Roles (inventory : Inventory) where
  native : Array Name
  helpers : Array Name
  native_exact : native = authorizedNativeAxioms inventory.declarations inventory.transcripts
  helpers_exact : helpers = authorizedUnsafeRecHelpers inventory.declarations inventory.transcripts

/-- Recompute both validators from the admitted data; no serialized proof is trusted. -/
def authorize (i : Inventory) : Roles i :=
  ⟨authorizedNativeAxioms i.declarations i.transcripts,
   authorizedUnsafeRecHelpers i.declarations i.transcripts, rfl, rfl⟩

/-- Public policy checks exact inventory membership before using role evidence. -/
def policyFor (i : Inventory) (roles : Roles i) (d : Declaration)
    (request : InspectionRequest) : Option DeclarationFailure :=
  if d ∈ i.declarations then declarationFailure d request roles.native roles.helpers
  else some .invalidInventory

/-- Foundation rendering uses the same inventory-bound generated-role result. -/
def foundationFor (i : Inventory) (roles : Roles i) (d : Declaration) :
    Except String FoundationClass :=
  if d ∈ i.declarations then .ok (labelOf d.axioms roles.native)
  else .error "declaration is not a member of the authenticated inventory"
end StrictLeanPolicy
