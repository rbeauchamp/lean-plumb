import StrictLean.StructuralName
import Lean.Elab.Command
import Lean.Compiler.Old
import Lean.Compiler.NoncomputableAttr
import Lean.Compiler.ImplementedByAttr
import Lean.Compiler.ExternAttr
import Lean.Compiler.CSimpAttr
import Lean.Compiler.IR.EmitUtil
import Lean.DeclarationRange
import Lean.Elab.PreDefinition.Structural.Eqns
import Lean.Elab.PreDefinition.WF.Eqns
import Lean.Meta.Match.MatcherInfo
import Lean.Meta.Native
import Lean.Meta.Eqns
import Lean.Meta.RecExt
import Lean.ProjFns
import Lean.Util.FoldConsts
import StrictLean.Report
import StrictLean.Contract

/-!
Machine-audit support consumed directly by the repository's Lean checker
executables.

The trusted runner calls `environmentReport` on a Lean-imported elaborated
environment — never on source text. The `audit_dump_json` command remains only
as an interactive compatibility entrypoint. For every declaration whose exact
module index is requested, the report records:

- the declaration's module and constant kind (axiom, theorem, def, opaque,
  constructor, inductive, recursor, quotient);
- the exact elaborated type, whether that type is a proposition, and
  `ConstantInfo.isUnsafe` / `ConstantInfo.isPartial` for every constant kind;
- instance / `noncomputable` / `@[implemented_by]` / `@[extern]` flags;
- the exact transitive axiom set (`Lean.collectAxioms`), which is what
  `#print axioms` reports; and
- Lean-native reporting metadata (internal/private spelling, projection,
  matcher, recursor kind, unsafe-recursion relationship, and source range).

The report additionally carries an execution-coverage account, distinct from
the logical axiom audit: for every owned executable root (computable,
non-proposition, safe, non-partial, non-internal definitions and opaque
constants, including claimed executable `main`s) it computes the transitive
conservative closure over value-level dependencies, retained compiler IR,
constant-equality simplification candidates, historical `@[implemented_by]`
targets, and partial helpers. `@[extern]` constants are boundary leaves for
their Lean bodies. The report distinguishes possible replacements from actual
retained compiler edges and records every boundary in this closure:
compiler simplifications, `@[implemented_by]` replacements, `@[extern]` declarations split into
toolchain native-runtime primitives (origin-checked `Init` modules) and other external code,
unsafe/partial/opaque computation, and compiler-trusting proof axioms. Each
boundary is marked `checked` (kernel-definitional equality, a standard-logical
correspondence theorem, or a kernel-checked opaque body), `trusted`, or
`unresolved`; unresolved paths are listed per root. Imported boundary
declarations are reported by this account without becoming owned.

Generated-role metadata is descriptive, not provenance. The checker policy
combines these semantic fields with a fresh exact-source frontend transcript
before it recognizes Lean's range-less internal code-generation helper for a
safe recursive base or a native-proof axiom. Names, ranges, and extension tags
alone never waive a rule. Every declaration is still emitted and checked.

The full list of imported module names and each module's Lean-resolved `.olean`
path are emitted as well, so drivers can reconcile the queried Lake inventory,
identify root-package ownership through Lake's actual output directory, and
detect fixture contamination. The trusted checker runner invokes the reporter
directly without parsing observer syntax in the audited module's frontend
extension environment.

This module is checker infrastructure shipped inside the `StrictLean`
library so that any adopting project can probe its own modules; it is not part
of this repository's audited positive surface.
-/

namespace StrictLean.Probe

open Lean Elab Command
open StrictLeanPolicy (DeclarationKind BoundaryKind Correspondence Safety Reducibility RecursionOrigin)

/-- Constant kind of a declaration, as reported by the environment. Public so
the checker self-test can apply `Policy.declarationNeedsTranscript` to raw
module constant records with the identical kind mapping. -/
def kindOf : ConstantInfo → DeclarationKind
  | .axiomInfo _   => .«axiom»
  | .defnInfo _    => .«definition»
  | .thmInfo _     => .«theorem»
  | .opaqueInfo _  => .«opaque»
  | .ctorInfo _    => .«constructor»
  | .inductInfo _  => .«inductive»
  | .recInfo _     => .«recursor»
  | .quotInfo _    => .«quotient»

/-- Compact source position used in declaration-range evidence. -/
private def positionReport (p : Lean.Position) : StrictLean.Report.Position :=
  { line := p.line, column := p.column }

/-- Typed encoding of one exact Lean declaration range. -/
private def rangeReport (r : DeclarationRange) : StrictLean.Report.Range :=
  { start := positionReport r.pos
    «end» := positionReport r.endPos
    startUtf16 := r.charUtf16
    endUtf16 := r.endCharUtf16 }

/-- Typed encoding of full and selection declaration ranges. -/
private def rangesReport (r : DeclarationRanges) : StrictLean.Report.Ranges :=
  { range := rangeReport r.range
    selectionRange := rangeReport r.selectionRange }

