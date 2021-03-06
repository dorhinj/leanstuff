import tactic.find algebra.group_power tactic.ring data.set.finite data.zmod.basic
universes u v
variables {α : Type u} {β : Type v}
open nat finset equiv int.modeq nat int
local attribute [instance, priority 0] classical.prop_decidable

lemma nat.div_mul_le (a) {b} (hb : 0 < b) : a / b * b ≤ a :=
have h : 0 + a / b * b ≤ a % b + a / b * b := add_le_add (nat.zero_le _) (le_refl _),
by rwa [zero_add, mul_comm, nat.mod_add_div, mul_comm] at h

lemma int.dvd_of_pow_dvd_pow {a b : ℤ} {n : ℕ} (hn : 0 < n) (h : a ^ n ∣ b ^ n) : a ∣ b :=
begin
  rw [← nat_abs_dvd, ← dvd_nat_abs, int.nat_abs_pow, int.nat_abs_pow, int.coe_nat_dvd] at h,
  rw [← nat_abs_dvd, ← dvd_nat_abs, int.coe_nat_dvd],
  exact (nat.pow_dvd_pow_iff hn).1 h
end

lemma nat.cast_div [division_ring α] [char_zero α] {n m : ℕ} (h : n ∣ m) (hn : n ≠ 0) :
    ((m / n : ℕ) : α) = (m : α) / n :=
eq.symm ((div_eq_iff_mul_eq (by rwa nat.cast_ne_zero)).2 (by rw [← nat.cast_mul, nat.div_mul_cancel h]))

lemma nat.cast_div_le [linear_ordered_field α] {n m : ℕ} (hm : 0 < m) : ((n / m : ℕ) : α) ≤ (n / m : α) :=
le_of_mul_le_mul_right
  (calc ((n / m : ℕ) : α) * m ≤ n : by rw [← nat.cast_mul, nat.cast_le]; exact nat.div_mul_le _ hm
    ... =  (n / m : α) * m : (div_mul_cancel (n : α) (ne_of_lt (nat.cast_lt.2 hm)).symm).symm)
  (nat.cast_lt.2 hm)

lemma nat.prime.odd_iff_ge_three {p : ℕ} (hp : prime p) : p % 2 = 1 ↔ 3 ≤ p :=
⟨λ hpo, succ_le_of_lt (lt_of_le_of_ne hp.1 (λ h, by rw ← h at hpo; exact absurd hpo dec_trivial)),
λ hp3, or.cases_on (nat.mod_two_eq_zero_or_one p)
  (λ h, or.cases_on (hp.2 _ (nat.dvd_of_mod_eq_zero h)) (λ h2, absurd h2 dec_trivial)
    (λ h1, by rw ← h1 at hp3; exact absurd hp3 dec_trivial)) id⟩

lemma int.cast_div [division_ring α] [char_zero α] {i j : ℤ} (h : j ∣ i) (hj : j ≠ 0) :
  ((i / j : ℤ) : α) = (i : α) / j :=
eq.symm ((div_eq_iff_mul_eq (by rwa int.cast_ne_zero)).2 (by rw [← int.cast_mul, int.div_mul_cancel h]))

lemma int.add_div {i j : ℤ} (k : ℤ) (h : j ∣ i) (hk : j ≠ 0) :
  i / j + k / j = (i + k) / j :=
(domain.mul_left_inj hk).1
(let ⟨m, hm⟩ := exists_eq_mul_left_of_dvd h in
by rw [hm, mul_add, add_comm _ k, int.add_mul_div_right _ _ hk,
    int.mul_div_cancel _ hk, mul_add, add_comm])

