/-
Positive control: every declaration below is **kernel-only** — its exact
transitive axiom set is empty. The checker must classify these declarations
as `kernel-only` (see lean/Fixtures/fixtures.json). `rfl`-proved equations about
reducible literals stay inside the kernel; no extension principles at all.
-/
theorem fixtures_kernel_only_nat : 1 + 1 = 2 := rfl

theorem fixtures_kernel_only_and : True ∧ True := ⟨trivial, trivial⟩

theorem fixtures_kernel_only_list : [1, 2, 3].length = 3 := rfl
