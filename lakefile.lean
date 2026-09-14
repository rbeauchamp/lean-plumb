import Lake
open Lake DSL

package «strict_lean» where
  srcDir := "lean"
  -- The verification toolset for the Strict Lean (see docs/).
  -- Code here exists to machine-check claims, patterns, and examples from the standard.
  leanOptions := #[⟨`warningAsError, true⟩]  -- Build warnings are failures

@[default_target]
lean_lib «Audit» where
  -- The claimed surface is every module at or below `Audit`, not only the
  -- transitive imports of the umbrella module. Lake's elaborated module
  -- inventory is the semantic inventory consumed by the declaration gate.
  globs := #[.andSubmodules `Audit]

@[default_target]
lean_lib «AuditApp» where
  -- The complete-application dogfooding surface: a bounded-slot limiter whose
  -- admission, update, and composition contracts are proved about the same
  -- computable definitions the `auditApp` executable runs.
  globs := #[.andSubmodules `AuditApp]

lean_lib «Fixtures» where
  -- Queryable exact inventory for isolated controls and mutations. This is
  -- deliberately not a default target: many modules are meant not to build.
  globs := #[.submodules `Fixtures]

lean_lib «StrictLean» where
  -- Lean-only checker implementation. Operational checker modules are
  -- separately qualified; they are not part of the conforming proof surface.
  globs := #[.submodules `StrictLean]

lean_exe «axiomGate» where
  root := `StrictLean.Checker.AxiomGate
  supportInterpreter := true

lean_exe «docFenceAudit» where
  root := `StrictLean.Checker.DocFenceAudit
  supportInterpreter := true

lean_exe «freshChecker» where
  root := `StrictLean.Checker.FreshChecker
  supportInterpreter := true

lean_exe «checkerSelftest» where
  root := `StrictLean.Checker.CheckerSelftest
  supportInterpreter := true

lean_exe «auditApp» where
  root := `Main
  supportInterpreter := true

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "0df444a360eaa60ab8c11dca51a86af692955474"