private def hintsString : ReducibilityHints → Reducibility
  | .opaque    => .«opaque»
  | .abbrev    => .«abbrev»
  | .regular _ => .«regular»

/-- Kernel value of a definition/theorem/opaque declaration when present. -/
private def valueOf? : ConstantInfo → Option Expr
  | .defnInfo value   => some value.value
  | .thmInfo value    => some value.value
  | .opaqueInfo value => some value.value
  | _                 => none

/-- Retrieve the original built-in recursion predefinition for a safe base. -/
private def recursionPredefinition? (env : Environment) (baseName : Name) :
    Option (RecursionOrigin × List Name × Expr × Array Name) :=
    match Lean.Elab.Structural.eqnInfoExt.find? env baseName with
    | some info => some (.structural, info.levelParams, info.value, info.declNames)
    | none => match Lean.Elab.WF.eqnInfoExt.find? env baseName with
      | some info => some (.wellFounded, info.levelParams, info.value, info.declNames)
      | none => none

/-- Reconstruct the exact executable body transformation used by Lean 4.33.1's
`addAndCompilePartialRec` from the built-in recursion equation metadata. -/
private def unsafeRecExpected? (env : Environment) (baseName : Name) :
    Option (RecursionOrigin × Expr) := do
  let (origin, _, value, group) ← recursionPredefinition? env baseName
  let expected := value.replace fun expr => match expr with
    | .const name levels =>
        if group.contains name then
          some <| mkConst (Lean.Compiler.mkUnsafeRecName name) levels
        else none
    | _ => none
  return (origin, expected)

