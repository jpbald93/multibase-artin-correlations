import MixedExclusion

/-! Satisfiability certificates (outside the library; not imported by it).
For every theorem with hypotheses: a Lean-checked example showing those hypotheses can all be met
simultaneously by concrete values. Theorems whose conclusion is `False` assert that their hypotheses
are jointly impossible; for those we certify that every hypothesis but the last is satisfiable,
so the impossibility is not caused by a trivially inconsistent subset. -/

set_option linter.unusedVariables false
set_option linter.unnecessarySeqFocus false
set_option linter.style.longLine false

-- hypotheses of MixedExclusion.legendreSym_eq_neg_one_of_isPrimitiveRoot are satisfiable
example : ∃ (p : ℕ) (hp_fact : Fact p.Prime) (hp2 : p ≠ 2) (a : ℤ) (ha : IsPrimitiveRoot ((a : ZMod p)) (p - 1)), True :=
  ⟨3, ⟨by norm_num⟩, by decide, 2, IsPrimitiveRoot.mk_of_lt _ (by norm_num) (by decide) (by intro l h0 h1; interval_cases l <;> decide), trivial⟩

-- hypotheses of MixedExclusion.isSquare_natCast_zmod_three are satisfiable
example : ∃ (n : ℕ) (hn : n % 3 ≠ 0), True :=
  ⟨1, by decide, trivial⟩

-- hypotheses of MixedExclusion.isSquare_three_iff are satisfiable
example : ∃ (q : ℕ) (hq : Fact q.Prime) (hq2 : q ≠ 2) (hq3 : q ≠ 3), True :=
  ⟨5, ⟨by norm_num⟩, by decide, by decide, trivial⟩

-- hypotheses of MixedExclusion.mod_three_ne_zero are satisfiable
example : ∃ (p : ℕ) (hp : p.Prime) (hp3 : p ≠ 3), True :=
  ⟨5, by norm_num, by decide, trivial⟩

-- hypotheses of MixedExclusion.not_primitiveRoot_two_six_of_gap (all except `h6`) are satisfiable; with `h6` they are jointly impossible, which is the theorem
example : ∃ (p q : ℕ) (hp : Fact p.Prime) (hq : Fact q.Prime) (hp3 : 3 < p) (hq3 : 3 < q) (hgap : q % 24 = (p + 10) % 24 ∨ q % 24 = (p + 14) % 24) (h2 : IsPrimitiveRoot (((2 : ℤ) : ZMod p)) (p - 1)), True :=
  ⟨5, 19, ⟨by norm_num⟩, ⟨by norm_num⟩, by norm_num, by norm_num, by decide, IsPrimitiveRoot.mk_of_lt _ (by norm_num) (by decide) (by intro l h0 h1; interval_cases l <;> decide), trivial⟩

-- hypotheses of MixedExclusion.not_primitiveRoot_six_two_of_gap (all except `h2`) are satisfiable; with `h2` they are jointly impossible, which is the theorem
example : ∃ (p q : ℕ) (_ : Fact p.Prime) (_ : Fact q.Prime) (hp3 : 3 < p) (hq3 : 3 < q) (hgap : q % 24 = (p + 10) % 24 ∨ q % 24 = (p + 14) % 24) (h6 : IsPrimitiveRoot (((6 : ℤ) : ZMod p)) (p - 1)), True :=
  ⟨11, 73, ⟨by norm_num⟩, ⟨by norm_num⟩, by norm_num, by norm_num, by decide, IsPrimitiveRoot.mk_of_lt _ (by norm_num) (by decide) (by intro l h0 h1; interval_cases l <;> decide), trivial⟩
