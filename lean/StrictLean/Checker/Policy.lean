import StrictLean.Checker.Frontend

/-! Exact foundation, generated-role, and computation policy over typed reports. -/

namespace StrictLean.Checker.Policy

open StrictLean.Report
open StrictLean.Checker.Frontend

inductive ExecutionClaim where
  | report
  | checked
  deriving Repr, BEq, DecidableEq, Inhabited

namespace ExecutionClaim

def parse? : String → Option ExecutionClaim
  | "report" => some .report
  | "checked" => some .checked
  | _ => none

def toString : ExecutionClaim → String
  | .report => "report"
  | .checked => "checked"

instance : ToString ExecutionClaim := ⟨toString⟩

end ExecutionClaim

inductive Profile where
  | kernelOnly
  | choiceFree
  | standardLogical
  | compilerTrusting
  deriving Repr, BEq, DecidableEq, Inhabited

namespace Profile

def parse? : String → Option Profile
  | "kernel-only" => some .kernelOnly
  | "choice-free" => some .choiceFree
  | "standard-logical" => some .standardLogical
  | "compiler-trusting" => some .compilerTrusting
  | _ => none

def toString : Profile → String
  | .kernelOnly => "kernel-only"
  | .choiceFree => "choice-free"
  | .standardLogical => "standard-logical"
  | .compilerTrusting => "compiler-trusting"

instance : ToString Profile := ⟨toString⟩

def permits : Profile → String → Bool
  | .kernelOnly, _ => false
  | .choiceFree, name => name == "propext" || name == "Quot.sound"
  | .standardLogical, name
  | .compilerTrusting, name =>
      name == "propext" || name == "Quot.sound" || name == "Classical.choice"

end Profile

def standardLogicalAxiom (name : String) : Bool :=
  Profile.standardLogical.permits name

def builtinCompilerAxiom (name : String) : Bool :=
  name == "Lean.trustCompiler" || name == "Lean.ofReduceBool"
    || name == "Lean.ofReduceNat"

private def arraySubset (values allowed : Array String) : Bool :=
  values.all allowed.contains

private def nativeParent? (name : String) : Option String := do
  let marker := "._native.native_decide.ax"
  let [parent, suffix] := name.splitOn marker | none
  guard (!parent.isEmpty && suffix.startsWith "_")
  let numbers := (suffix.drop 1).toString.splitOn "_"
  guard (!numbers.isEmpty)
  guard <| numbers.all fun number =>
    !number.isEmpty && number.toList.all Char.isDigit
  return parent

/-- Only declaration kinds that could receive a generated-role exception need
the extra fresh frontend transcript. This core works over primitive fields so
a batched harness can apply the identical predicate to raw environment
constant records before paying any environment load. -/
def declarationNeedsTranscript (isUnsafe isPartial : Bool) (kind name : String) : Bool :=
  isUnsafe || isPartial || (kind == "axiom" && (nativeParent? name).isSome)

/-- Only declaration kinds that could receive a generated-role exception need
the extra fresh frontend transcript. -/
def needsFrontendTranscript (decls : Array Declaration) : Bool :=
  decls.any fun decl =>
    declarationNeedsTranscript decl.isUnsafe decl.isPartial decl.kind decl.name

private def positionLE (a b : StrictLean.Report.Position) : Bool :=
  a.line < b.line || (a.line == b.line && a.column <= b.column)

private def declarationRange? (decl : Declaration) : Option SyntaxRange := do
  let ranges ← decl.ranges
  return { start := ranges.range.start, «end» := ranges.range.«end» }

private def commandForDecl (transcripts : Array Transcript)
    (moduleName declarationName : String) : Option Command := Id.run do
  let mut found : Array Command := #[]
  for transcript in transcripts do
    if transcript.«module» == moduleName then
      for command in transcript.commands do
        if command.added.contains declarationName then
          found := found.push command
  if found.size == 1 then found[0]? else none