/-- Independently require a kernel-checked unfolding theorem with exactly the
one-step equation reconstructed from the same built-in predefinition. -/
private def unsafeRecEquationEvidence (env : Environment) (name : Name) :
    CommandElabM (Option (Bool × Bool × Array Name)) := do
  let some baseName := Lean.Compiler.isUnsafeRecName? name | return none
  let some (_, levelParams, value, _) := recursionPredefinition? env baseName
    | return none
  liftTermElabM <| withoutModifyingEnv do
    try
      let some equationName ← Meta.getUnfoldEqnFor? baseName
        | return some (false, false, #[])
      let some equationInfo := (← getEnv).find? equationName
        | return some (false, false, #[])
      let expectedType ← Meta.lambdaTelescope value fun args body => do
        let lhs := mkAppN (mkConst baseName (levelParams.map mkLevelParam)) args
        let equality ← Meta.mkEq lhs body
        Meta.letToHave (← Meta.mkForallFVars args equality)
      let definitional ← Meta.isDefEq equationInfo.type expectedType
      let axioms ← collectAxioms equationName
      return some (equationInfo.type == expectedType, definitional, axioms)
    catch _ =>
      return some (false, false, #[])

/-- Whether a helper's entire value is the pinned compiler transformation of
the built-in structural/well-founded predefinition stored for its safe base. -/
private def unsafeRecValueEvidence (env : Environment) (name : Name)
    (info : ConstantInfo) : CommandElabM (Option (RecursionOrigin × Bool × Bool)) := do
  let some baseName := Lean.Compiler.isUnsafeRecName? name | return none
  let some (origin, expected) := unsafeRecExpected? env baseName | return none
  let .defnInfo helper := info | return none
  let definitional ← liftTermElabM <| Meta.isDefEq helper.value expected
  return some (origin, helper.value == expected, definitional)

/-- Exact Boolean expression asserted by a native-proof-shaped axiom. -/
private def nativeBoolExpr? (type : Expr) : Option Expr := do
  let args := type.getAppArgs
  guard <| type.getAppFn.isConstOf ``Eq
  guard <| args.size == 3
  guard <| args[0]!.isConstOf ``Bool
  guard <| args[2]!.isConstOf ``Bool.true
  let decideExpr := args[1]!
  guard <| decideExpr.getAppFn.isConstOf ``Decidable.decide
  guard <| decideExpr.getAppArgs.size == 2
  return decideExpr

/-- Whether a declaration's entire proof is the exact native-decision bridge
for `axiomName` and the same `decide` expression. -/
private def isExactNativeUse (axiomName : Name) (decideExpr : Expr)
    (info : ConstantInfo) : Bool :=
  match valueOf? info with
  | none => false
  | some value =>
      let args := value.getAppArgs
      value.getAppFn.isConstOf ``of_decide_eq_true
        && args.size == 3
        && args[0]! == info.type
        && args[2]!.isConst
        && args[2]!.constName! == axiomName
        && mkApp2 (mkConst ``Decidable.decide) args[0]! args[1]! == decideExpr

/-- Independently replay the Boolean native evaluation without retaining any
declaration it creates. This remains compiler evidence, never a kernel proof. -/
private def replayNative? (type : Expr) : CommandElabM (Option Bool) := do
  let some decideExpr := nativeBoolExpr? type | return none
  try
    let result ← liftTermElabM <| withoutModifyingEnv do
      Meta.nativeEqTrue `audit_native_replay decideExpr
    return some <| match result with
      | .success _ => true
      | .notTrue   => false
  catch _ =>
    return some false

/-- Classify the terminal result after Lean reduction, including aliases of
function types and universes. Runtime roots cannot return erased types. -/
private def returnsSort (type : Expr) : MetaM Bool :=
  Meta.withTransparency .all <|
    Meta.forallTelescopeReducing type (fun _ body => pure body.isSort) (whnfType := true)

/-- Recognize a closed proof-bearing requirement by its elaborated type. No
annotation, theorem-name inventory, or proposition matcher supplies evidence:
the `ExecutableContract` constructor requires the exact proposition in Lean.
The promised implementation must be a constant, not a partial application or
an existential proof. Its execution closure is inspected even if it is private.
-/
private def executableContract? (env : Environment) (info : ConstantInfo) :
    CommandElabM (Option StrictLean.Report.ExecutableContract) := do
  if !#[DeclarationKind.definition, .theorem, .opaque].contains (kindOf info) then return none
  liftTermElabM <| Meta.withTransparency .all <|
    Meta.forallTelescopeReducing info.type (whnfType := true) fun parameters type => do
    if !type.isAppOfArity ``StrictLean.ExecutableContract 3 then return none
    let args := type.getAppArgs
    let implementation := args[1]!
    let requirement ← Meta.ppExpr (mkApp args[2]! implementation)
    let root := implementation.constName?
    let failure ← if !parameters.isEmpty then
        pure <| some "registration must be closed; put the implementation's complete domain inside its predicate"
      else match root with
      | none => pure <| some "implementation must be a named constant with its complete domain"
      | some name => do
        let some target := env.find? name
          | pure (some "implementation is missing from the environment")
        if Lean.isNoncomputable env name then
          pure <| some "promised implementation is noncomputable"
        else if target.isUnsafe || target.isPartial then
          pure <| some "promised implementation is unsafe or partial"
        else if !(← Meta.isProp target.type) && (kindOf target == .definition || kindOf target == .opaque) then
          let typeProducing ← returnsSort target.type
          pure <| if typeProducing then some "promised implementation returns a type, not runtime data" else none
        else pure <| some "promised implementation is not an executable data/function definition"
    return some {
      root := root.getD .anonymous
      requirement := toString requirement
      failure }

/-- One typed record per audited declaration. -/
private def declEntry (env : Environment) (name : Name) (info : ConstantInfo) :
    CommandElabM StrictLean.Report.Declaration := do
  let axioms ← collectAxioms name
  let isProp ← liftTermElabM <| Meta.isProp info.type
  let prettyType ← liftTermElabM do
    return toString (← Meta.ppExpr info.type)
  let ranges? ← findDeclarationRangesCore? name
  let recursive ← liftTermElabM <| Meta.isRecursiveDefinition name
  let unsafeRecValueEvidence? ← unsafeRecValueEvidence env name info
  let unsafeRecEquationEvidence? ← unsafeRecEquationEvidence env name
  let nativeReplay? ← replayNative? info.type
  let nativeUseParents : Array Name :=
    match nativeBoolExpr? info.type with
    | none => #[]
    | some decideExpr => env.constants.fold (init := #[]) fun parents parentName parentInfo =>
        if isExactNativeUse name decideExpr parentInfo then
          parents.push parentName
        else parents
  let levelParams : List Name := info.levelParams
  let all : List Name :=
    match info with
    | .defnInfo value   => value.all
    | .thmInfo value    => value.all
    | .opaqueInfo value => value.all
    | _                 => []
  let hints : Option Reducibility :=
    match info with
    | .defnInfo value => some (hintsString value.hints)
    | _               => none
  let valueConstants : Array Name :=
    match valueOf? info with
    | some value => value.getUsedConstants
    | none       => #[]
  let some moduleIdx := env.getModuleIdxFor? name
    | throwError "owned declaration {name} has no module index"
  return {
    name := name
    «module» := env.header.modules[(moduleIdx : Nat)]!.module
    kind := kindOf info
    «type» := toString (repr info.type)
    prettyType
    isProp
    isUnsafe := info.isUnsafe
    isPartial := info.isPartial
    safety := if info.isPartial then some .partial
      else if info.isUnsafe then some .unsafe else none
    «instance» := Lean.Meta.isInstanceCore env name
    «noncomputable» := Lean.isNoncomputable env name
    implementedBy := (Lean.Compiler.getImplementedBy? env name)
    «extern» := Lean.isExtern env name
    internal := name.isInternal
    «private» := Lean.isPrivateName name
    projection := env.isProjectionFn name
    matcher := Lean.Meta.isMatcherCore env name
    recursive
    unsafeRecBase := (Lean.Compiler.isUnsafeRecName? name)
    levelParams := levelParams.toArray
    all := all.toArray
    hints
    valueConstants := StrictLeanPolicy.canonicalNames valueConstants
    unsafeRecValueOrigin := unsafeRecValueEvidence?.map fun (origin, _, _) => origin
    unsafeRecValueExact := unsafeRecValueEvidence?.map fun (_, exact, _) => exact
    unsafeRecValueDefeq := unsafeRecValueEvidence?.map fun (_, _, value) => value
    unsafeRecEquationExact := unsafeRecEquationEvidence?.map fun (exact, _, _) => exact
    unsafeRecEquationDefeq := unsafeRecEquationEvidence?.map fun (_, value, _) => value
    unsafeRecEquationAxioms := unsafeRecEquationEvidence?.map fun (_, _, values) =>
      StrictLeanPolicy.canonicalNames values
    nativeBoolShape := (nativeBoolExpr? info.type).isSome
    nativeReplay := nativeReplay?
    nativeUseParents
    ranges := ranges?.map rangesReport
    axioms := StrictLeanPolicy.canonicalNames axioms
    executableContract := ← executableContract? env info
  }

/-- Select the intersection of current kernel constants and Lean's exact
import ownership map. For the imported environments used by admission and
reporting, the base and checked kernel share this map. Enumerating ownership
first avoids an ownership hash
lookup for every dependency constant; IR-only names without constants are
ignored, and the current kernel entry retains subsumption semantics. -/
def ownedConstants (env : Environment) (modules : List Name) :
    Array (Name × ConstantInfo) := Id.run do
  let kernel := env.toKernelEnv
  let selected := env.header.modules.map fun imported => modules.contains imported.module
  let mut own := #[]
  for (name, idx) in kernel.const2ModIdx do
    if selected[(idx : Nat)]! then
      if let some info := kernel.find? name then
        own := own.push (name, info)
  return own

/-- Declarations attributed by Lean to one of the exact requested modules. -/
private def ownedDecls (env : Environment) (modules : List Name) :
    CommandElabM (Array (Name × ConstantInfo)) :=
  pure (ownedConstants env modules)

/-- Admission checks the constructed closed proof against the exact required
proposition in a disposable kernel declaration. Neither metavariable unification
nor a matching theorem statement alone authorizes `checked`. -/
private def checkCorrespondenceProof (levels : List Name) (required proof : Expr) :
    MetaM String := do
  let required ← instantiateMVars required
  let proof ← instantiateMVars proof
  if required.hasMVar || proof.hasMVar || required.hasFVar || proof.hasFVar then
    throwError "correspondence has undischarged variables"
  let name ← mkFreshUserName `audit_correspondence
  let declaration := Declaration.thmDecl {
    name := name
    levelParams := levels
    type := required
    value := proof }
  let checked ← match (← getEnv).addDeclCore 200000 1000 declaration none with
    | .ok checked => pure checked
    | .error _ => throwError "kernel rejected exact correspondence"
  let axioms ← withEnv checked <| collectAxioms name
  unless axioms.all (fun ax =>
      ax == ``propext || ax == ``Quot.sound || ax == ``Classical.choice) do
    throwError "correspondence exceeds standard-logical foundations"
  withOptions (fun opts => opts.setBool `pp.all true |>.setBool `pp.deepTerms true
      |>.set `pp.maxSteps (1000000 : Nat)) do
    return s!"proof={← Meta.ppExpr proof}; required={← Meta.ppExpr required}"

/-- A theorem mentioning both endpoints is only a search candidate. For every
prefix of the actual dependent domain, instantiate its universes and premises,
match the equality, apply any remaining arguments by congruence, and close over
exactly the actual domain. Unsolved theorem-only premises remain metavariables
and cannot pass kernel admission. Search incompleteness never grants evidence. -/
private def theoremCorrespondence? (levels : List Name) (reference replacement : Expr)
    (domain : Array Expr) (required : Expr) (name : Name) : MetaM (Option String) := do
  for count in List.range (domain.size + 1) do
    for reverse in [false, true] do
      let result ← Meta.withoutModifyingMCtx do
        try
          let candidate ← Meta.mkConstWithFreshMVarLevels name
          let (args, _, conclusion) ← Meta.forallMetaTelescope (← Meta.inferType candidate)
          let lhs := mkAppN reference (domain.extract 0 count)
          let rhs := mkAppN replacement (domain.extract 0 count)
          let target ← if reverse then Meta.mkEq rhs lhs else Meta.mkEq lhs rhs
          unless ← Meta.isDefEq conclusion target do return none
          let mut proof ← instantiateMVars (mkAppN candidate args)
          if reverse then proof ← Meta.mkEqSymm proof
          for arg in domain.extract count domain.size do
            proof ← Meta.mkCongrFun proof arg
          proof ← Meta.mkLambdaFVars domain proof
          let detail ← checkCorrespondenceProof levels required proof
          return some s!"proved: {name}; {detail}"
        catch _ => return none
      if result.isSome then return result
  return none

/-- Require `∀ xs, reference.{us} xs = replacement.{us} xs`, where `us`
are rigid universal level parameters and `xs` is the complete elaborated
reference domain, including implicit, dependent, and proof parameters. The
compiler's positional universe substitution must type-check at those same
levels. Both definitional and theorem-backed evidence pass the same kernel gate. -/
private def replacementCorrespondence (env : Environment) (reference replacement : Name)
    (proofCandidates : Array Name := #[]) :
    CommandElabM (Correspondence × Option String) := do
  try
    liftTermElabM <| Meta.withoutModifyingMCtx do
      let referenceInfo ← getConstInfo reference
      let replacementInfo ← getConstInfo replacement
      let levels := referenceInfo.levelParams
      unless replacementInfo.levelParams.length == levels.length do
        throwError "unsupported replacement universes"
      let us := levels.map mkLevelParam
      let ref := mkConst reference us
      let impl := mkConst replacement us
      unless ← Meta.isDefEq (← Meta.inferType ref) (← Meta.inferType impl) do
        throwError "replacement types differ"
      Meta.forallTelescopeReducing (← Meta.inferType ref) fun domain _ => do
        let lhs := mkAppN ref domain
        let rhs := mkAppN impl domain
        let required ← Meta.mkForallFVars domain (← Meta.mkEq lhs rhs)
        try
          let proof ← Meta.mkLambdaFVars domain (← Meta.mkEqRefl lhs)
          let detail ← checkCorrespondenceProof levels required proof
          return (.checked, some s!"kernel-defeq; {detail}")
        catch _ => pure ()
        for name in proofCandidates do
          if let some evidence ← theoremCorrespondence? levels ref impl domain required name then
            return (.checked, some evidence)
        for (name, info) in env.constants.toList do
          let .thmInfo _ := info | continue
          let used := info.type.getUsedConstants
          if !used.contains reference || !used.contains replacement then continue
          if let some evidence ← theoremCorrespondence? levels ref impl domain required name then
            return (.checked, some evidence)
        return (.trusted, some "no kernel-checked unconditional correspondence proof")
  catch _ =>
    return (.unresolved, some s!"cannot construct exact correspondence for {reference} and {replacement}")

private def compilerTrustingAxiom (name : Name) : Bool :=
  name == ``Lean.trustCompiler || name == ``Lean.ofReduceBool
    || name == ``Lean.ofReduceNat
    || (name.toString.splitOn "._native.native_decide.ax").length == 2

/-- The pinned `CSimp.isConstantReplacement?` shape, indexed independently of
the final scoped attribute state. This conservative candidate set includes
proof-valued definitions, expired local registrations, and overwritten entries.
An equality candidate is not evidence that a compiler selected that edge. -/
private def simplificationCandidates (env : Environment) :
    NameMap (Array Lean.Compiler.CSimp.Entry) :=
  env.constants.fold (init := {}) fun candidates theoremName info => Id.run do
    let some (_, .const reference us, .const target vs) := info.type.eq?
      | return candidates
    if reference == target then return candidates
    let levels := Std.HashSet.ofList us
    if levels.size != us.length || !levels.all Level.isParam || us != vs then
      return candidates
    let entry : Lean.Compiler.CSimp.Entry := ⟨reference, target, theoremName⟩
    return candidates.insert reference ((candidates.find? reference).getD #[] |>.push entry)

/-- Remove sinks from the finite replacement-only graph. The remaining names
are precisely those that can reach a directed cycle. Ordinary body recursion
is not a replacement-only cycle and does not enter this graph. -/
private def cyclicReplacementPaths (edges : Array (Name × Name)) : Array Name := Id.run do
  let mut remaining := edges.foldl (fun names (source, target) =>
    let names := if names.contains source then names else names.push source
    if names.contains target then names else names.push target) #[]
  for _ in [:remaining.size] do
    remaining := remaining.filter fun source =>
      edges.any fun (left, right) => left == source && remaining.contains right
  return remaining

/-- Identify the uncompiled helper produced for an actual kernel inductive by
Lean's pinned `mkBRecOnFromRec`. Names come from the inductive/recursor records,
then must agree with the tagged parent's actual projection and helper body.
This does not waive execution coverage: the helper remains a root, and all
source, attribute, historical replacement and retained IR edges are inspected. -/
private def brecOnHelpers (env : Environment) (own : Array (Name × ConstantInfo)) :
    Array Name := Id.run do
  let mut helpers := #[]
  for (indName, info) in own do
    let .inductInfo ind := info | continue
    if !ind.isRec then continue
    let base := (Lean.mkRecName indName, Lean.mkBRecOnName indName)
    let nested := if ind.all.head? == some indName then
      (List.range ind.numNested).toArray.map fun i =>
        (base.1.appendIndexAfter (i + 1), base.2.appendIndexAfter (i + 1))
      else #[]
    for (recName, parent) in #[base] ++ nested do
      let some (.recInfo _) := env.find? recName | continue
      if !Lean.isBRecOnRecursor env parent then continue
      let some (.defnInfo parentInfo) := env.find? parent | continue
      let .proj ``PProd 0 argument := parentInfo.value.getLambdaBody.consumeMData | continue
      let some helper := argument.getAppFn.constName? | continue
      if helper != parent.str "go" then continue
      let some (.defnInfo helperInfo) := env.find? helper | continue
      if helperInfo.hints != .abbrev then continue
      if env.getModuleIdxFor? helper != env.getModuleIdxFor? indName then continue
      if env.getModuleIdxFor? parent != env.getModuleIdxFor? indName then continue
      if !helperInfo.value.getUsedConstants.contains recName then continue
      helpers := helpers.push helper
  return helpers

/-- Finite conservative execution closure: source values, retained compiler IR,
all supported equality candidates, and observed implementation choices.
Compiler metadata supplements source dependencies; neither alone retains all
earlier replacements after inlining. Equality candidates are not a claim that
the compiler selected them. Extern reference bodies remain boundary leaves. -/
private def executionWalk (env : Environment) (ownedModules : List Name)
    (nativeModules : NameMap StrictLeanPolicy.NativeOrigin)
    (loadReplacementHistory : Name → IO (Except String (Array (Name × Name))))
    (candidates : NameMap (Array Lean.Compiler.CSimp.Entry))
    (proofCache : IO.Ref (Std.HashMap (Name × Name) (Correspondence × Option String)))
    (recursorHelpers : Array Name) (root : Name) : CommandElabM (Array StrictLean.Report.ExecutionBoundary ×
      Array String × Array (Name × Name)) := do
  let mut visited : Std.HashSet Name := {}
  let mut queue : Array Name := #[root]
  let mut boundaries : Array StrictLean.Report.ExecutionBoundary := #[]
  let mut unresolved : Array String := #[]
  let mut replacementEdges : Array (Name × Name) := #[]
  let mut compilerEdges : Array (Name × Name) := #[]
  let mut compiledNames : Std.HashSet Name := {}
  -- Meta.mkProjections installs projection bodies without compiling standalone
  -- IR; ToLCNF handles their uses directly. The identified brecOn helper also
  -- has no standalone IR on this pin. Both retain full source/boundary coverage;
  -- retained compiler edges still require actual IR.
  if (Lean.Compiler.getImplementedBy? env root).isNone &&
      !Lean.Compiler.hasMacroInlineAttribute env root && !env.isProjectionFn root &&
      !(recursorHelpers.contains root && (Lean.IR.findEnvDecl env root).isNone) then
    compiledNames := compiledNames.insert root
  let moduleOf (name : Name) : Option Name :=
    (env.getModuleIdxFor? name).map fun idx => env.header.modules[(idx : Nat)]!.module
  let correspondence (reference target : Name) := do
    if let some result := (← liftIO proofCache.get)[(reference, target)]? then return result
    let proofs := ((candidates.find? reference).getD #[]).filterMap fun candidate =>
      if candidate.toDeclName == target then some candidate.thmName else none
    let result ← replacementCorrespondence env reference target proofs
    liftIO <| proofCache.modify (·.insert (reference, target) result)
    return result
  while !queue.isEmpty do
    let name := queue.back!
    queue := queue.pop
    if visited.contains name then continue
    visited := visited.insert name
    -- Persisted compiler IR records replacements at the time each imported
    -- declaration was compiled, including scoped simplification and inlining.
    -- Keep source edges too: optimization may erase an unsafe/replacement step.
    if let some compiled := Lean.IR.findEnvDecl env name then
      let dependencies := (Lean.IR.collectUsedDecls env [compiled]).filter (· != name)
      for dependency in dependencies do
        compilerEdges := compilerEdges.push (name, dependency)
        compiledNames := compiledNames.insert dependency
      queue := queue ++ dependencies
    let some info := env.find? name
    | if (Lean.IR.findEnvDecl env name).isNone then
        unresolved := unresolved.push s!"{name}: constant used by {root} is not in the environment"
      continue
    let some moduleName := moduleOf name
    | unresolved := unresolved.push s!"{name}: module attribution is unavailable"
      continue
    let owned := ownedModules.contains moduleName
    let entry (boundary : BoundaryKind) (correspondence : Correspondence) (replacement : Option Name) (evidence : Option String) :
        CommandElabM StrictLean.Report.ExecutionBoundary := do
      let account ← match StrictLeanPolicy.admitBoundaryEvidence boundary correspondence evidence
          (if boundary == .nativeRuntime && correspondence == .trusted then nativeModules.find? moduleName else none) with
        | .ok account => pure account
        | .error error => throwError "{error}"
      return {
        occurrence := boundaries.size
        name := name
        «module» := moduleName
        boundary := boundary
        account := account
        owned := owned
        replacement := replacement }
    if let some active := (Lean.Compiler.CSimp.ext.getState env).map.find? name then
      replacementEdges := replacementEdges.push (name, active.toDeclName)
    for simplification in (candidates.find? name).getD #[] do
      let target := simplification.toDeclName
      let (correspondence, evidence) ← correspondence name target
      boundaries := boundaries.push <|
        (← entry .compilerSimplification correspondence (some target)
          (some s!"conservative constant-equality candidate={simplification.thmName}; {evidence.getD ""}"))
      queue := queue.push target
    if Lean.isExtern env name then
      let native := nativeModules.contains moduleName
      boundaries := boundaries.push <|
        (← entry (if native then .nativeRuntime else .external) .trusted none none)
      continue
    if let some target := Lean.Compiler.getImplementedBy? env name then
      let history ← liftIO <| loadReplacementHistory moduleName
      let targets ← match history with
        | .error error =>
            unresolved := unresolved.push s!"{name}: replacement history unavailable: {error}"
            pure #[target]
        | .ok edges =>
            let targets := edges.filterMap fun (reference, target) =>
              if reference == name then some target else none
            if !targets.contains target then
              unresolved := unresolved.push s!"{name}: fresh replacement history omits current target {target}"
            pure <| if targets.contains target then targets else targets.push target
      for target in targets do
        replacementEdges := replacementEdges.push (name, target)
        let (correspondence, evidence) ← correspondence name target
        boundaries := boundaries.push <|
          (← entry .runtimeReplacement correspondence (some target) evidence)
        queue := queue.push target
      continue
    if info.isPartial then
      boundaries := boundaries.push <| (← entry .partialComputation .trusted none none)
      if let some value := info.value? then queue := queue ++ value.getUsedConstants
      continue
    if info.isUnsafe then
      boundaries := boundaries.push <| (← entry .unsafeComputation .trusted none none)
      if let some value := info.value? then queue := queue ++ value.getUsedConstants
      continue
    match info with
    | .defnInfo _ =>
        if !(← liftTermElabM <| Meta.isProp info.type) then
          if let some value := info.value? then queue := queue ++ value.getUsedConstants
    | .opaqueInfo _ =>
        let recName := Lean.Compiler.mkUnsafeRecName name
        match env.find? recName with
        | some recInfo =>
            if recInfo.isPartial then
              boundaries := boundaries.push <|
                (← entry .partialComputation .trusted none (some recName.toString))
              queue := queue.push recName
            else
              boundaries := boundaries.push <| (← entry .opaqueComputation .unresolved none
                (some s!"compiled helper {recName} is not partial"))
        | none =>
            boundaries := boundaries.push <|
              (← entry .opaqueComputation .checked none (some "kernel-checked-body"))
            if !(← liftTermElabM <| Meta.isProp info.type) then
              if let some value := info.value? (allowOpaque := true) then
                queue := queue ++ value.getUsedConstants
    | .axiomInfo _ =>
        if compilerTrustingAxiom name then
          boundaries := boundaries.push <| (← entry .compilerTrustedProof .trusted none none)
    | .thmInfo _ | .ctorInfo _ | .inductInfo _ | .recInfo _ | .quotInfo _ => pure ()
  let cycles := cyclicReplacementPaths replacementEdges
  if !cycles.isEmpty then
    unresolved := unresolved.push s!"replacement-only cycle reachable from {cycles}"
  for name in compiledNames do
    match Lean.IR.findEnvDecl env name with
    | some (.fdecl ..) => pure ()
    | some (.extern ..) =>
        if !Lean.isExtern env name then
          unresolved := unresolved.push s!"{name}: compiler body is an opaque export placeholder"
    | none =>
        unresolved := unresolved.push s!"{name}: compiled dependency body is unavailable"
  boundaries := boundaries.mapIdx fun occurrence boundary =>
    { boundary with occurrence, compilerCallers := compilerEdges.filterMap fun (caller, callee) =>
        if callee == boundary.name then some caller else none }
  return (boundaries, unresolved, StrictLeanPolicy.canonicalEdges compilerEdges)

/-- Owned executable roots: computable, non-proposition, safe, non-partial,
non-internal definitions and opaque constants, excluding compiler-generated
eliminator and matcher machinery (reached through the authored roots that use
it) and declarations whose result is a `Sort` (types are erased before
execution, like propositions). -/
private def executableRoots (env : Environment) (own : Array (Name × ConstantInfo)) :
    CommandElabM (Array Name) := do
  let mut roots : Array Name := #[]
  for (name, info) in own do
    match info with
    | .defnInfo _ | .opaqueInfo _ =>
        if name.isInternal || info.isUnsafe || info.isPartial
            || Lean.isNoncomputable env name then continue
        if Lean.isAuxRecursor env name
            || Lean.isNoConfusion env name || Lean.Meta.isMatcherCore env name then continue
        if ← liftTermElabM <| Meta.isProp info.type then continue
        let typeProducing ← liftTermElabM <| returnsSort info.type
        if typeProducing then continue
        roots := roots.push name
    | _ => continue
  return roots

/-- Build the complete report for exact requested module names. The trusted
runner calls this function directly, without parsing a command in the audited
module's frontend extension environment. -/
def environmentReport (modules : List Name)
    (loadReplacementHistory : Name → IO (Except String (Array (Name × Name))) :=
      fun _ => pure (.error "trusted source-history loader was not supplied"))
    (includeExecution : Bool := true) (includeModuleOrigins : Bool := true) :
    CommandElabM StrictLean.Report.Environment := do
  if modules.isEmpty then
    throwError "environmentReport: no owned module names were supplied"
  if Lean.githash != "819816b2e0a3bf405af45ae5c7af2491d8f5bee6" then
    throwError "execution coverage is unsupported on compiler commit {Lean.githash}"
  let env ← getEnv
  -- Execution trust checks always need canonical origins. Logical-only
  -- documentation inspection may omit this otherwise unused report payload.
  let moduleOrigins ← if includeExecution || includeModuleOrigins then
      env.header.moduleNames.zip env.header.moduleData |>.mapM fun (moduleName, data) => do
        let path ← liftIO <| IO.FS.realPath (← Lean.findOLean moduleName)
        return ({ name := moduleName, olean := path.toString
                  imports := data.imports.map (·.module) } :
          StrictLean.Report.ModuleOrigin)
    else pure #[]
  let own ← ownedDecls env modules
  let entries ← own.mapM fun (name, info) => declEntry env name info
  -- Documentation consumes only `declarations`; avoid constructing unused
  -- execution graphs. The full gate and all other callers retain them.
  let execution ← if includeExecution then do
    -- Names alone do not establish toolchain ownership: an adopter or dependency
    -- can supply Init.* modules. Resolve each candidate once, and require the
    -- exact canonical artifact path in the pinned toolchain's library directory.
    -- Missing origin evidence throws rather than granting a runtime exemption.
    let toolchainLib ← liftIO <| Lean.getLibDir (← Lean.findSysroot)
    let mut nativeModules : NameMap StrictLeanPolicy.NativeOrigin := {}
    for (moduleName, origin) in env.header.moduleNames.zip moduleOrigins do
      if moduleName.getRoot == `Init then
        let actual ← liftIO <| IO.FS.realPath origin.olean
        let expected := Lean.modToFilePath toolchainLib moduleName "olean"
        if ← liftIO expected.pathExists then
          if actual == (← liftIO <| IO.FS.realPath expected) then
            let receipt ← match StrictLeanPolicy.admitNativeOrigin moduleName actual.toString
                (← liftIO <| IO.FS.realPath expected).toString with
              | .ok receipt => pure receipt
              | .error error => throwError "{error}"
            nativeModules := nativeModules.insert origin.name receipt
    let recursorHelpers := brecOnHelpers env own
    let mut roots ← executableRoots env own
    for entry in entries do
      if let some contract := entry.executableContract then
        if contract.failure.isNone && !roots.contains contract.root then
          roots := roots.push contract.root
    let candidates := simplificationCandidates env
    let proofCache ← liftIO <| IO.mkRef ({} : Std.HashMap (Name × Name) (Correspondence × Option String))
    roots.mapM fun root => do
      let (boundaries, unresolved, compilerEdges) ←
        executionWalk env modules nativeModules loadReplacementHistory candidates proofCache recursorHelpers root
      let some moduleName := (env.getModuleIdxFor? root).map
          fun idx => env.header.modules[(idx : Nat)]!.module
        | throwError "owned executable root {root} has no module index"
      return ({
        name := root
        «module» := moduleName
        boundaries, unresolved, compilerEdges } :
        StrictLean.Report.ExecutionRoot)
    else pure #[]
  return {
    toolchain := Lean.versionString
    modules := StrictLeanPolicy.canonicalNames env.header.moduleNames
    moduleOrigins
    declarations := entries
    execution
  }

/-- `audit_dump_json`: compatibility command for direct interactive use. The
Lean-native checker calls `environmentReport` directly. -/
elab (name := auditDumpJsonCmd) "audit_dump_json" : command => do
  let some pathStr := ← liftIO (IO.getEnv "AUDIT_DUMP_PATH")
    | throwError "audit_dump_json: AUDIT_DUMP_PATH is not set"
  let some modulesRaw := ← liftIO (IO.getEnv "AUDIT_OWN_MODULES")
    | throwError "audit_dump_json: AUDIT_OWN_MODULES is not set"
  let modules := (modulesRaw.split (· == ',')).toList
    |>.filterMap fun t =>
      let t := t.trimAscii.toString
      if t.isEmpty then none else some t.toName
  let report ← environmentReport modules
  liftIO <| IO.FS.writeFile (System.FilePath.mk pathStr) (Json.pretty (toJson report))

end StrictLean.Probe
