import Lean.Data.Json

open Lean

/-!
Typed machine-audit records shared by the audited environment probe and the
Lean checker executables. The policy consumes these values directly; JSON is
only an optional output format, not the semantic boundary between two
implementation languages.
-/

namespace StrictLean.Report

/-- One source position in Lean's one-based line/zero-based column format. -/
structure Position where
  line : Nat
  column : Nat
  deriving Repr, BEq, FromJson, ToJson

/-- Lean one-based lines and zero-based codepoint columns, with corresponding
zero-based UTF-16 columns (not absolute offsets). -/
structure Range where
  start : Position
  «end» : Position
  startUtf16 : Nat
  endUtf16 : Nat
  deriving Repr, BEq, FromJson, ToJson

/-- Full and selection ranges recorded by Lean for a declaration. -/
structure Ranges where
  range : Range
  selectionRange : Range
  deriving Repr, BEq, FromJson, ToJson

/-- A proof-bearing promise about one named executable and its exact predicate.
An unsupported or non-executable registration carries a failure, never success. -/
structure ExecutableContract where
  root : String
  requirement : String
  failure : Option String
  deriving Repr, FromJson, ToJson

/-- Complete Lean-semantic report for one owned constant. -/
structure Declaration where
  name : String
  /-- Structural original Name for new diagnostic transport; absent legacy records are unsupported. -/
  structuralName : Option String := none
  «module» : String
  kind : String
  «type» : String
  prettyType : String
  isProp : Bool
  isUnsafe : Bool
  isPartial : Bool
  safety : Option String
  «instance» : Bool
  «noncomputable» : Bool
  implementedBy : Option String
  «extern» : Bool
  internal : Bool
  «private» : Bool
  projection : Bool
  matcher : Bool
  recursive : Bool
  unsafeRecBase : Option String
  levelParams : Array String
  all : Array String
  hints : Option String
  valueConstants : Array String
  unsafeRecValueOrigin : Option String
  unsafeRecValueExact : Option Bool
  unsafeRecValueDefeq : Option Bool
  unsafeRecEquationExact : Option Bool
  unsafeRecEquationDefeq : Option Bool
  unsafeRecEquationAxioms : Option (Array String)
  nativeBoolShape : Bool
  nativeReplay : Option Bool
  nativeUseParents : Array String
  ranges : Option Ranges
  axioms : Array String
  executableContract : Option ExecutableContract := none
  deriving Repr, FromJson, ToJson

/-- One boundary in the conservative compiler/source closure of an
executable root. `boundary` is one of `runtime-replacement`, `compiler-simplification`, `native-runtime`,
`external`, `unsafe-computation`, `partial-computation`, `opaque-computation`,
or `compiler-trusted-proof`; `correspondence` is `checked`, `trusted`, or
`unresolved`. -/
structure ExecutionBoundary where
  name : String
  «module» : String
  boundary : String
  correspondence : String
  owned : Bool
  replacement : Option String
  evidence : Option String
  compilerCallers : Array String := #[]
  deriving Repr, FromJson, ToJson

/-- Execution coverage for one owned executable root: every boundary its
conservative compiler/source closure reaches, plus every dependency path the
analysis could not resolve. -/
structure ExecutionRoot where
  name : String
  structuralName : Option String := none
  «module» : String
  boundaries : Array ExecutionBoundary
  unresolved : Array String
  /-- Direct calls/closures/initializers retained in the pinned compiler IR;
  unlike the boundary candidate closure, these record compiled edges. -/
  compilerEdges : Array (String × String) := #[]
  deriving Repr, FromJson, ToJson

/-- Lean-resolved origin of one imported module, with its direct imports as
recorded in the loaded module header. -/
structure ModuleOrigin where
  name : String
  olean : String
  imports : Array String
  deriving Repr, BEq, FromJson, ToJson

/-- Complete report for one exact requested module set. -/
structure Environment where
  toolchain : String
  modules : Array String
  moduleOrigins : Array ModuleOrigin
  declarations : Array Declaration
  execution : Array ExecutionRoot
  deriving Repr, FromJson, ToJson

end StrictLean.Report