private def nativeCommandForAxiom (transcripts : Array Transcript)
    (ax : Declaration) (parentName : String) : Option Command := Id.run do
  let mut found : Array Command := #[]
  for transcript in transcripts do
    if transcript.«module» == ax.«module» then
      for command in transcript.commands do
        let roleMatches := command.addedDeclarations.filter fun added =>
          nativeParent? added.name == some parentName
            && added.kind == "axiom" && added.«type» == ax.«type»
        if roleMatches.size == 1 then found := found.push command
  if found.size == 1 then found[0]? else none

private def declarationElaborator := "Lean.Elab.Command.elabDeclaration"
private def namespacedDeclarationElaborator :=
  "Lean.Elab.Command.expandNamespacedDeclaration"
private def declarationKind := "Lean.Parser.Command.declaration"
private def nativeDecideElaborator := "Lean.Elab.Tactic.evalNativeDecide"
private def nativeDecideKind := "Lean.Parser.Tactic.nativeDecide"

structure EvaluatorKey where
  role : String
  elaborator : String
  kind : String
  deriving Repr, BEq

private def key (value : Evaluator) : EvaluatorKey :=
  { role := value.role, elaborator := value.elaborator, kind := value.kind }

private def nativeDecideChain : Array EvaluatorKey := #[
  ⟨"command", declarationElaborator, declarationKind⟩,
  ⟨"tactic", "[anonymous]", "Lean.Parser.Term.byTactic"⟩,
  ⟨"tactic", "[anonymous]", "by"⟩,
  ⟨"tactic", "Lean.Elab.Tactic.evalTacticSeq", "Lean.Parser.Tactic.tacticSeq"⟩,
  ⟨"tactic", "Lean.Elab.Tactic.evalTacticSeq1Indented",
    "Lean.Parser.Tactic.tacticSeq1Indented"⟩,
  ⟨"tactic", nativeDecideElaborator, nativeDecideKind⟩
]

private def literalDeclarationCommand (command : Command)
    (declRange : SyntaxRange) : Bool :=
  command.commandKind == declarationKind && command.commandRange == some declRange
    && (command.commandElaborator == declarationElaborator
      || (command.commandElaborator == namespacedDeclarationElaborator
        && (command.evaluators.filter fun evaluator =>
          evaluator.role == "command"
            && evaluator.elaborator == declarationElaborator
            && evaluator.kind == declarationKind
            && evaluator.range == some declRange).size == 1))

private def evaluatorChain (command : Command) : Array EvaluatorKey :=
  (command.evaluators.filter (·.role != "term")).map key

private def supportedEvaluator (evaluator : Evaluator) : Bool :=
  evaluator.pinned && evaluator.elaborator != "Lean.Elab.Tactic.evalRunTac"
    && evaluator.elaborator != "Lean.Elab.Term.elabRunElab"

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

private def findDecl? (decls : Array Declaration) (name : String) :
    Option Declaration :=
  decls.find? (·.name == name)