lemma modeq_two_square_self (a : ℤ) : a * a ≡ a [ZMOD 2] :=
or.cases_on (int.mod_two_eq_zero_or_one a)
  (λ h, have h' : a ≡ 0 [ZMOD 2] := h,
    ((show a * a ≡ 0 * 0 [ZMOD 2], from modeq_mul h' h').trans h'.symm))
  (λ h, @eq.subst _ (λ b, a * a ≡ b [ZMOD 2]) _ _ (mul_one a)
    (int.modeq.modeq_mul rfl h))

lemma sum_two_squares_of_sum_two_squares_two_mul {n a b : ℤ} (h : a * a + b * b = 2 * n) :
    ∃ c d : ℤ, c * c + d * d = n :=
have hs : a * a + b * b ≡ 0 [ZMOD 2] := int.modeq.modeq_zero_iff.2 (h.symm ▸ dvd_mul_right _ _),
have hadd : (2 : ℤ) ∣ a + b := int.modeq.modeq_zero_iff.1 (int.modeq.trans
    (int.modeq.modeq_add (modeq_two_square_self _).symm (modeq_two_square_self _).symm) hs),
have hsub : (2 : ℤ) ∣ a - b :=
begin
  have : a - b = (a + b) + 2 * -b := by ring,
  rw this,
  exact dvd_add hadd (dvd_mul_right _ _),
end,
have h2 : (2 : ℤ) ≠ 0 := by norm_num,
⟨(a + b) / 2, (a - b) / 2,
  (domain.mul_left_inj h2).1
    (calc 2 * (((a + b) / 2) * ((a + b) / 2) + (a - b) / 2 * ((a - b) / 2))
        = (a + b) * ((a + b) / 2) + (a - b) * ((a - b) / 2) :
          by rw [mul_add (2 : ℤ), ← mul_assoc, ← mul_assoc, int.mul_div_cancel' hadd,
           int.mul_div_cancel' hsub]
    ... = a * a + b * b :
      (domain.mul_right_inj h2).1
        (by simp only [add_mul, mul_assoc _ _ (2 : ℤ), int.div_mul_cancel hadd,
              int.div_mul_cancel hsub]; ring)
    ... = 2 * n : h ▸ by simp [nat.pow_succ, int.coe_nat_mul, int.coe_nat_add])⟩

open finset function

private def mod_sub_half (n m : ℤ) : ℤ := if ((n % m : ℤ) : ℚ) ≤ m / 2 then (n : ℤ) % m else n % m - m

private lemma mod_sub_half_modeq {n m : ℤ} (hm : 0 < m) : mod_sub_half n m ≡ n [ZMOD m] :=
or.cases_on (classical.em (((n % m : ℤ) : ℚ) ≤ m / 2)) (λ h, begin
  rw [mod_sub_half, if_pos h],
  exact int.mod_mod _ _,
end)
(λ h, begin
  rw [mod_sub_half, if_neg h],
  conv {to_rhs, skip, rw ← sub_zero (n : ℤ)},
  exact int.modeq.modeq_sub (int.mod_mod _ _) (int.modeq.modeq_zero_iff.2 (dvd_refl _)),
end)

private lemma mod_sub_half_square {n m : ℤ} (hm : 0 < m) : mod_sub_half n m * mod_sub_half n m ≡ n * n [ZMOD m] :=
int.modeq.modeq_mul (mod_sub_half_modeq hm) (mod_sub_half_modeq hm)

private lemma mod_sub_half_eq_zero {n m : ℤ} (hm : 0 < m) (h : mod_sub_half n m * mod_sub_half n m = 0) :
    n * n ≡ 0 [ZMOD (m * m)] :=
have h : _ := eq_zero_of_mul_self_eq_zero h,
modeq_zero_iff.2 (mul_dvd_mul
  (modeq_zero_iff.1 (h ▸ (mod_sub_half_modeq hm).symm))
  (modeq_zero_iff.1 (h ▸ (mod_sub_half_modeq hm).symm)))

private lemma mod_sub_half_le {n m : ℤ} (hm : 0 < m) : ((abs (mod_sub_half n m) : ℤ) : ℚ) ≤ m / 2 :=
have hm0 : (m : ℤ) ≠ 0 := (ne_of_lt hm).symm,
begin
  cases classical.em (((n % m : ℤ) : ℚ) ≤ m / 2) with h h,
  { rwa [mod_sub_half, if_pos h, abs_of_nonneg (int.mod_nonneg (n : ℤ) hm0)] },
  { have hmn : (n : ℤ) % m - m < 0 := sub_neg_of_lt (trans_rel_left _
      (int.mod_lt _ hm0) (abs_of_pos hm)),
    rw [mod_sub_half, if_neg h, abs_of_neg hmn, neg_sub, int.cast_sub,
      sub_le_iff_le_add, ← sub_le_iff_le_add', sub_half],
    exact le_of_lt (lt_of_not_ge h) }
end

private lemma mod_sub_half_square_le {n m : ℤ} (hm : 0 < m) :
  ((mod_sub_half n m * mod_sub_half n m : ℤ) : ℚ) ≤ ((m * m) / 4) :=
calc ((mod_sub_half n m * mod_sub_half n m : ℤ) : ℚ) =
  ((abs (mod_sub_half n m) : ℤ) : ℚ) * ((abs (mod_sub_half n m) : ℤ) : ℚ) :
      by rw [← int.cast_mul, ← abs_mul, abs_mul_self]
   ... ≤ (m / 2) * (m / 2) : mul_self_le_mul_self (int.cast_nonneg.2 (abs_nonneg _)) (mod_sub_half_le hm)
   ... = m * m / 4 : by rw [_root_.div_mul_div, (show (2 : ℚ) * 2 = 4, from rfl)]

private lemma mod_sub_half_lt_of_odd {n m : ℤ} (hm : 0 < m) (hmo : m % 2 = 1) :
  ((abs (mod_sub_half n m) : ℤ) : ℚ) < m / 2 :=
let h := (@int.cast_nonneg ℚ _ _).2 (abs_nonneg (mod_sub_half n m)) in
have h2 : (2 : ℚ) ≠ 0 := by norm_num,
lt_of_le_of_ne (mod_sub_half_le hm)
(λ h, begin
  rw [← domain.mul_left_inj h2, mul_div_cancel' _ h2, (show (2 : ℚ) = ((2 : ℤ) : ℚ), from rfl),
    ← int.cast_mul, int.cast_inj] at h,
  have h2m : 2 ∣ m := h ▸ dvd_mul_right _ _,
  exact absurd ((int.mod_eq_zero_of_dvd h2m).symm.trans hmo) dec_trivial
end)

lemma four_squares_mul_four_squares {α : Type*} [comm_ring α] (a b c d w x y z : α) :
  (a * a + b * b +  c * c + d * d)  * (w * w + x * x +  y * y + z * z)  =
  (a * x - w * b + (d * y - z * c)) * (a * x - w * b + (d * y - z * c)) +
  (a * y - w * c + (b * z - x * d)) * (a * y - w * c + (b * z - x * d)) +
  (a * z - w * d + (c * x - y * b)) * (a * z - w * d + (c * x - y * b)) +
  (a * w + b * x +  c * y + d * z)  * (a * w + b * x +  c * y + d * z)  :=
by ring

lemma dvd_mul_sub_add_mul_sub {m a b c d w x y z : ℤ}
  (haw : w ≡ a [ZMOD m]) (hbx : x ≡ b [ZMOD m])
  (hcy : y ≡ c [ZMOD m]) (hdz : z ≡ d [ZMOD m]) :
  m ∣ (a * x - w * b + (d * y - z * c)) :=
dvd_add (modeq_iff_dvd.1 (modeq_mul haw hbx.symm)) (modeq_iff_dvd.1 (modeq_mul hdz hcy.symm))

lemma int.even_add_even {a b : ℤ} (ha : a % 2 = 0) (hb : b % 2 = 0) : (a + b) % 2 = 0 :=
show a + b ≡ 0 + 0 [ZMOD 2], from int.modeq.modeq_add ha hb

lemma int.odd_add_odd {a b : ℤ} (ha : a % 2 = 1) (hb : b % 2 = 1) : (a + b) % 2 = 0 :=
show a + b ≡ 1 + 1 [ZMOD 2], from int.modeq.modeq_add ha hb

lemma even_sum_four_squares {n a b c d : ℤ}
  (H : a * a + b * b + c * c + d * d = 2 * n) :
  ∃ w x y z, w * w + x * x + y * y + z * z = 2 * n ∧
  w * w + x * x ≡ 0 [ZMOD 2] ∧ y * y + z * z ≡ 0 [ZMOD 2] :=
have h' : a * a + b * b + c * c + d * d ≡ 0 [ZMOD 2] :=
  modeq_zero_iff.2 (H.symm ▸ dvd_mul_right _ _),
or.cases_on (int.mod_two_eq_zero_or_one (a * a))
  (λ ha, or.cases_on (int.mod_two_eq_zero_or_one (b * b))
    (λ hb, ⟨a, b, c, d, H, int.even_add_even ha hb,
      modeq_add_cancel_left (show a * a + b * b ≡ 0 [ZMOD 2], from int.even_add_even ha hb)
        (int.modeq.trans (by simp) h')⟩)
    (λ hb, or.cases_on (int.mod_two_eq_zero_or_one (c * c))
      (λ hc, ⟨a, c, b, d, by simp [H.symm], int.even_add_even ha hc,
        modeq_add_cancel_left (show a * a + c * c ≡ 0 [ZMOD 2], from int.even_add_even ha hc)
          (int.modeq.trans (by simp) h')⟩)
      (λ hc, ⟨a, d, b, c, by simp [H.symm],
        modeq_add_cancel_left (show b * b + c * c ≡ 0 [ZMOD 2], from int.odd_add_odd hb hc)
          (int.modeq.trans (by simp) h'),
        int.odd_add_odd hb hc⟩)))
  (λ ha, or.cases_on (int.mod_two_eq_zero_or_one (b * b))
    (λ hb, or.cases_on (int.mod_two_eq_zero_or_one (c * c))
      (λ hc, ⟨b, c, a, d, by simp [H.symm], int.even_add_even hb hc,
        modeq_add_cancel_left (show b * b + c * c ≡ 0 [ZMOD 2], from int.even_add_even hb hc)
          (int.modeq.trans (by simp) h')⟩)
      (λ hc, ⟨a, c, b, d, by simp [H.symm], int.odd_add_odd ha hc,
        modeq_add_cancel_left (show a * a + c * c ≡ 0 [ZMOD 2], from int.odd_add_odd ha hc)
          (int.modeq.trans (by simp) h')⟩))
    (λ hb, ⟨a, b, c, d, by simp [H.symm], int.odd_add_odd ha hb,
      modeq_add_cancel_left (show a * a + b * b ≡ 0 [ZMOD 2], from int.odd_add_odd ha hb)
        (int.modeq.trans (by simp) h')⟩))

private lemma sum_four_squares_of_sum_four_squares_two_mul {n a b c d : ℤ}
  (h : a * a + b * b + c * c + d * d = 2 * n) :
  ∃ a' b' c' d', a' * a' + b' * b' + c' * c' + d' * d' = n :=
let ⟨a, b, c, d, h, hab, hcd⟩ := even_sum_four_squares h in
let ⟨k, hk⟩ := exists_eq_mul_right_of_dvd (modeq_zero_iff.1 hab) in
let ⟨l, hl⟩ := exists_eq_mul_right_of_dvd (modeq_zero_iff.1 hcd) in
let ⟨a', b', hab'⟩ := sum_two_squares_of_sum_two_squares_two_mul hk in
let ⟨c', d', hcd'⟩ := sum_two_squares_of_sum_two_squares_two_mul hl in
⟨a', b', c', d', (domain.mul_left_inj (show (2 : ℤ) ≠ 0, by norm_num)).1
  (h ▸ by rw [add_assoc, hab', hcd', mul_add, ← hk, ← hl, ← add_assoc])⟩

section odd_primes
variables {p : ℕ} (hp : prime p) (hpo : p % 2 = 1)
include hp hpo

lemma bla14 {p : ℕ} (hp : prime p) (hpo : p % 2 = 1) {a b : fin (succ (p / 2))} :
  a.1 * a.1 + b.1 * b.1 + 1 < p * p :=
have hf : ∀ {a : fin (succ (p / 2))}, (a.1 : ℚ) ≤ p / 2 := λ a,
  calc (a.1 : ℚ) ≤ ((p / 2 : ℕ) : ℚ) : nat.cast_le.2 (le_of_lt_succ a.2)
           ... ≤ (p / 2 : ℚ) : nat.cast_div_le dec_trivial,
have hp2 : 0 ≤ (p : ℚ) / 2 := div_nonneg (nat.cast_nonneg _) (by norm_num),
have h20 : (2 : ℚ) ≠ 0 := by norm_num,
(@nat.cast_lt ℚ _ _ _).1 $
calc ((a.1 * a.1 + b.1 * b.1 + 1 : ℕ) : ℚ) = (a.1 : ℚ) * a.1 + b.1 * b.1 + 1 :
      by simp [nat.cast_mul, nat.cast_add]
  ... ≤ (p / 2) * (p / 2) + (p / 2) * (p / 2) + 1 : add_le_add (add_le_add
      (mul_le_mul hf hf (nat.cast_nonneg _) hp2)
      (mul_le_mul hf hf (nat.cast_nonneg _) hp2)) (le_refl _)
  ... = ((p : ℚ) * p) / 2 + 1 : by rw [div_mul_div, div_add_div_same, ← mul_two, mul_div_mul_right _ h20 h20]
  ... < ((p * p : ℕ) : ℚ) : add_lt_of_lt_sub_left
    (begin
      rw [nat.cast_mul, sub_half, one_lt_div_iff_lt (show (0 : ℚ) < 2, by norm_num)],
      exact calc (2 : ℚ) < 3 * 3 : by norm_num
        ... ≤ (p : ℚ) * (p : ℚ) : mul_self_le_mul_self (by norm_num) (nat.cast_le.2 (hp.odd_iff_ge_three.1 hpo)),
    end)

private lemma exists_sum_four_squares_dvd_prime :
  ∃ (m : ℕ) (a b c d : ℤ), a * a + b * b + c * c + d * d = m * p ∧ m < p ∧ 0 < m :=
let ⟨a, b, hab⟩ := bla12 hp hpo in
  let ⟨m, hm⟩ := exists_eq_mul_left_of_dvd hab in
  ⟨m, a.1, b.1, 1, 0,
    by rw [← int.coe_nat_mul m, ← hm];
      simp,
    lt_of_mul_lt_mul_right
      (by rw ← hm; exact bla14 hp hpo)
      (nat.zero_le p),
    pos_of_mul_pos_right
    (by rw [← hm, add_assoc]; exact succ_pos _)
    (nat.zero_le p)⟩

private lemma sum_four_squares_odd_prime :
  ∃ a b c d : ℤ, a * a + b * b + c * c + d * d = p :=
let h := exists_sum_four_squares_dvd_prime hp hpo in
let m := nat.find h in
let ⟨a, b, c, d, (habcd : (_ : ℤ) = (↑m : ℤ) * p), (hmp : m < p), (hm0 : 0 < m)⟩ :=
    nat.find_spec h in
have hm0' : (0 : ℤ) < m := int.coe_nat_lt.2 hm0,
have h₂ : ∃ r : ℤ, mod_sub_half a m * mod_sub_half a m + mod_sub_half b m * mod_sub_half b m +
    mod_sub_half c m * mod_sub_half c m + mod_sub_half d m * mod_sub_half d m = m * r :=
  exists_eq_mul_right_of_dvd (modeq_zero_iff.1 $
    int.modeq.trans (show _ ≡ m * p [ZMOD m], from
      by rw ← habcd; exact modeq_add (modeq_add (modeq_add
      (mod_sub_half_square hm0') (mod_sub_half_square hm0')) (mod_sub_half_square hm0'))
      (mod_sub_half_square hm0'))
    (show (m : ℤ) * p ≡ 0 [ZMOD m], from modeq_zero_iff.2 (dvd_mul_right m p))),
let ⟨r', hr'⟩ := h₂ in
have hr0 : (0 : ℤ) ≤ r' := @nonneg_of_mul_nonneg_left _ _ (↑m : ℤ) r'
  (hr' ▸ add_nonneg (add_nonneg (add_nonneg (mul_self_nonneg _) (mul_self_nonneg _))
    (mul_self_nonneg _)) (mul_self_nonneg _))
  hm0',
let r := r'.nat_abs in
have hr : mod_sub_half a ↑m * mod_sub_half a ↑m + mod_sub_half b ↑m *
  mod_sub_half b ↑m + mod_sub_half c ↑m * mod_sub_half c ↑m +
  mod_sub_half d ↑m * mod_sub_half d ↑m = ((m * r : ℕ) : ℤ) :=
  show _ = ((_ * r'.nat_abs : ℕ) : ℤ), by rwa [int.coe_nat_mul, int.nat_abs_of_nonneg hr0],
have h₁ : m = 1 := by_contradiction $ λ h₁,
  or.cases_on (nat.mod_two_eq_zero_or_one m)
    (λ hm2, let ⟨k, hk⟩ := exists_eq_mul_right_of_dvd (dvd_of_mod_eq_zero hm2) in
      have hk0 : 0 < k := pos_of_mul_pos_left (show 0 < 2 * k, from hk ▸ hm0)
        (nat.zero_le _),
      have hkm : k < m := hk.symm ▸ (lt_mul_iff_one_lt_left hk0).2 (lt_succ_self _),
      begin
        rw [hk, int.coe_nat_mul, mul_assoc] at habcd,
        rcases sum_four_squares_of_sum_four_squares_two_mul habcd with ⟨a', b', c', d', habcd'⟩,
        exact nat.find_min h hkm ⟨a', b', c', d', habcd', lt_trans hkm hmp, hk0⟩,
      end)
    (λ hm2, have hm2' : (m : ℤ) % (2 : ℕ) = 1 :=
        by rw [← int.coe_nat_mod, hm2, int.coe_nat_one],
      have add_quarters : ∀ q : ℚ, q = q / 4 + q / 4 + q / 4 + q / 4 := λ q,
        by rw [← (show ((2 : ℚ) * 2 = 4), by norm_num), ← div_div_eq_div_mul,
          add_halves, add_assoc, add_halves, add_halves],
      have hrm : r < m := lt_of_mul_lt_mul_left
        (begin
          rw [← int.coe_nat_lt, ← hr, ← @int.cast_lt ℚ],
          simp only [int.cast_add, int.cast_coe_nat, nat.cast_mul, nat.cast_add],
          rw [add_quarters ((m : ℚ) * m)],
          refine add_lt_add_of_lt_of_le (add_lt_add_of_lt_of_le
            (add_lt_add_of_lt_of_le _ (mod_sub_half_square_le hm0'))
            (mod_sub_half_square_le hm0')) (mod_sub_half_square_le hm0'),
          rw [← (show (2 : ℚ) * 2 = 4, by norm_num), ← _root_.div_mul_div, ← abs_mul_self, abs_mul, int.cast_mul],
          exact mul_self_lt_mul_self (int.cast_nonneg.2 (abs_nonneg _)) (mod_sub_half_lt_of_odd hm0' hm2'),
        end)
        (nat.zero_le m),
      have hmodeq : mod_sub_half a m * mod_sub_half a m + mod_sub_half b m * mod_sub_half b m
          + mod_sub_half c m * mod_sub_half c m + mod_sub_half d m * mod_sub_half d m ≡
          a * a + b * b + c * c + d * d [ZMOD m] :=
        modeq_add (modeq_add (modeq_add (mod_sub_half_square hm0') (mod_sub_half_square hm0'))
          (mod_sub_half_square hm0')) (mod_sub_half_square hm0'),
      have hdvd : (m : ℤ) ∣ a * a + b * b + c * c + d * d := habcd.symm ▸ dvd_mul_right _ _,
      have hdvd₁ : (m : ℤ) ∣ _ := modeq_zero_iff.1 ((modeq.trans hmodeq) (modeq_zero_iff.2 hdvd)),
      have hr0 : r ≠ 0 := λ h, begin
        rw [h, mul_zero, int.coe_nat_zero] at hr,
        simp only [int.nat_abs_mul_self.symm, (int.coe_nat_add _ _).symm] at hr,
        have hd := eq_zero_of_add_eq_zero (int.coe_nat_inj hr),
        have hc := eq_zero_of_add_eq_zero hd.1,
        have hab := eq_zero_of_add_eq_zero hc.1,
        simp only [(int.coe_nat_eq_coe_nat_iff _ _).symm, int.nat_abs_mul_self] at hab hc hd,
        have h : a * a + b * b + c * c + d * d ≡ 0 + 0 + 0 + 0 [ZMOD (m * m)] :=
          modeq_add (modeq_add (modeq_add (mod_sub_half_eq_zero hm0' hab.1)
            (mod_sub_half_eq_zero hm0' hab.2))
            (mod_sub_half_eq_zero hm0' hc.2)) (mod_sub_half_eq_zero hm0' hd.2),
        have : m ∣ p := dvd_of_mul_dvd_mul_left hm0
          (by rw [← int.coe_nat_dvd, int.coe_nat_mul, int.coe_nat_mul, ← habcd];
            exact modeq_zero_iff.1 h),
        cases hp.2 _ this with he he,
        { contradiction },
        { rw he at hmp,
          exact lt_irrefl _ hmp }
      end,
      have hk : _ := four_squares_mul_four_squares a b c d (mod_sub_half a m)
        (mod_sub_half b m) (mod_sub_half c m) (mod_sub_half d m),
      have ha : _ := @mod_sub_half_modeq a _ hm0',
      have hb : _ := @mod_sub_half_modeq b _ hm0',
      have hc : _ := @mod_sub_half_modeq c _ hm0',
      have hd : _ := @mod_sub_half_modeq d _ hm0',
      let ⟨a', ha'⟩ := exists_eq_mul_right_of_dvd
          (dvd_mul_sub_add_mul_sub ha hb hc hd) in
      let ⟨b', hb'⟩ := exists_eq_mul_right_of_dvd
          (dvd_mul_sub_add_mul_sub ha hc hd hb) in
      let ⟨c', hc'⟩ := exists_eq_mul_right_of_dvd
          (dvd_mul_sub_add_mul_sub ha hd hb hc) in
      have hm4 : ∀ i j : ℤ, (m : ℤ) * i * (m * j) = (m * m) * (i * j) :=
        λ i j, by simp [mul_comm, mul_assoc, mul_left_comm],
      begin
        rw [hr, habcd, ha', hb', hc', int.coe_nat_mul, hm4, hm4, hm4, hm4,
          ← mul_add, ← mul_add] at hk,
        have hk' := sub_eq_iff_eq_add'.2 hk,
        have hd₁ : (m : ℤ) * m ∣ ((a * mod_sub_half a ↑m + b * mod_sub_half b ↑m +
          c * mod_sub_half c ↑m + d * mod_sub_half d ↑m).nat_abs *
            (a * mod_sub_half a ↑m + b * mod_sub_half b ↑m +
            c * mod_sub_half c ↑m + d * mod_sub_half d ↑m).nat_abs : ℕ) :=
          by rw [int.nat_abs_mul_self, ← hk', ← mul_sub];
          exact dvd_mul_right _ _,
        have hd' : (m : ℤ) ∣ (a * mod_sub_half a ↑m + b * mod_sub_half b ↑m +
            c * mod_sub_half c ↑m + d * mod_sub_half d ↑m) :=
          dvd_nat_abs.1 (int.coe_nat_dvd.2 begin
            rw [← int.coe_nat_mul, ← nat.pow_two, ← nat.pow_two, int.coe_nat_dvd] at hd₁,
            exact (nat.pow_dvd_pow_iff dec_trivial).1 hd₁,
          end),
        cases exists_eq_mul_right_of_dvd hd' with d' hd',
        have habcd' : a' * a' + b' * b' + c' * c' + d' * d' = ↑r * ↑p :=
          (domain.mul_left_inj (ne_of_lt (mul_pos hm0' hm0')).symm).1 begin
            rw [mul_comm (r : ℤ), hk, hd'],
            ring,
          end,
        exact nat.find_min h hrm ⟨a', b', c', d', habcd', lt_trans hrm hmp,
          nat.pos_of_ne_zero (λ h, by rw h at hr0; contradiction)⟩,
      end),
⟨a, b, c, d, by rw [habcd, h₁]; simp⟩

end odd_primes

lemma sum_four_squares_int : ∀ n : ℕ, ∃ a b c d : ℤ, a * a + b * b + c * c + d * d = n
| 0 := ⟨0, 0, 0, 0, rfl⟩
| 1 := ⟨1, 0, 0, 0, rfl⟩
| n@(k+2) :=
have hm : prime (min_fac n) := min_fac_prime dec_trivial,
have n / min_fac n < n := factors_lemma,
let ⟨a, b, c, d, h₁⟩ := show ∃ a b c d : ℤ, a * a + b * b + c * c + d * d = min_fac n,
  from or.cases_on hm.eq_two_or_odd
    (λ h2, h2.symm ▸ ⟨1, 1, 0, 0, rfl⟩)
    (sum_four_squares_odd_prime hm) in
let ⟨w, x, y, z, h₂⟩ := sum_four_squares_int (n / min_fac n) in
⟨a * x - w * b + (d * y - z * c),
 a * y - w * c + (b * z - x * d),
 a * z - w * d + (c * x - y * b),
 a * w + b * x +  c * y + d * z,
  by rw [← four_squares_mul_four_squares, h₁, h₂, ← int.coe_nat_mul,
      int.coe_nat_eq_coe_nat_iff, nat.mul_div_cancel' (min_fac_dvd _)]⟩

lemma sum_four_squares (n : ℕ) : ∃ a b c d : ℕ, a * a + b * b + c * c + d * d = n :=
let ⟨a, b, c, d, h⟩ := sum_four_squares_int n in
⟨a.nat_abs, b.nat_abs, c.nat_abs, d.nat_abs,
  int.coe_nat_inj (h ▸ by simp only [int.coe_nat_add, int.nat_abs_mul_self])⟩