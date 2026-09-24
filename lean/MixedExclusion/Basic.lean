/-
Copyright (c) 2026 J. Bald. Released under the MIT license.
Authors: J. Bald
-/
import Mathlib.NumberTheory.LegendreSymbol.QuadraticReciprocity
import Mathlib.RingTheory.RootsOfUnity.PrimitiveRoots
import Mathlib.Tactic

set_option linter.style.header false

/-!
# A mixed-base quadratic obstruction for primitive roots

Formalises the proposition of the data note: if `p, q > 3` are primes with
`q - p ≡ 10` or `14 (mod 24)`, then `2` is not a primitive root modulo `p` while
`6` is a primitive root modulo `q`; and the same with the bases interchanged.
The primes need not be consecutive and either may be the larger.

The gap condition is stated as `q % 24 = (p + 10) % 24 ∨ q % 24 = (p + 14) % 24`,
which is `q - p ≡ 10` or `14 (mod 24)` without integer subtraction.

Ingredients, all from Mathlib: a primitive root modulo an odd prime is a
quadratic non-residue (Euler's criterion); the second supplementary law for `2`;
quadratic reciprocity for `3`; multiplicativity of the Legendre symbol.
-/

namespace MixedExclusion

open ZMod

/-- A primitive root modulo an odd prime is a quadratic non-residue. -/
theorem legendreSym_eq_neg_one_of_isPrimitiveRoot
    {p : ℕ} [hp_fact : Fact p.Prime] (hp2 : p ≠ 2) {a : ℤ}
    (ha : IsPrimitiveRoot ((a : ZMod p)) (p - 1)) :
    legendreSym p a = -1 := by
  have hp : p.Prime := hp_fact.out
  have ha_order : orderOf (a : ZMod p) = p - 1 := IsPrimitiveRoot.iff_orderOf.mp ha
  have hge3 : p ≥ 3 := by have := hp.two_le; omega
  have ha0 : (a : ZMod p) ≠ 0 := by
    intro h0
    apply ha.ne_zero (Nat.sub_ne_zero_of_lt hp.one_lt)
    simpa using h0
  rcases legendreSym.eq_one_or_neg_one p ha0 with h | h
  · exfalso
    have heq : (legendreSym p a : ZMod p) = (a : ZMod p) ^ (p / 2) := legendreSym.eq_pow p a
    rw [h] at heq
    have h1 : (a : ZMod p) ^ (p / 2) = 1 := by simpa using heq.symm
    have hdvd : orderOf (a : ZMod p) ∣ p / 2 := orderOf_dvd_of_pow_eq_one h1
    rw [ha_order] at hdvd
    have := Nat.le_of_dvd (by omega) hdvd
    omega
  · exact h

/-- `IsSquare (n : ZMod 3)` iff `n % 3 = 1`, provided `3 ∤ n`. -/
theorem isSquare_natCast_zmod_three (n : ℕ) (hn : n % 3 ≠ 0) :
    IsSquare ((n : ℕ) : ZMod 3) ↔ n % 3 = 1 := by
  have hcast : ((n : ℕ) : ZMod 3) = ((n % 3 : ℕ) : ZMod 3) := (ZMod.natCast_mod n 3).symm
  rw [hcast]
  have h3 : n % 3 = 0 ∨ n % 3 = 1 ∨ n % 3 = 2 := by omega
  rcases h3 with h | h | h
  · exact absurd h hn
  · simp only [h]
    exact ⟨fun _ => trivial, fun _ => ⟨1, by decide⟩⟩
  · simp only [h]
    exact ⟨by decide, by omega⟩

/-- The finite residue check behind the obstruction: for residues `r, s` modulo
`24` of primes `p, q > 3` with `2` a non-residue modulo `p` (`r ≢ ±1 (mod 8)`)
and `s ≡ r + 10` or `r + 14`, the characters of `2` and `3` at `q` agree, so
`6` is a quadratic residue modulo `q`. Checked by exhaustive evaluation. -/
theorem residue_check : ∀ r, r < 24 → ∀ s, s < 24 → r % 2 = 1 → r % 3 ≠ 0 → s % 3 ≠ 0 →
    ¬ (r % 8 = 1 ∨ r % 8 = 7) → (s = (r + 10) % 24 ∨ s = (r + 14) % 24) →
    ((s % 8 = 1 ∨ s % 8 = 7) ↔ (s % 12 = 1 ∨ s % 12 = 11)) := by
  intro r hr s hs h1 h2 h3 h4 h5
  interval_cases r <;> omega

/-- For a prime `q > 3`, `3` is a square modulo `q` iff `q ≡ ±1 (mod 12)`. -/
theorem isSquare_three_iff {q : ℕ} [hq : Fact q.Prime] (hq2 : q ≠ 2) (hq3 : q ≠ 3) :
    IsSquare (3 : ZMod q) ↔ (q % 12 = 1 ∨ q % 12 = 11) := by
  have : Fact (Nat.Prime 3) := ⟨Nat.prime_three⟩
  have hqp : q.Prime := hq.out
  have hmod3 : q % 3 ≠ 0 := by
    intro h
    have h3 : 3 ∣ q := Nat.dvd_of_mod_eq_zero h
    exact hq3 ((Nat.prime_dvd_prime_iff_eq Nat.prime_three hqp).mp h3).symm
  have hodd : q % 2 = 1 := by
    rcases Nat.Prime.eq_two_or_odd hqp with h | h
    · exact absurd h hq2
    · exact h
  have hsq3 := isSquare_natCast_zmod_three q hmod3
  have h4 : q % 4 = 1 ∨ q % 4 = 3 := by omega
  rcases h4 with h4 | h4
  · have key := ZMod.exists_sq_eq_prime_iff_of_mod_four_eq_one (p := q) (q := 3) h4 (by norm_num)
    simp only [Nat.cast_ofNat] at key
    rw [key, hsq3]
    omega
  · have key := ZMod.exists_sq_eq_prime_iff_of_mod_four_eq_three (p := q) (q := 3) h4
      (by norm_num) hq3
    simp only [Nat.cast_ofNat] at key
    rw [key, hsq3]
    omega

/-- A prime `p > 3` is not divisible by `3`. -/
theorem mod_three_ne_zero {p : ℕ} (hp : p.Prime) (hp3 : p ≠ 3) : p % 3 ≠ 0 := by
  intro h
  exact hp3 ((Nat.prime_dvd_prime_iff_eq Nat.prime_three hp).mp (Nat.dvd_of_mod_eq_zero h)).symm

/-- **Mixed obstruction, first order.** If `p, q > 3` are primes with
`q - p ≡ 10` or `14 (mod 24)`, then `2` being a primitive root modulo `p` and
`6` being a primitive root modulo `q` cannot both hold. -/
theorem not_primitiveRoot_two_six_of_gap {p q : ℕ} [hp : Fact p.Prime] [hq : Fact q.Prime]
    (hp3 : 3 < p) (hq3 : 3 < q)
    (hgap : q % 24 = (p + 10) % 24 ∨ q % 24 = (p + 14) % 24)
    (h2 : IsPrimitiveRoot (((2 : ℤ) : ZMod p)) (p - 1))
    (h6 : IsPrimitiveRoot (((6 : ℤ) : ZMod q)) (q - 1)) : False := by
  have hp2 : p ≠ 2 := by omega
  have hq2 : q ≠ 2 := by omega
  have hpm3 := mod_three_ne_zero hp.out (by omega)
  have hqm3 := mod_three_ne_zero hq.out (by omega)
  have hA : (p + 10) % 24 = (p % 24 + 10) % 24 := by omega
  have hB : (p + 14) % 24 = (p % 24 + 14) % 24 := by omega
  rw [hA, hB] at hgap
  have hpodd : p % 2 = 1 := by
    rcases Nat.Prime.eq_two_or_odd hp.out with h | h
    · exact absurd h hp2
    · exact h
  -- 2 is a non-residue modulo p, so p ≡ 3, 5 (mod 8)
  have hL2p := legendreSym_eq_neg_one_of_isPrimitiveRoot hp2 h2
  have hns2p : ¬ IsSquare (2 : ZMod p) := by
    have := (legendreSym.eq_neg_one_iff' p (a := 2)).mp (by simpa using hL2p)
    simpa using this
  rw [ZMod.exists_sq_eq_two_iff hp2] at hns2p
  have key := residue_check (p % 24) (Nat.mod_lt _ (by norm_num)) (q % 24)
    (Nat.mod_lt _ (by norm_num)) (by omega) (by omega) (by omega) (by omega) hgap
  have key' : (q % 8 = 1 ∨ q % 8 = 7) ↔ (q % 12 = 1 ∨ q % 12 = 11) := by
    have e8 : q % 24 % 8 = q % 8 := Nat.mod_mod_of_dvd q (by norm_num)
    have e12 : q % 24 % 12 = q % 12 := Nat.mod_mod_of_dvd q (by norm_num)
    rw [e8, e12] at key
    exact key
  -- 6 is a non-residue modulo q
  have hL6q := legendreSym_eq_neg_one_of_isPrimitiveRoot hq2 h6
  have hmul : legendreSym q 6 = legendreSym q 2 * legendreSym q 3 := by
    rw [show (6 : ℤ) = 2 * 3 by norm_num, legendreSym.mul]
  have h20 : ((2 : ℕ) : ZMod q) ≠ 0 := by
    intro h; rw [ZMod.natCast_eq_zero_iff] at h
    exact hq2 ((Nat.prime_dvd_prime_iff_eq hq.out Nat.prime_two).mp h)
  have h30 : ((3 : ℕ) : ZMod q) ≠ 0 := by
    intro h; rw [ZMod.natCast_eq_zero_iff] at h
    have := (Nat.prime_dvd_prime_iff_eq hq.out Nat.prime_three).mp h
    omega
  have hs2 := ZMod.exists_sq_eq_two_iff (p := q) hq2
  have hs3 := isSquare_three_iff (q := q) hq2 (by omega)
  have h2val := legendreSym.eq_one_or_neg_one q (a := 2) (by simpa using h20)
  have h3val := legendreSym.eq_one_or_neg_one q (a := 3) (by simpa using h30)
  rw [hmul] at hL6q
  rcases h2val with h2v | h2v <;> rcases h3val with h3v | h3v
  · rw [h2v, h3v] at hL6q; norm_num at hL6q
  · -- 2 square, 3 non-square mod q
    have sq2 : IsSquare (2 : ZMod q) := by
      have := (legendreSym.eq_one_iff' q (a := 2) h20).mp (by simpa using h2v)
      simpa using this
    have ns3 : ¬ IsSquare (3 : ZMod q) := by
      have := (legendreSym.eq_neg_one_iff' q (a := 3)).mp (by simpa using h3v)
      simpa using this
    rw [hs2] at sq2; rw [hs3] at ns3
    exact ns3 (key'.mp sq2)
  · -- 2 non-square, 3 square mod q
    have ns2 : ¬ IsSquare (2 : ZMod q) := by
      have := (legendreSym.eq_neg_one_iff' q (a := 2)).mp (by simpa using h2v)
      simpa using this
    have sq3 : IsSquare (3 : ZMod q) := by
      have := (legendreSym.eq_one_iff' q (a := 3) h30).mp (by simpa using h3v)
      simpa using this
    rw [hs2] at ns2; rw [hs3] at sq3
    exact ns2 (key'.mpr sq3)
  · rw [h2v, h3v] at hL6q; norm_num at hL6q

/-- **Mixed obstruction, reversed order.** If `p, q > 3` are primes with
`q - p ≡ 10` or `14 (mod 24)`, then `6` being a primitive root modulo `p` and
`2` being a primitive root modulo `q` cannot both hold. This follows from the
first order with the roles of the primes exchanged, since `-10 ≡ 14`. -/
theorem not_primitiveRoot_six_two_of_gap {p q : ℕ} [Fact p.Prime] [Fact q.Prime]
    (hp3 : 3 < p) (hq3 : 3 < q)
    (hgap : q % 24 = (p + 10) % 24 ∨ q % 24 = (p + 14) % 24)
    (h6 : IsPrimitiveRoot (((6 : ℤ) : ZMod p)) (p - 1))
    (h2 : IsPrimitiveRoot (((2 : ℤ) : ZMod q)) (q - 1)) : False :=
  not_primitiveRoot_two_six_of_gap (p := q) (q := p) hq3 hp3 (by omega) h2 h6

end MixedExclusion

#print axioms MixedExclusion.legendreSym_eq_neg_one_of_isPrimitiveRoot
#print axioms MixedExclusion.isSquare_three_iff
#print axioms MixedExclusion.not_primitiveRoot_two_six_of_gap
#print axioms MixedExclusion.not_primitiveRoot_six_two_of_gap