/-- Authenticate native proof axioms by exact semantics and fresh built-in
frontend attribution. -/
def authorizedNativeAxioms (decls : Array Declaration)
    (transcripts : Array Transcript := #[]) : Array String := Id.run do
  let mut authorized : Array String := #[]
  for ax in decls do
    let some parentName := nativeParent? ax.name | continue
    if ax.kind != "axiom" || !ax.internal || !ax.isProp
        || ax.isUnsafe || ax.isPartial || ax.implementedBy.isSome
        || ax.«extern» || !ax.nativeBoolShape
        || ax.nativeReplay != some true || !ax.axioms.contains ax.name
        || !ax.axioms.all (fun name => name == ax.name || standardLogicalAxiom name) then
      continue
    let some parent := findDecl? decls parentName | continue
    if !parent.isProp || !#["theorem", "opaque", "def"].contains parent.kind
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
      evaluator.role == "tactic" && evaluator.elaborator == nativeDecideElaborator
        && evaluator.kind == nativeDecideKind
    let some nativeEvaluator := nativeEvaluators[0]? | continue
    if nativeEvaluators.size != 1 || nativeEvaluator.range != some axRange then
      continue
    authorized := authorized.push ax.name
  authorized

/-- Authenticate only Lean's exact range-less helper for a safe recursive base. -/
def authorizedUnsafeRecHelpers (decls : Array Declaration)
    (transcripts : Array Transcript := #[]) : Array String := Id.run do
  let mut authorized : Array String := #[]
  for helper in decls do
    let some baseName := helper.unsafeRecBase | continue
    let some base := findDecl? decls baseName | continue
    if base.kind != "def" || helper.kind != "def"
        || helper.«module» != base.«module» || !helper.internal
        || helper.ranges.isSome || !helper.isPartial || helper.isUnsafe
        || helper.hints != some "opaque" || helper.implementedBy.isSome
        || helper.«extern» then continue
    if !#["structural", "well-founded"].contains (helper.unsafeRecValueOrigin.getD "")
        || helper.unsafeRecValueExact != some true
        || helper.unsafeRecValueDefeq != some true
        || helper.unsafeRecEquationExact != some true
        || helper.unsafeRecEquationDefeq != some true then continue
    let some equationAxioms := helper.unsafeRecEquationAxioms | continue
    if !equationAxioms.all (fun name =>
        standardLogicalAxiom name || base.axioms.contains name) then continue
    if base.isPartial || base.isUnsafe || base.hints != some "regular"
        || !base.recursive || base.implementedBy.isSome || base.«extern»
        || helper.«type» != base.«type» || helper.levelParams != base.levelParams
        || !arraySubset helper.axioms base.axioms || base.all.isEmpty then continue
    let expectedHelpers := base.all.map (· ++ "._unsafe_rec")
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

private def compilerAxiom (native : Array String) (name : String) : Bool :=
  builtinCompilerAxiom name || native.contains name

def labelOf (axioms : Array String) (native : Array String := #[]) : String :=
  if axioms.contains "sorryAx" then "hole"
  else if axioms.any fun name => !standardLogicalAxiom name && !compilerAxiom native name then
    "unknown-axiom"
  else if axioms.any (compilerAxiom native) then "compiler-trusting"
  else if axioms.isEmpty then "kernel-only"
  else if axioms.all Profile.choiceFree.permits then "choice-free"
  else "standard-logical"

def reasonFor (decl : Declaration) (claim : Option Profile)
    (native : Array String := #[]) (unsafeHelpers : Array String := #[]) :
    Option String :=
  if decl.kind == "axiom" then
    if native.contains decl.name then
      if claim == some .compilerTrusting then none else some "compiler-trusting"
    else some "project-axiom"
  else if decl.axioms.contains "sorryAx" then some "hole"
  else if decl.axioms.any fun name =>
      !standardLogicalAxiom name && !compilerAxiom native name then some "unknown-axiom"
  else if (decl.isUnsafe || decl.isPartial) && !unsafeHelpers.contains decl.name then
    some "escape-hatch"
  else if decl.axioms.any (compilerAxiom native) && claim != some .compilerTrusting then
    some "compiler-trusting"
  else if decl.executableContract.any (·.failure.isSome) then some "executable-contract"
  else match claim with
    | some profile =>
        if decl.axioms.all fun name => compilerAxiom native name || profile.permits name
        then none else some "label-exceeds-claim"
    | none => none

/-- Boundary kinds that a checked-correspondence execution claim does not
require to be checked: the Lean toolchain's own native runtime primitives are
the documented execution substrate and are always reported as trusted. -/
private def nativeRuntimeBoundary (boundary : String) : Bool :=
  boundary == "native-runtime"

/-- Execution-claim failures over the typed coverage account. Unresolved
paths and unclassified boundaries block in every mode; a trusted boundary
blocks a checked-correspondence claim unless it is a toolchain native-runtime
primitive. -/
def executionFailures (roots : Array StrictLean.Report.ExecutionRoot)
    (claim : ExecutionClaim) : Array String := Id.run do
  let mut failures : Array String := #[]
  for root in roots do
    for item in root.unresolved do
      failures := failures.push s!"execution-unresolved: {root.name}: {item}"
    for boundary in root.boundaries do
      if boundary.correspondence == "unresolved" then
        failures := failures.push (s!"execution-unresolved: {root.name} reaches " ++
          s!"{boundary.name} ({boundary.boundary}): {boundary.evidence.getD "unclassified"}")
      else if claim == .checked && boundary.correspondence != "checked"
          && !nativeRuntimeBoundary boundary.boundary then
        failures := failures.push (s!"execution-trusted-boundary: {root.name} reaches " ++
          s!"{boundary.name} ({boundary.boundary})")
  failures

/-- One-line rendering of a single execution boundary. -/
def describeBoundary (boundary : StrictLean.Report.ExecutionBoundary) : String :=
  let replacement := boundary.replacement.map (fun value => s!" replacement={value}") |>.getD ""
  let evidence := boundary.evidence.map (fun value => s!" evidence={value}") |>.getD ""
  let owned := if boundary.owned then " owned" else ""
  let callers := if boundary.compilerCallers.isEmpty then "" else
    s!" compiler-callers={boundary.compilerCallers}"
  s!"boundary {boundary.name} [{boundary.boundary}] " ++
    s!"correspondence={boundary.correspondence}{replacement}{evidence}{owned}{callers} " ++
    s!"(module {boundary.«module»})"

/-- Execution-coverage summary counts for gate output: roots, boundaries,
checked, trusted, unresolved. -/
def executionSummary (roots : Array StrictLean.Report.ExecutionRoot) :
    Nat × Nat × Nat × Nat × Nat := Id.run do
  let mut boundaries := 0
  let mut checked := 0
  let mut trusted := 0
  let mut unresolved := 0
  for root in roots do
    unresolved := unresolved + root.unresolved.size
    for boundary in root.boundaries do
      boundaries := boundaries + 1
      if boundary.correspondence == "checked" then checked := checked + 1
      else if boundary.correspondence == "trusted" then trusted := trusted + 1
      else unresolved := unresolved + 1
  return (roots.size, boundaries, checked, trusted, unresolved)

def classify (decl : Declaration) (native : Array String := #[]) : String :=
  let flags := Id.run do
    let mut values : Array String := #[]
    if decl.kind == "axiom" then values := values.push "AXIOM"
    if decl.isProp then values := values.push "Prop"
    if decl.«instance» then values := values.push "instance"
    if decl.«noncomputable» then values := values.push "noncomputable"
    if decl.isUnsafe then values := values.push "unsafe"
    if decl.isPartial then values := values.push "partial"
    if let some implementation := decl.implementedBy then
      values := values.push s!"implemented_by={implementation}"
    if decl.«extern» then values := values.push "extern"
    values
  let roles := Id.run do
    let mut values : Array String := #[]
    if decl.internal then values := values.push "internal"
    if decl.«private» then values := values.push "private"
    if decl.projection then values := values.push "projection"
    if decl.matcher then values := values.push "matcher"
    if let some base := decl.unsafeRecBase then values := values.push s!"unsafe-rec-for={base}"
    values
  let flagText := if flags.isEmpty then "" else s!" [{", ".intercalate flags.toList}]"
  let roleText := if roles.isEmpty then "" else s!" roles={repr roles.toList}"
  let contractText := decl.executableContract.map (fun contract =>
    s!" executable-contract={contract.root} requires={contract.requirement}" ++
      (contract.failure.map (s!" failure={·}")).getD "") |>.getD ""
  s!"{decl.name} ({decl.kind}){flagText}{roleText} type={decl.prettyType} " ++
    s!"axioms={repr decl.axioms.toList} -> {labelOf decl.axioms native}{contractText}"

end StrictLean.Checker.Policy
