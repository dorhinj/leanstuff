import group_theory.subgroup group_theory.order_of_element data.fintype data.nat.prime data.nat.modeq .zmod_as_fin2 algebra.pi_instances group_theory.subgroup
open equiv fintype finset
universes u v w
variables {G : Type u} {α : Type v} {β : Type w} [group G]

namespace finset

lemma filter_insert_of_pos [decidable_eq α] (s : finset α) {P : α → Prop} 
  [decidable_pred P] (a : α) (h : P a) : (insert a s).filter P = insert a (s.filter P) :=
ext.2 (λ x, by rw [mem_filter, mem_insert, mem_insert, mem_filter, eq_comm];
  exact ⟨λ h₁, by cases h₁.1; simp * at *, λ h₁, by cases h₁; simp * at *⟩)

lemma filter_insert_of_neg [decidable_eq α] (s : finset α) {P : α → Prop} 
  [decidable_pred P] (a : α) (h : ¬P a) : (insert a s).filter P = s.filter P :=
ext.2 (λ x, by rw [mem_filter, mem_insert, mem_filter, eq_comm];
  exact ⟨λ h₁, by cases h₁.1; simp * at *, by finish⟩)

lemma prod_const [comm_monoid β] (s : finset α) (b : β) 
  [decidable_eq α] : s.prod (λ x, b) = b ^ s.card :=
finset.induction_on s rfl (by simp [pow_add, mul_comm] {contextual := tt})

lemma sum_const [add_comm_monoid β] (s : finset α) (b : β) 
  [decidable_eq α] : s.sum (λ x, b) = add_monoid.smul s.card b :=
finset.induction_on s rfl (by simp [add_monoid.add_smul] {contextual := tt})

lemma card_pi {δ : α → Type*} [decidable_eq α] [Π a, decidable_eq (δ a)]
  (s : finset α) (t : Π a, finset (δ a)) : (s.pi t).card = s.prod (λ a, card (t a)) :=
multiset.card_pi _ _

end finset

lemma nat.sum_mod [decidable_eq α] (s : finset α) (f : α → ℕ) (n : ℕ) : 
  s.sum f ≡ (s.filter (λ x, f x % n ≠ 0)).sum f [MOD n] :=
finset.induction_on s rfl begin 
  assume a s has ih,
  by_cases ha : f a % n ≠ 0,
  { rw [finset.sum_insert has, finset.filter_insert_of_pos s a ha, finset.sum_insert],
    exact nat.modeq.modeq_add rfl ih,
    { finish [finset.mem_filter] } },
  { rw [finset.sum_insert has, finset.filter_insert_of_neg s a ha, 
      ← zero_add (finset.sum (finset.filter _ _) _)],
    rw [ne.def, ← nat.zero_mod n] at ha,
    exact nat.modeq.modeq_add (not_not.1 ha) ih }  
end 

namespace perm 

@[simp] lemma one_apply (a : α) : (1 : perm α) a = a := rfl

@[simp] lemma mul_apply (x y : perm α) (a : α) : (x * y) a = x (y a) := rfl

end perm

namespace fintype

instance quotient_fintype {α : Type*} [fintype α] (s : setoid α)
  [decidable_eq (quotient s)] : fintype (quotient s) :=
fintype.of_surjective quotient.mk (λ x, quotient.induction_on x (λ x, ⟨x, rfl⟩))

instance finset_fintype [fintype α] : fintype (finset α) :=
⟨finset.univ.powerset, λ x, finset.mem_powerset.2 (finset.subset_univ _)⟩

instance set.fintype (α : Type u) [fintype α] [decidable_eq α] : fintype (set α) := 
fintype.of_bijective finset.to_set
⟨λ _ _, finset.coe_eq_coe.1, 
λ x, by haveI := classical.prop_decidable;
  exact ⟨set.finite.to_finset ⟨set_fintype _⟩, finset.coe_to_finset⟩⟩

def subtype_fintype [fintype α] (p : α → Prop) [decidable_pred p] : fintype {x // p x} :=
set_fintype _

lemma card_eq_one_iff [fintype α] : card α = 1 ↔ (∃ x : α, ∀ y : α, y = x) :=
by rw [← card_unit, card_eq]; exact
⟨λ h, ⟨(classical.choice h).symm unit.star, λ y, (classical.choice h).bijective.1 
    (subsingleton.elim _ _)⟩, 
λ ⟨x, hx⟩, ⟨⟨λ _, unit.star, λ _, x, λ _, (hx _).trans (hx _).symm, 
    λ _, subsingleton.elim _ _⟩⟩⟩

lemma card_eq_zero_iff [fintype α] : card α = 0 ↔ (α → false) :=
⟨λ h a, have e : α ≃ empty := classical.choice (card_eq.1 (by simp [h])),
  (e a).elim, 
λ h, have e : α ≃ empty := ⟨λ a, (h a).elim, λ a, a.elim, λ a, (h a).elim, λ a, a.elim⟩, 
  by simp [card_congr e]⟩

lemma card_pos_iff [fintype α] : 0 < card α ↔ nonempty α :=
⟨λ h, classical.by_contradiction (λ h₁, 
  have card α = 0 := card_eq_zero_iff.2 (λ a, h₁ ⟨a⟩),
  lt_irrefl 0 $ by rwa this at h), 
λ ⟨a⟩, nat.pos_of_ne_zero (mt card_eq_zero_iff.1 (λ h, h a))⟩

lemma card_le_of_injective [fintype α] [fintype β] (f : α → β) 
  (hf : function.injective f) : card α ≤ card β :=
by haveI := classical.prop_decidable; exact
finset.card_le_card_of_inj_on f (λ _ _, finset.mem_univ _) (λ _ _ _ _ h, hf h)

lemma card_le_one_iff [fintype α] : card α ≤ 1 ↔ (∀ a b : α, a = b) :=
let n := card α in
have hn : n = card α := rfl,
match n, hn with
| 0 := λ ha, ⟨λ h, λ a, (card_eq_zero_iff.1 ha.symm a).elim, λ _, ha ▸ nat.le_succ _⟩
| 1 := λ ha, ⟨λ h, λ a b, let ⟨x, hx⟩ := card_eq_one_iff.1 ha.symm in
  by rw [hx a, hx b],
    λ _, ha ▸ le_refl _⟩
| (n+2) := λ ha, ⟨λ h, by rw ← ha at h; exact absurd h dec_trivial, 
  (λ h, card_unit ▸ card_le_of_injective (λ _, ())
    (λ _ _ _, h _ _))⟩
end

open finset

lemma card_pi {β : α → Type*} [fintype α] [decidable_eq α]
  [f : Π a, fintype (β a)] [Π a, decidable_eq (β a)] :
  card (Π a, β a) = univ.prod (λ a, card (β a)) :=
by letI f : fintype (Πa∈univ, β a) :=
  ⟨(univ.pi $ λa, univ), assume f, finset.mem_pi.2 $ assume a ha, mem_univ _⟩;
exact calc card (Π a, β a) = card (Π a ∈ univ, β a) : card_congr
  ⟨λ f a ha, f a, λ f a, f a (mem_univ a), λ _, rfl, λ _, rfl⟩ 
... = univ.prod (λ a, card (β a)) : finset.card_pi _ _

lemma card_fun [fintype α] [decidable_eq α] [fintype β] [decidable_eq β] :
  card (α → β) = card β ^ card α :=
by rw [card_pi, prod_const, nat.pow_eq_pow]; refl

end fintype

namespace set

lemma card_eq_of_eq {s t : set α} [fintype s] [fintype t] (h : s = t) :
  card s = card t :=
by congr; assumption

lemma card_image_of_inj_on {s : set α} [fintype s]
  {f : α → β} [fintype (f '' s)] (H : ∀x∈s, ∀y∈s, f x = f y → x = y) :
  fintype.card (f '' s) = fintype.card s :=
by haveI := classical.prop_decidable; exact
calc fintype.card (f '' s) = (s.to_finset.image f).card : card_fintype_of_finset' _ (by simp)
... = s.to_finset.card : card_image_of_inj_on
    (λ x hx y hy hxy, H x (mem_to_finset.1 hx) y (mem_to_finset.1 hy) hxy)
... = card s : (card_fintype_of_finset' _ (λ a, mem_to_finset)).symm

lemma card_image_of_injective (s : set α) [fintype s]
  {f : α → β} [fintype (f '' s)] (H : function.injective f) : 
  fintype.card (f '' s) = fintype.card s :=
card_image_of_inj_on $ λ x _ y _ h, H h

lemma coe_to_finset' [decidable_eq α] (s : set α) [fintype s] : (↑s.to_finset : set α) = s :=
set.ext (by simp)

lemma ssubset_iff_subset_not_subset {s t : set α} : s ⊂ t ↔ s ⊆ t ∧ ¬ t ⊆ s :=
by split; simp [set.ssubset_def, ne.def, set.subset.antisymm_iff] {contextual := tt}

lemma coe_ssubset [decidable_eq α] {s t : finset α} : (↑s : set α) ⊂ ↑t ↔ s ⊂ t :=
show ↑s ⊆ ↑t ∧ ↑s ≠ ↑t ↔ s ⊆ t ∧ ¬t ⊆ s,
  by split; simp [set.ssubset_def, ne.def, set.subset.antisymm_iff] {contextual := tt}

lemma card_lt_card {s t : set α} [fintype s] [fintype t] (h : s ⊂ t) : card s < card t :=
begin
  haveI := classical.prop_decidable,
  rw [card_fintype_of_finset' _ (λ x, mem_to_finset), card_fintype_of_finset' _ (λ x, mem_to_finset)],
  rw [← coe_to_finset' s, ← coe_to_finset' t, coe_ssubset] at h,
  exact finset.card_lt_card h,
end

def equiv_univ (α : Type u) : α ≃ (set.univ : set α) :=
{ to_fun := λ a, ⟨a, mem_univ _⟩,
  inv_fun := λ a, a.1,
  left_inv := λ a, rfl,
  right_inv := λ ⟨a, ha⟩, rfl }

@[simp] lemma card_univ (α : Type u) [fintype α] [fintype.{u} (set.univ : set α)] : 
  fintype.card (set.univ : set α) = fintype.card α := 
eq.symm (card_congr (equiv_univ α))

lemma eq_of_card_eq_of_subset {s t : set α} [fintype s] [fintype t]
  (hcard : card s = card t) (hsub : s ⊆ t) : s = t :=
classical.by_contradiction (λ h, lt_irrefl (card t)
  (have card s < card t := set.card_lt_card ⟨hsub, h⟩,
    by rwa hcard at this))

end set

namespace pi
variable {I : Type u}     -- The indexing type
variable {f : I → Type v} -- The family of types already equiped with instances

lemma mul_apply [∀ i, has_mul $ f i] (a b : Π i, f i) (i : I) : (a * b) i = a i * b i := rfl

lemma one_apply [∀ i, has_one $ f i] (i : I) : (1 : Π i, f i) i = 1 := rfl

end pi

local attribute [instance, priority 0] 
  classical.prop_decidable fintype.subtype_fintype set_fintype

section should_be_in_group_theory

noncomputable instance [fintype G] (H : set G) [is_subgroup H] : 
fintype (left_cosets H) := fintype.quotient_fintype (left_rel H)

lemma card_eq_card_cosets_mul_card_subgroup [fintype G] (H : set G) [is_subgroup H] : 
  card G = card (left_cosets H) * card H :=
by rw ← card_prod;
  exact card_congr (is_subgroup.group_equiv_left_cosets_times_subgroup _)

lemma order_of_dvd_of_pow_eq_one [fintype G] {a : G} {n : ℕ} (h : a ^ n = 1) :
  order_of a ∣ n :=
by_contradiction
(λ h₁, nat.find_min _ (show n % order_of a < order_of a, 
  from nat.mod_lt _ (nat.pos_of_ne_zero (order_of_ne_zero _))) 
    ⟨mt nat.dvd_of_mod_eq_zero h₁, by rwa ← pow_eq_mod_order_of⟩)

lemma eq_one_of_order_of_eq_one [fintype G] {a : G} (h : order_of a = 1) : a = 1 :=
by conv { to_lhs, rw [← pow_one a, ← h, pow_order_of_eq_one] }

lemma order_eq_card_gpowers [fintype G] {a : G} : order_of a = card (gpowers a) :=
begin
  refine (finset.card_eq_of_bijective _ _ _ _).symm,
  { exact λn hn, ⟨gpow a n, ⟨n, rfl⟩⟩ },
  { exact assume ⟨_, i, rfl⟩ _,
      have pos: (0:int) < order_of a,
        from int.coe_nat_lt.mpr $ nat.pos_iff_ne_zero.mpr $ order_of_ne_zero a,
      have 0 ≤ i % (order_of a),
        from int.mod_nonneg _ $ ne_of_gt pos,
      ⟨int.to_nat (i % order_of a),
        by rw [← int.coe_nat_lt, int.to_nat_of_nonneg this];
          exact ⟨int.mod_lt_of_pos _ pos, subtype.eq gpow_eq_mod_order_of.symm⟩⟩ },
  { intros, exact finset.mem_univ _ },
  { exact assume i j hi hj eq, pow_injective_of_lt_order_of a hi hj $ by simpa using eq }
end

@[simp] lemma card_trivial [fintype (is_subgroup.trivial G)] :
  fintype.card (is_subgroup.trivial G) = 1 := fintype.card_eq_one_iff.2
  ⟨⟨(1 : G), by simp⟩, λ ⟨y, hy⟩, subtype.eq $ is_subgroup.mem_trivial.1 hy⟩

local attribute [instance] left_rel normal_subgroup.to_is_subgroup

instance (H : set G) [normal_subgroup H] : group (left_cosets H) :=
{ one := ⟦1⟧,
  mul := λ a b, quotient.lift_on₂ a b
  (λ a b, ⟦a * b⟧)
  (λ a₁ a₂ b₁ b₂ (hab₁ : a₁⁻¹ * b₁ ∈ H) (hab₂ : a₂⁻¹ * b₂ ∈ H),
    quotient.sound
    ((is_subgroup.mul_mem_cancel_left H (is_subgroup.inv_mem hab₂)).1
        (by rw [mul_inv_rev, mul_inv_rev, ← mul_assoc (a₂⁻¹ * a₁⁻¹),
          mul_assoc _ b₂, ← mul_assoc b₂, mul_inv_self, one_mul, mul_assoc (a₂⁻¹)];
          exact normal_subgroup.normal _ hab₁ _))),
  mul_assoc := λ a b c, quotient.induction_on₃
    a b c (λ a b c, show ⟦_⟧ = ⟦_⟧, by rw mul_assoc),
  one_mul := λ a, quotient.induction_on a
    (λ a, show ⟦_⟧ = ⟦_⟧, by rw one_mul),
  mul_one := λ a, quotient.induction_on a
    (λ a, show ⟦_⟧ = ⟦_⟧, by rw mul_one),
  inv := λ a, quotient.lift_on a (λ a, ⟦a⁻¹⟧)
    (λ a b hab, quotient.sound begin
      show a⁻¹⁻¹ * b⁻¹ ∈ H,
      rw ← mul_inv_rev,
      exact is_subgroup.inv_mem (is_subgroup.mem_norm_comm hab)
    end),
  mul_left_inv := λ a, quotient.induction_on a
    (λ a, show ⟦_⟧ = ⟦_⟧, by rw inv_mul_self) }

instance quotient.mk.is_group_hom (H : set G) [normal_subgroup H] : @is_group_hom G (left_cosets H) _ _ 
  quotient.mk := 
⟨λ _ _, rfl⟩

instance subtype.val.is_group_hom (H : set G) [is_subgroup H] : is_group_hom (subtype.val : H → G) :=
⟨λ _ _, rfl⟩

def normalizer (H : set G) : set G :=
{ g : G | ∀ n, n ∈ H ↔ g * n * g⁻¹ ∈ H }

instance (H : set G) [is_subgroup H] : is_subgroup (normalizer H) :=
{ one_mem := by simp [normalizer],
  mul_mem := λ a b (ha : ∀ n, n ∈ H ↔ a * n * a⁻¹ ∈ H)
    (hb : ∀ n, n ∈ H ↔ b * n * b⁻¹ ∈ H) n,
    by rw [mul_inv_rev, ← mul_assoc, mul_assoc a, mul_assoc a, ← ha, ← hb],
  inv_mem := λ a (ha : ∀ n, n ∈ H ↔ a * n * a⁻¹ ∈ H) n,
    by rw [ha (a⁻¹ * n * a⁻¹⁻¹)];
    simp [mul_assoc] }

lemma subset_normalizer (H : set G) [is_subgroup H] : H ⊆ normalizer H :=
λ g hg n, by rw [is_subgroup.mul_mem_cancel_left _ ((is_subgroup.inv_mem_iff _).2 hg),
  is_subgroup.mul_mem_cancel_right _ hg]

instance (H : set G) [is_subgroup H] : normal_subgroup { x : normalizer H | ↑x ∈ H } :=
{ one_mem := show (1 : G) ∈ H, from is_submonoid.one_mem _,
  mul_mem := λ a b ha hb, show (a * b : G) ∈ H, from is_submonoid.mul_mem ha hb,
  inv_mem := λ a ha, show (a⁻¹ : G) ∈ H, from is_subgroup.inv_mem ha, 
  normal := λ a ha ⟨m, hm⟩, (hm a).1 ha }

lemma mem_normalizer_fintype_iff {H : set G} [fintype H] {x : G} : 
  x ∈ normalizer H ↔ ∀ n, n ∈ H → x * n * x⁻¹ ∈ H :=
⟨λ h n, (h n).1,
λ h n, ⟨h n, λ h₁,
have hsubs₁ : (λ n, x * n * x⁻¹) '' H ⊆ H := λ n ⟨y, hy⟩, hy.2 ▸ h y hy.1,
have hcard : card ((λ (n : G), x * n * x⁻¹) '' H) = card H :=
  set.card_image_of_injective H (λ a₁ a₂ ha, (mul_left_inj x).1 ((mul_right_inj (x⁻¹)).1 ha)),
have hsubs₂ : H ⊆ (λ n, x * n * x⁻¹) '' H := by_contradiction 
  (λ h, by have := set.card_lt_card (set.ssubset_iff_subset_not_subset.2 ⟨hsubs₁, h⟩);
    exact lt_irrefl (card H) (by rwa hcard at this)),
begin
  rw set.subset.antisymm hsubs₂ hsubs₁ at h₁,
  cases h₁ with m hm,
  have : m = n, from (mul_left_inj x).1 ((mul_right_inj (x⁻¹)).1 hm.2),
  exact this ▸ hm.1  
end⟩ ⟩

noncomputable lemma preimage_quotient_mk_equiv_subgroup_times_set (H : set G) [is_subgroup H]
  (s : set (left_cosets H)) : quotient.mk ⁻¹' s ≃ (H × s) :=
have h : ∀ {x : left_cosets H} {a : G}, x ∈ s → a ∈ H → 
  ⟦quotient.out x * a⟧ = ⟦quotient.out x⟧ := λ x a hx ha,
      quotient.sound (show (quotient.out x * a)⁻¹ * quotient.out x ∈ H, 
      from (is_subgroup.inv_mem_iff _).1 $ 
        by rwa [mul_inv_rev, inv_inv, ← mul_assoc, inv_mul_self, one_mul]), 
{ to_fun := λ ⟨a, ha⟩, ⟨⟨(quotient.out ⟦a⟧)⁻¹ * a, 
    @quotient.exact _ (left_rel H) _ _ $ by simp⟩, ⟨⟦a⟧, ha⟩⟩,
  inv_fun := λ ⟨⟨a, ha⟩, ⟨x, hx⟩⟩, ⟨(quotient.out x) * a, 
    show _ ∈ s, by simpa [h hx ha]⟩,
  left_inv := λ ⟨a, ha⟩, by simp,
  right_inv := λ ⟨⟨a, ha⟩, ⟨x, hx⟩⟩, by simp [h hx ha] }

end should_be_in_group_theory

structure group_action (G : Type u) [group G] (α : Type v) :=
(to_fun : G → α → α) 
(one : ∀ a : α, to_fun (1 : G) a = a )
(mul : ∀ (x y : G) (a : α), to_fun (x * y) a = to_fun x (to_fun y a))

instance : has_coe_to_fun (group_action G α) :=
{ F := λ _, G → α → α,
  coe := λ x, x.to_fun }

namespace group_action

@[simp] lemma one_apply (f : group_action G α) (a : α) : f 1 a = a := group_action.one f a

lemma mul_apply (f : group_action G α) (x y : G) (a : α) : f (x * y) a = f x (f y a) := group_action.mul _ _ _ _

lemma bijective (f : group_action G α) (x : G) : function.bijective (f x) :=
function.bijective_iff_has_inverse.2 ⟨f (x⁻¹), 
  λ a, by rw [← mul_apply, inv_mul_self, one_apply],
  λ a, by rw [← mul_apply, mul_inv_self, one_apply]⟩ 

/-- restriction of a group action on a Type α to s, a set α -/
def restriction {f : group_action G α} {s : set α}
  (h : ∀ a ∈ s, ∀ x : G, f x a ∈ s) :
  group_action G s :=
{ to_fun := λ x a, ⟨f x a, h a.1 a.2 x⟩,
  mul := λ x y a, subtype.eq (group_action.mul f x y a),
  one := λ a, subtype.eq (group_action.one f a) } 

lemma restriction_apply {f : group_action G α} {s : set α}
  (h : ∀ a ∈ s, ∀ x : G, f x a ∈ s) (x : G) (a : s) :
  f x a = (restriction h) x a := rfl

def orbit (f : group_action G α) (a : α) := set.range (λ x : G, f x a)

lemma mem_orbit_iff {f : group_action G α} {a b : α} :
  b ∈ orbit f a ↔ ∃ x : G, f x a = b :=
by finish [orbit]

def orbit_rel (f : group_action G α) (a b : α) := orbit f a = orbit f b

@[simp] lemma mem_orbit (f : group_action G α) (a : α) (x : G) :
  f x a ∈ orbit f a :=
⟨x, rfl⟩

lemma mem_orbit_self (f : group_action G α) (a : α) :
  a ∈ orbit f a :=
⟨1, show f 1 a = a, by simp⟩

lemma orbit_eq {f : group_action G α} {a b : α} : a ∈ orbit f b → orbit f a = orbit f b :=
λ ⟨x, (hx : f x b = a)⟩, set.ext (λ c, ⟨λ ⟨y, (hy : f y a = c)⟩, ⟨y * x,
  show f (y * x) b = c, by rwa [mul_apply, hx]⟩,
λ ⟨y, (hy : f y b = c)⟩, ⟨y * x⁻¹,
  show f (y * x⁻¹) a = c, by
    conv {to_rhs, rw [← hy, ← mul_one y, ← inv_mul_self x, ← mul_assoc,
      mul_apply, hx]}⟩⟩)

noncomputable def orbit_fintype (f : group_action G α) (a : α) [fintype G] :
fintype (orbit f a) := set.fintype_range _

def stabilizer (f : group_action G α) (a : α) : set G :=
{ x : G | f x a = a }

lemma mem_stabilizer_iff {f : group_action G α} {a : α} {x : G} :
  x ∈ stabilizer f a ↔ f x a = a :=
iff.rfl

lemma orbit_restriction {f : group_action G α} {s : set α} {a : s}
  {h : ∀ a ∈ s, ∀ x, f x a ∈ s} {b : s} :
  b ∈ orbit (restriction h) a ↔ (b : α) ∈ orbit f a :=
⟨λ h, let ⟨x, hx⟩ := mem_orbit_iff.1 h in
  mem_orbit_iff.2 ⟨x, hx ▸ rfl⟩,
λ h, let ⟨x, hx⟩ := mem_orbit_iff.1 h in
  mem_orbit_iff.2 ⟨x, subtype.eq hx⟩⟩

lemma stabilizer_restriction {f : group_action G α} {s : set α} {a : s}
  (h : ∀ a ∈ s, ∀ x, f x a ∈ s) :
stabilizer (restriction h) a = stabilizer f a :=
set.ext (λ x,by rw [mem_stabilizer_iff, mem_stabilizer_iff];
  exact ⟨λ h, by conv {to_rhs, rw ← h}; refl,
  λ h, subtype.eq h⟩)

instance (f : group_action G α) (a : α) : is_subgroup (stabilizer f a) :=
{ one_mem := one_apply _ _,
  mul_mem := λ x y (hx : f x a = a) (hy : f y a = a),
    show f (x * y) a = a, by rw mul_apply; simp *,
  inv_mem := λ x (hx : f x a = a), show f x⁻¹ a = a,
    by rw [← hx, ← mul_apply, inv_mul_self, one_apply, hx] }

noncomputable lemma orbit_equiv_left_cosets (a : α) (f : group_action G α) :
  orbit f a ≃ left_cosets (stabilizer f a) :=
by letI := left_rel (stabilizer f a); exact
{ to_fun := λ b, quotient.mk (classical.some (mem_orbit_iff.1 b.2)),
  inv_fun := λ x, ⟨f (quotient.out x) a, mem_orbit _ _ _⟩,
  left_inv := λ b, subtype.eq
    (let x := classical.some (mem_orbit_iff.1 b.2) in
    let y := quotient.out ⟦x⟧ in
    show f y a = b.1, begin
      have : f (x⁻¹ * y) a = a :=
        setoid.symm (quotient.mk_out x),
      rw [← one_mul y, ← mul_inv_self x, mul_assoc, mul_apply, this],
      exact classical.some_spec (mem_orbit_iff.1 b.2)
    end),
  right_inv := λ x,
    let hx := mem_orbit_iff.1 (mem_orbit f a (quotient.out x)) in
    let y := classical.some hx in
    have hy : f y a = f (quotient.out x) a := classical.some_spec hx,
    show quotient.mk y = _,
    begin
      rw ← quotient.out_eq x,
      refine quotient.sound  _,
      show y⁻¹ * _ ∈ _,
      rw [mem_stabilizer_iff, mul_apply, ← hy, ← mul_apply, inv_mul_self, one_apply]
    end }

def fixed_points (f : group_action G α) : set α := {a : α | ∀ x, x ∈ stabilizer f a}

lemma mem_fixed_points {f : group_action G α} {x : α} : x ∈ fixed_points f ↔
  (∀ y, y ∈ orbit f x → y = x) :=
⟨λ h y h₁, let ⟨a, ha⟩ := mem_orbit_iff.1 h₁ in ha ▸ h a,
λ h x, mem_stabilizer_iff.2 (h _ (mem_orbit _ _ _))⟩

lemma fixed_points_restriction {f : group_action G α} {s : set α}
  (h : ∀ a ∈ s, ∀ x, f x a ∈ s) {a : s} :
  a ∈ fixed_points (restriction h) ↔ (a : α) ∈ fixed_points f :=
show (∀ x, x ∈ stabilizer (restriction h) a) ↔
  (∀ x, x ∈ stabilizer f a),
by rw stabilizer_restriction h; refl

lemma card_orbit_of_mem_fixed_point {f : group_action G α} {x : α} [fintype (orbit f x)] : 
  x ∈ fixed_points f ↔ card (orbit f x) = 1 := 
begin
  rw [fintype.card_eq_one_iff, mem_fixed_points],
  split,
  { exact λ h, ⟨⟨x, mem_orbit_self _ _⟩, λ ⟨y, hy⟩, subtype.eq (h _ hy)⟩ }, 
  { assume h y hy,
    rcases h with ⟨⟨z, hz⟩, hz₁⟩,
    exact calc y = z : subtype.mk.inj (hz₁ ⟨y, hy⟩)
      ... = x : (subtype.mk.inj (hz₁ ⟨x, mem_orbit_self _ _⟩)).symm }
end

lemma mpl [fintype α] [fintype G] {p n : ℕ} (hp : nat.prime p) (h : card G = p ^ n)
  (f : group_action G α) : card α ≡ card (fixed_points f) [MOD p] :=
have hcard : ∀ s : set α, card ↥{x : α | orbit f x = s} % p ≠ 0
    ↔ card ↥{x : α | orbit f x = s} = 1 :=
  λ s, ⟨λ hs, begin
    have h : ∃ y, orbit f y = s := by_contradiction (λ h, begin
      rw not_exists at h,
      have : {x | orbit f x = s} = ∅ := set.eq_empty_iff_forall_not_mem.2 h,
      rw [set.card_eq_of_eq this, set.empty_card', nat.zero_mod] at hs,
      contradiction
    end),
    cases h with y hy,
    have hseq : {x | orbit f x = s} = orbit f y := set.ext (λ z, 
      ⟨λ h : orbit f z = s, hy.symm ▸ h ▸ mem_orbit_self _ _, 
      λ h, show orbit f z = s, by rwa orbit_eq h⟩),
    rw [card_eq_card_cosets_mul_card_subgroup (stabilizer f y), 
      ← card_congr (orbit_equiv_left_cosets y f)] at h,
    have : ∃ k ≤ n, card (orbit f y) = p ^ k := (nat.dvd_prime_pow hp).1
      (h ▸ dvd_mul_right _ _),
    rcases this with ⟨k, hk₁, hk₂⟩,
    rw [set.card_eq_of_eq hseq, hk₂] at hs ⊢,
    have : ¬p ∣ p ^ k := mt nat.mod_eq_zero_of_dvd hs,
    cases k,
    { refl },
    { simpa [nat.pow_succ] using this }
  end, 
  λ hs, hs.symm ▸ (nat.mod_eq_of_lt hp.gt_one).symm ▸ λ h, nat.no_confusion h⟩,
have h : (finset.univ.filter (λ a, card {x | orbit f x = a} % p ≠ 0)).sum 
  (λ a : set α, card {x | orbit f x = a}) = card (fixed_points f),
  from calc _ = (finset.univ.filter (λ a, card {x | orbit f x = a} % p ≠ 0)).sum 
    (λ a : set α, 1) : finset.sum_congr rfl (λ s hs, (hcard s).1 (finset.mem_filter.1 hs).2)
  ... = card {a : set α | card ↥{x : α | orbit f x = a} % p ≠ 0} :
  begin
    rw [finset.sum_const, nat.smul_eq_mul, mul_one],
    refine eq.symm (set.card_fintype_of_finset' _ _),
    simp [finset.mem_filter],
  end
  ... = card (fixed_points f) : fintype.card_congr 
    (@equiv.of_bijective _ _ 
      (show fixed_points f → {a : set α // card ↥{x : α | orbit f x = a} % p ≠ 0},
      from λ x, ⟨orbit f x.1, begin 
        rw [hcard, fintype.card_eq_one_iff],
        exact ⟨⟨x, rfl⟩, λ ⟨y, hy⟩, 
          have hy : y ∈ orbit f x := (show orbit f y = orbit f x, from hy) ▸ mem_orbit_self _ _,
          subtype.eq (mem_fixed_points.1 x.2 _ hy)⟩
      end⟩) 
      ⟨λ x y hxy, 
        have hxy : orbit f x.1 = orbit f y.1 := subtype.mk.inj hxy,
        have hxo : x.1 ∈ orbit f y.1 := hxy ▸ mem_orbit_self _ _,
        subtype.eq (mem_fixed_points.1 y.2 _ hxo), 
      λ ⟨s, hs⟩, begin
        rw [hcard, fintype.card_eq_one_iff] at hs,
        rcases hs with ⟨⟨x, hx₁⟩, hx₂⟩,
        exact ⟨⟨x, mem_fixed_points.2 (λ y hy, 
          subtype.mk.inj (hx₂ ⟨y, by have := orbit_eq hy; simpa [this, hx₁] using hx₁⟩))⟩,
            by simpa using hx₁⟩
      end⟩).symm,
calc card α % p = finset.sum finset.univ (λ a : set α, card {x // orbit f x = a}) % p : 
  by rw [card_congr (equiv_fib (orbit f)), fintype.card_sigma] 
... = _ : nat.sum_mod _ _ _
... = fintype.card ↥(fixed_points f) % p : by rw ← h; congr

end group_action

namespace sylow
open group_action

def F₁ (n : ℕ) [Zmod.pos n] (v : Zmod n → G) : Zmod (n+1) → G := 
λ m, if h : m.1 < n then v m.1 else ((list.range n).map (λ m : ℕ, v (m : Zmod n))).prod⁻¹

lemma F₁_injective {p : ℕ} [h0 : Zmod.pos p] : function.injective (@F₁ G _ p _) := 
λ x y hxy, funext (λ ⟨a, ha⟩, begin
  have : dite _ _ _ = dite _ _ _ := congr_fun hxy a,
  rw [Zmod.cast_val, nat.mod_eq_of_lt (nat.lt_succ_of_lt ha), 
    dif_pos ha, dif_pos ha] at this,
  rwa Zmod.mk_eq_cast
end)

/-- set of elements of G^n such that the product of the 
  list of elements of the vector is one -/
def Gstar (G : Type*) [group G] (n : ℕ) [Zmod.pos n] : set (Zmod n → G) := 
{v | ((list.range n).map (λ m : ℕ, v (↑m : Zmod n))).prod = 1 }

lemma prod_lemma (n : ℕ) [Zmod.pos n] (v : Zmod (n + 1) → G) :
  ((list.range (n + 1)).map (λ m : ℕ, v (m : Zmod (n + 1)))).prod =
  list.prod (list.map (λ (m : ℕ), v ↑m) (list.range n)) * v ↑n :=
by rw [list.range_concat, list.map_append, list.prod_append,
  list.map_singleton, list.prod_cons, list.prod_nil, mul_one]

lemma mem_Gstar_iff {n : ℕ} [Zmod.pos n] (v : Zmod (n + 1) → G) :
  v ∈ Gstar G (n + 1) ↔ v ∈ F₁ n '' (set.univ : set (Zmod n → G)) :=
⟨λ h : list.prod (list.map (λ (m : ℕ), v ↑m) (list.range (n + 1))) = 1, 
  have h₁ : list.map (λ (m : ℕ), v ((m : Zmod n).val : Zmod (n+1))) (list.range n)
    = list.map (λ (m : ℕ), v m) (list.range n) := list.map_congr (λ m hm, 
  have hm' : m < n := list.mem_range.1 hm,  
    by simp[nat.mod_eq_of_lt hm']),
⟨λ m, v m.val, set.mem_univ _, funext (λ i, show dite _ _ _ = _, begin
  split_ifs,
  { refine congr_arg _ (fin.eq_of_veq _), 
    simp [nat.mod_eq_of_lt h_1, nat.mod_eq_of_lt (nat.lt_succ_of_lt h_1)] },
  { have hi : i = n := fin.eq_of_veq begin 
      rw [Zmod.cast_val, nat.mod_eq_of_lt (nat.lt_succ_self _)],
      exact le_antisymm (nat.le_of_lt_succ i.2) (le_of_not_gt h_1),
    end,
    rw [h₁, hi, inv_eq_iff_mul_eq_one, ← prod_lemma, h] }
end)⟩,
λ ⟨w, hw⟩, 
have h : list.map (λ m : ℕ, w m) (list.range n) = list.map (λ m : ℕ, v m) (list.range n) :=
list.map_congr (λ k hk, 
  have hk' : k < n := list.mem_range.1 hk,
  hw.2 ▸ (show _ = dite _ _ _, 
    by rw [Zmod.cast_val, nat.mod_eq_of_lt (nat.lt_succ_of_lt hk'), dif_pos hk'])),
begin
  show list.prod (list.map (λ (m : ℕ), v ↑m) (list.range (n + 1))) = 1,
  rw [prod_lemma, ← h, ← hw.2],
  show _ * dite _ _ _ = (1 : G),
  rw [Zmod.cast_val, nat.mod_eq_of_lt (nat.lt_succ_self _), dif_neg (lt_irrefl _),
    mul_inv_self],
end⟩

def F₂ (α : Type*) (n : ℕ) [h0 : Zmod.pos n] : 
  group_action (multiplicative (Zmod n)) (Zmod n → α) :=
{ to_fun := λ i v m, v (m + i),
  mul := λ (i j : Zmod n) (v : Zmod n → α), 
    funext (λ m, congr_arg v (add_assoc _ _ _).symm),
  one := λ (v : Zmod n → α), funext (λ m, congr_arg v (add_zero m)) }

lemma fixed_points_F₂_eq_const {n : ℕ} [h0 : Zmod.pos n] {v : Zmod n → G}
  (h : v ∈ fixed_points (F₂ G n)) (i j : Zmod n) : v i = v j :=
calc v i = v (j + i) : add_comm i j ▸ (congr_fun ((mem_fixed_points.1 h _) (mem_orbit (F₂ G n) v j)) i).symm
... = v j : congr_fun ((mem_fixed_points.1 h _) (mem_orbit (F₂ G n) v i)) j

lemma map_succ_range : ∀ n : ℕ, list.range (nat.succ n) = 0 :: (list.range n).map nat.succ
| 0 := rfl
| (n+1) := by rw [list.range_concat, list.range_concat, list.map_append,
  ← list.cons_append, ← map_succ_range, list.range_concat, list.map_singleton]

open nat

lemma list.prod_const [monoid α] : ∀ {l : list α} {a : α}, (∀ b ∈ l, b = a) → l.prod = a ^ l.length
| [] := λ _ _, rfl
| (b::l) := λ a ha,
have h : ∀ b ∈ l, b = a := λ b hb, ha b (list.mem_cons_of_mem _ hb),
have hb : b = a := ha b (list.mem_cons_self _ _),
by simp [_root_.pow_add, list.prod_const h, hb]

lemma F₂_on_Gstar {n : ℕ} [h0 : Zmod.pos n] {v : Zmod (succ n) → G}
  (hv : v ∈ Gstar G (succ n)) (i : Zmod (succ n)) :
  (F₂ G (succ n)) (i : Zmod (succ n)) v ∈ Gstar G (succ n) :=
begin
  cases i with i hi,
  rw Zmod.mk_eq_cast,
  clear hi,
  induction i with i ih,
  { show list.prod (list.map (λ (m : ℕ), v (m + 0)) (list.range (succ n))) = 1,
    simpa },
  { show list.prod (list.map (λ (m : ℕ), v (m + (i + 1))) (list.range (succ n))) = 1,
    replace ih : list.prod (list.map (λ (m : ℕ), v (m + i)) (list.range (succ n))) = 1 := ih, 
    rw [list.range_concat, list.map_append, list.prod_append, list.map_singleton, 
      list.prod_cons, list.prod_nil, mul_one] at ⊢ ih,
    have h : list.map (λ m : ℕ, v (↑m + (i + 1))) (list.range n) =
      list.map (λ m : ℕ, v (m + i)) (list.map (λ m : ℕ, m + 1) (list.range n)),
    { simp [list.map_map, function.comp] },
    resetI,
    cases n,
    { exact (lt_irrefl 0 h0.pos).elim },
    { have h : list.map (λ m : ℕ, v (↑m + (i + 1))) (list.range n) =
        list.map (λ m : ℕ, v (m + i)) (list.map succ (list.range n)),
      { simp [list.map_map, function.comp] },
      have h₁ : (succ n : Zmod (succ (succ n))) + (↑i + 1) = i,
      { rw [add_left_comm, ← nat.cast_one, ← nat.cast_add, Zmod.cast_self_eq_zero, add_zero] },
      have h₂ : (n : Zmod (succ (succ n))) + i + 1 = succ n + i := by simp [succ_eq_add_one],
      rw [map_succ_range, list.map_cons, list.prod_cons, ← h, nat.cast_zero, zero_add] at ih,
      have := eq_inv_mul_of_mul_eq ih,
      rw [list.range_concat, list.map_append, list.map_singleton, list.prod_append,
        list.prod_cons, list.prod_nil, mul_one, ← add_assoc, h₁, h₂, this],
      simp } }
end

def F₂Gstar (G : Type u) [group G] (n : ℕ) [Zmod.pos n] : 
  group_action (multiplicative (Zmod (succ n))) (Gstar G (succ n)) :=
restriction (λ v, F₂_on_Gstar)

lemma fixed_points_F₂_pow_n [fintype G] {n : ℕ} (hn : nat.prime (succ n))
  [h0 : Zmod.pos n]
  {v : Gstar G (succ n)}
  (hv : v ∈ fixed_points (F₂Gstar G n)) : (v : Zmod (succ n) → G) 0 ^ (n + 1) = 1 :=
let ⟨w, hw⟩ := (mem_Gstar_iff _).1 v.2 in
have hv' : (v : Zmod (succ n) → G) ∈ _ := ((fixed_points_restriction _).1 hv),
begin
  have h₁ : dite _ _ _ = (v : Zmod (succ n) → G) _ := congr_fun hw.2 ⟨n, nat.lt_succ_self n⟩,
  rw dif_neg (lt_irrefl _) at h₁,
  have h₂ : ∀ b, b < n → w b = (v : Zmod (succ n) → G) b := λ b hb, begin
    have : dite _ _ _ = _ := congr_fun hw.2 b,
    rwa [Zmod.cast_val_of_lt (lt_succ_of_lt hb), dif_pos hb] at this,
  end,
  have hb : ∀ (b : G), b ∈ list.map (λ (m : ℕ), w ↑m) (list.range n) → b = w 0 := λ b hb,
    let ⟨i, hi⟩ := list.mem_map.1 hb in
    by rw [← hi.2, h₂ _ (list.mem_range.1 hi.1), fixed_points_F₂_eq_const 
      ((fixed_points_restriction _).1 hv) _ 0];
      exact (h₂ 0 h0.pos).symm,
  refine (@mul_left_inj _ _ (w 0 ^ (-n : ℤ)) _ _).1 _,
  rw [@list.prod_const _ _ _ (w 0) hb, list.length_map, list.length_range, ← gpow_coe_nat, ← gpow_neg] at h₁,
  conv { to_rhs, rw [h₁, fixed_points_F₂_eq_const hv' _ 0] },
  rw [← nat.cast_zero, h₂ 0 h0.pos, nat.cast_zero, ← gpow_coe_nat, ← gpow_add, int.coe_nat_add],
  simp,
end

lemma one_mem_fixed_points_F₂ [fintype G] {n : ℕ} [h0 : Zmod.pos n] :
  (1 : Zmod n → G) ∈ fixed_points (F₂ G n) :=
mem_fixed_points.2 (λ y hy, funext (λ j,
  let ⟨i, hi⟩ := mem_orbit_iff.1 hy in
  have hj : (1 : G) = y j := congr_fun hi j,
    hj ▸ rfl))

lemma one_mem_Gstar (n : ℕ) [Zmod.pos n] : (1 : Zmod n → G) ∈ Gstar G n :=
show list.prod (list.map (λ (m : ℕ), (1 : G)) (list.range n)) = 1,
from have h : ∀ b : G, b ∈ list.map (λ (m : ℕ), (1 : G)) (list.range n) → b = 1 :=
λ b hb, let ⟨_, h⟩ := list.mem_map.1 hb in h.2.symm,
by simp [list.prod_const h]

attribute [trans] dvd.trans

lemma exists_prime_order_of_dvd_card [fintype G] {p : ℕ} (hp : nat.prime p)
  (hdvd : p ∣ card G) : ∃ x : G, order_of x = p :=
let n := p - 1 in
have hn : p = n + 1 := nat.succ_sub hp.pos,
have hnp : nat.prime (n + 1) := hn ▸ hp,
have hn0 : Zmod.pos n := ⟨nat.lt_of_succ_lt_succ hnp.gt_one⟩,
have hlt : ¬(n : Zmod (n + 1)).val < n :=
  not_lt_of_ge (by rw [Zmod.cast_val, nat.mod_eq_of_lt (nat.lt_succ_self _)]; 
    exact le_refl _),
have hcard1 : card (Gstar G (n + 1)) = card (Zmod n → G) := 
  by rw [← set.card_univ (Zmod n → G), set.ext (@mem_Gstar_iff _ _ _ hn0), 
    set.card_image_of_injective _ F₁_injective],
have hcard : card (Gstar G (n + 1)) = card G ^ n :=
  by conv { rw hcard1, to_rhs, rw ← card_fin n };
    exact fintype.card_fun,
have hZmod : @fintype.card (multiplicative (Zmod (n+1))) (fin.fintype _) = 
  (n+1) ^ 1 := (nat.pow_one (n + 1)).symm ▸ card_fin _,
have hmodeq : _ = _ := mpl hnp hZmod (@F₂Gstar G _ n hn0),
have hdvdcard : (n + 1) ∣ card (Gstar G (n + 1)) :=
  calc (n + 1) = p : hn.symm
  ... ∣ card G ^ 1 : by rwa nat.pow_one
  ... ∣ card G ^ n : nat.pow_dvd_pow _ hn0.pos
  ... = card (Gstar G (n + 1)) : hcard.symm,
have hdvdcard₂ : (n + 1) ∣ card (fixed_points (@F₂Gstar G _ n hn0)) :=
  nat.dvd_of_mod_eq_zero (hmodeq ▸ (nat.mod_eq_zero_of_dvd hdvdcard)),
have hcard_pos : 0 < card (fixed_points (@F₂Gstar G _ n hn0)) :=
  fintype.card_pos_iff.2 ⟨⟨⟨(1 : Zmod (succ n) → G), one_mem_Gstar _⟩, 
    (fixed_points_restriction _).2 (one_mem_fixed_points_F₂)⟩⟩,
have hle : 1 < card (fixed_points (@F₂Gstar G _ n hn0)) :=
  calc 1 < n + 1 : hnp.gt_one
  ... ≤ _ : nat.le_of_dvd hcard_pos hdvdcard₂,
let ⟨⟨x, hx₁⟩, hx₂⟩ := classical.not_forall.1 (mt fintype.card_le_one_iff.2 (not_le_of_gt hle)) in
let ⟨⟨y, hy₁⟩, hy₂⟩ := classical.not_forall.1 hx₂ in
have hxy : (x : Zmod (succ n) → G) 0 ≠ 1 ∨ (y : Zmod (succ n) → G) 0 ≠ 1 := 
  or_iff_not_imp_left.2 
  (λ hx1 hy1, hy₂ (subtype.eq (subtype.eq (funext (λ i, 
  show (x : Zmod (succ n) → G) i = (y : Zmod (succ n) → G) i,
  by rw [fixed_points_F₂_eq_const ((fixed_points_restriction _).1 hy₁) i 0, hy1,
        fixed_points_F₂_eq_const ((fixed_points_restriction _).1 hx₁) i 0, not_not.1 hx1]))))),
have hxp : (x : Zmod (succ n) → G) 0 ^ (n + 1) = 1 := @fixed_points_F₂_pow_n _ _ _ _ hnp hn0 _ hx₁,
have hyp : (y : Zmod (succ n) → G) 0 ^ (n + 1) = 1 := @fixed_points_F₂_pow_n _ _ _ _ hnp hn0 _ hy₁,
begin
  rw hn,
  cases hxy with hx hy,
  { existsi (x : Zmod (succ n) → G) 0,
    exact or.resolve_left (hnp.2 _ (order_of_dvd_of_pow_eq_one hxp)) 
      (λ h, hx (eq_one_of_order_of_eq_one h)) },
  { existsi (y : Zmod (succ n) → G) 0,
    exact or.resolve_left (hnp.2 _ (order_of_dvd_of_pow_eq_one hyp)) 
      (λ h, hy (eq_one_of_order_of_eq_one h)) }
end

local attribute [instance] left_rel set_fintype
open is_subgroup is_submonoid is_group_hom

def thing (H : set G) [is_subgroup H] : group_action H (left_cosets H) :=
{ to_fun := λ x y, quotient.lift_on y (λ y, ⟦(x : G) * y⟧) 
  (λ a b (hab : _ ∈ H), quotient.sound 
    (show _ ∈ H, by rwa [mul_inv_rev, ← mul_assoc, mul_assoc (a⁻¹), inv_mul_self, mul_one])),
  one := λ a, quotient.induction_on a (λ a, quotient.sound (show (1 : G) * a ≈ a, by simp)),
  mul := λ x y a, quotient.induction_on a (λ a, quotient.sound (by rw ← mul_assoc; refl)) }


def thing2 (L₁ L₂ : set G) [is_subgroup L₂] [is_subgroup L₁] : group_action L₂ (left_cosets L₁) :=
{ to_fun := λ x y, quotient.lift_on y (λ y, ⟦(x : G) * y⟧) 
  (λ a b (hab : _ ∈ L₁), quotient.sound 
    (show _ ∈ L₁, by rwa [mul_inv_rev, ← mul_assoc, mul_assoc (a⁻¹), inv_mul_self, mul_one])),
  one := λ a, quotient.induction_on a (λ a, quotient.sound (show (1 : G) * a ≈ a, by simp)),
  mul := λ x y a, quotient.induction_on a (λ a, quotient.sound (by rw ← mul_assoc; refl)) }

lemma mem_fixed_points_thing_iff_mem_normalizer {H : set G} [is_subgroup H] [fintype H]
  {x : G} : ⟦x⟧ ∈ fixed_points (thing H) ↔ x ∈ normalizer H := 
⟨λ hx, have ha : ∀ {y : left_cosets H}, y ∈ orbit (thing H) ⟦x⟧ → y = ⟦x⟧ := λ _, 
    (mem_fixed_points.1 hx _),
  (inv_mem_iff _).1 (mem_normalizer_fintype_iff.2 (λ n hn,
    have (n⁻¹ * x)⁻¹ * x ∈ H := quotient.exact (ha (mem_orbit (thing H) _ 
      ⟨n⁻¹, inv_mem hn⟩)),
    by simpa only [mul_inv_rev, inv_inv] using this)),
λ (hx : ∀ (n : G), n ∈ H ↔ x * n * x⁻¹ ∈ H), 
mem_fixed_points.2 $ λ y, quotient.induction_on y $ λ y hy, quotient.sound 
  (let ⟨⟨b, hb₁⟩, hb₂⟩ := hy in 
  have hb₂ : (b * x)⁻¹ * y ∈ H := quotient.exact hb₂,
  (inv_mem_iff H).1 $ (hx _).2 $ (mul_mem_cancel_right H (inv_mem hb₁)).1
  $ by rw hx at hb₂;
    simpa [mul_inv_rev, mul_assoc] using hb₂)⟩

lemma fixed_points_thing_equiv_cosets (H : set G) [is_subgroup H] [fintype H] :
  fixed_points (thing H) ≃ left_cosets {x : normalizer H | ↑x ∈ H} :=
{ to_fun := λ a, quotient.hrec_on a.1 (λ a ha, @quotient.mk _
  (left_rel {x : normalizer H | ↑x ∈ H}) ⟨a, mem_fixed_points_thing_iff_mem_normalizer.1 ha⟩)
    (λ x y hxy, function.hfunext (by rw quotient.sound hxy)
      (λ hx hy _, heq_of_eq (@quotient.sound _ (left_rel {x : normalizer H | ↑x ∈ H})
        _ _ (by exact hxy)))) a.2,
  inv_fun := λ x, ⟨@quotient.lift_on _ _ (left_rel {x : normalizer H | ↑x ∈ H}) x
    (λ x, show fixed_points (thing H),
      from ⟨⟦x⟧, mem_fixed_points_thing_iff_mem_normalizer.2 x.2⟩)
    (λ ⟨x, hx⟩ ⟨y, hy⟩ (hxy : x⁻¹ * y ∈ H), subtype.eq (quotient.sound hxy)),
    (@quotient.induction_on _  (left_rel {x : normalizer H | ↑x ∈ H}) _ x
      (by intro x; cases x with x hx;
        exact mem_fixed_points_thing_iff_mem_normalizer.2 hx))⟩,
  left_inv := λ ⟨x, hx⟩, by revert hx;
    exact quotient.induction_on x (by intros; refl),
  right_inv := λ x, @quotient.induction_on _
    (left_rel {x : normalizer H | ↑x ∈ H}) _ x
      (by intro x; cases x; refl) }

lemma sylow1 [fintype G] {p : ℕ} : ∀ {n : ℕ} (hp : nat.prime p)
  (hdvd : p ^ n ∣ card G), ∃ H : set G, is_subgroup H ∧ card H = p ^ n
| 0 := λ _ _, ⟨trivial G, by apply_instance, by simp [-set.set_coe_eq_subtype]⟩
| (n+1) := λ hp hdvd,
let ⟨H, ⟨hH1, hH2⟩⟩ := sylow1 hp (dvd.trans (pow_dvd_pow _ (le_succ _)) hdvd) in
let ⟨s, hs⟩ := exists_eq_mul_left_of_dvd hdvd in
by exactI
have hcard : card (left_cosets H) = s * p :=
  (nat.mul_right_inj (show card H > 0, from fintype.card_pos_iff.2 ⟨⟨1, is_submonoid.one_mem H⟩⟩)).1
    (by rwa [← card_eq_card_cosets_mul_card_subgroup, hH2, hs, nat.pow_succ, mul_assoc, mul_comm p]),
have hm : s * p % p = card (left_cosets {x : normalizer H | ↑x ∈ H}) % p :=
  card_congr (fixed_points_thing_equiv_cosets H) ▸ hcard ▸ mpl hp hH2 (thing H),
have hm' : p ∣ card (left_cosets {x : normalizer H | ↑x ∈ H}) :=
  nat.dvd_of_mod_eq_zero
    (by rwa [nat.mod_eq_zero_of_dvd (dvd_mul_left _ _), eq_comm] at hm),
let ⟨x, hx⟩ := exists_prime_order_of_dvd_card hp hm' in
have hxcard : card (gpowers x) = p := by rwa ← order_eq_card_gpowers,
let S : set ↥(normalizer H) := set.preimage (@quotient.mk _
    (left_rel {x : ↥(normalizer H) | ↑x ∈ H}))
      (@gpowers (left_cosets {x : ↥(normalizer H) | ↑x ∈ H}) _ x) in
have is_subgroup S := @is_group_hom.preimage _
  (left_cosets {x : ↥(normalizer H) | ↑x ∈ H}) _ _ _ _ _ _,
have fS : fintype S := by apply_instance,
let hequiv : {x : ↥(normalizer H) | ↑x ∈ H} ≃ H :=
  { to_fun := λ ⟨x, hx⟩, ⟨x, hx⟩,
    inv_fun := λ ⟨x, hx⟩, ⟨⟨x, subset_normalizer _ hx⟩, hx⟩,
    left_inv := λ ⟨⟨_, _⟩, _⟩, rfl,
    right_inv := λ ⟨_, _⟩, rfl } in
⟨subtype.val '' S, by apply_instance,
by dsimp only [S];
  rw [set.card_image_of_injective _ subtype.val_injective, nat.pow_succ,
    @card_congr _ _ fS _ (preimage_quotient_mk_equiv_subgroup_times_set _ _),
    card_prod, hxcard, ← hH2, card_congr hequiv]⟩

def conjugate_set (G : Type u) [group G] : group_action G (set G) :=
{ to_fun := λ x H, {n | x⁻¹ * n * x ∈ H},
  one := λ H, by simp,
  mul := λ x y H, by simp [mul_inv_rev, mul_assoc, function.comp] }

lemma conjugate_set_eq_image (H : set G) (x : G) : 
  conjugate_set G x H = (λ n, x * n * x⁻¹) '' H :=
set.ext (λ n, ⟨λ h, ⟨x⁻¹ * n * x, h, by simp [mul_assoc]⟩,
  λ ⟨a, ha⟩, show x⁻¹ * n * x ∈ H, from ha.2 ▸ by simp [ha.1, mul_assoc]⟩)

lemma mem_conjugate_set {H : set G} {x n : G} :
  n ∈ conjugate_set G x H ↔ x⁻¹ * n * x ∈ H := iff.rfl

lemma conj_inj_left {x : G} : function.injective (λ (n : G), x * n * x⁻¹) :=
λ a b h, (mul_left_inj x).1 $ (mul_right_inj (x⁻¹)).1 h

instance is_group_hom_conj (x : G) : is_group_hom (λ (n : G), x * n * x⁻¹) :=
⟨by simp [mul_assoc]⟩

instance is_subgroup_conj (x : G) (H : set G) [is_subgroup H] :
  is_subgroup (conjugate_set G x H) := 
by rw conjugate_set_eq_image; apply_instance

/-- dlogn p a gives the value of n such that p ^ n ∣ a -/
def dlogn (p : ℕ) : ℕ → ℕ
| 0     := 0
| (a+1) := if h : p > 1 then
  have (a + 1) / p < a + 1, from div_lt_self dec_trivial h,
    if p ∣ (a + 1) then dlogn ((a + 1) / p) + 1 else 0
  else 0

lemma dlogn_dvd {p : ℕ} : ∀ a, p > 1 → p ^ dlogn p a ∣ a
| 0     := λ _, dvd_zero _
| (a+1) := λ h,
have (a + 1) / p < a + 1, from div_lt_self dec_trivial h,
begin
  rw [dlogn, if_pos h],
  split_ifs,
  { rw [nat.pow_succ],
    conv {to_rhs, rw ← nat.div_mul_cancel h_1},
    exact mul_dvd_mul (dlogn_dvd _ h) (dvd_refl _) },
  { simp }
end

lemma not_dvd_div_dlogn {p : ℕ} : ∀ {a}, a > 0 → p > 1 → ¬p ∣ a / (p ^ dlogn p a)
| 0     := λ h, (lt_irrefl _ h).elim
| (a+1) := λ h hp hd,
have (a + 1) / p < a + 1, from div_lt_self dec_trivial hp,
begin
  rw [dlogn, if_pos hp] at hd,
  split_ifs at hd,
  { have := @not_dvd_div_dlogn ((a + 1) / p)
      (pos_of_mul_pos_left (by rw nat.mul_div_cancel' h_1; exact nat.succ_pos _) (nat.zero_le p)) hp,
    rw [nat.div_div_eq_div_mul, mul_comm, ← nat.pow_succ] at this,
    contradiction },
  { simpa using hd }
end

class is_sylow [fintype G] (H : set G) {p : ℕ} (hp : prime p) extends is_subgroup H : Prop := 
(card_eq : card H = p ^ dlogn p (card G))

lemma exists_sylow_p_subgroup (G : Type u) [group G] [fintype G] {p : ℕ} (hp : prime p) : 
  ∃ H : set G, is_sylow H hp := 
let ⟨H, ⟨hH₁, hH₂⟩⟩ := sylow1 hp (dlogn_dvd (card G) hp.gt_one) in
by exactI ⟨H, by split; assumption⟩

lemma card_sylow [fintype G] (H : set G) {p : ℕ} (hp : prime p) [is_sylow H hp] : card H = p ^ dlogn p (card G) := 
is_sylow.card_eq _ hp

lemma sylow2 [fintype G] {p : ℕ} (hp : nat.prime p)
  (L₁ L₂ : set G) [is_sylow L₂ hp] [is_sylow L₁ hp] :
  ∃ x : G, L₂ = conjugate_set G x L₁ :=
have hs : card (left_cosets L₁) = card G / (p ^ dlogn p (card G)) := 
  (nat.mul_right_inj (pos_pow_of_pos (dlogn p (card G)) hp.pos)).1
  $ by rw [← card_sylow L₁ hp, ← card_eq_card_cosets_mul_card_subgroup, card_sylow L₁ hp, 
    nat.div_mul_cancel (dlogn_dvd _ hp.gt_one)],
have hmodeq : card G / (p ^ dlogn p (card G)) ≡ card (fixed_points (thing2 L₁ L₂)) [MOD p] := 
  hs ▸ mpl hp (card_sylow L₂ hp) (thing2 L₁ L₂),
have hfixed : 0 < card (fixed_points (thing2 L₁ L₂)) := nat.pos_of_ne_zero 
  (λ h, (not_dvd_div_dlogn (fintype.card_pos_iff.2 ⟨(1 : G)⟩) hp.gt_one) 
  $ by rwa [h, nat.modeq.modeq_zero_iff] at hmodeq),
let ⟨x, hx⟩ := classical.choice $ fintype.card_pos_iff.1 hfixed in
begin
  revert hx,
  refine quotient.induction_on x
    (λ x hx, ⟨x, set.eq_of_card_eq_of_subset _ _⟩),
  { rw [conjugate_set_eq_image, set.card_image_of_injective _ conj_inj_left, card_sylow L₁ hp,
    card_sylow L₂ hp] },
  assume y hy,
  have : (y⁻¹ * x)⁻¹ * x ∈ L₁ := quotient.exact 
    (mem_fixed_points.1 hx ⟦y⁻¹ * x⟧ ⟨⟨y⁻¹, inv_mem hy⟩, rfl⟩),
  simp [mem_conjugate_set, mul_inv_rev, *, mul_assoc] at *
end

def conj_on_sylow [fintype G] {p : ℕ} (hp : nat.prime p) :
  group_action G {H : set G // is_sylow H hp} :=
{ to_fun := λ x ⟨H, hH⟩, ⟨conjugate_set G x H, by exactI
  have h : is_subgroup (conjugate_set G x H) := sylow.is_subgroup_conj _ _,
  { card_eq := by exactI by
    rw [← card_sylow H hp, conjugate_set_eq_image, set.card_image_of_injective _ conj_inj_left], 
    ..h }⟩,
  one := λ ⟨H, hH⟩, by simp!,
  mul := λ x y ⟨H, hH⟩, by simp! [mul_inv_rev, mul_assoc, function.comp, 
      conjugate_set_eq_image, (set.image_comp _ _ _).symm] }

lemma sylow3 [fintype G] {p : ℕ} (hp : nat.prime p) : 
  card {H : set G // is_sylow H hp} ∣ card G :=
let ⟨H, hH⟩ := exists_sylow_p_subgroup G hp in
have h : orbit (conj_on_sylow hp) ⟨H, hH⟩ = set.univ := 
  set.eq_univ_iff_forall.2 (λ S, mem_orbit_iff.2 $ 
  let ⟨x, (hx : S.val = _)⟩ := @sylow2 _ _ _ _ hp H S S.2 hH in
  ⟨x, subtype.eq (hx.symm ▸ rfl)⟩),
have orbit_equiv : card (orbit (conj_on_sylow hp) ⟨H, hH⟩) = 
  card (left_cosets (stabilizer (conj_on_sylow hp) ⟨H, hH⟩)) :=
   card_congr (orbit_equiv_left_cosets (⟨H, hH⟩ : {H : set G // is_sylow H hp}) (conj_on_sylow hp)),
by exactI begin
  rw [h, ← card_congr (set.equiv_univ _)] at orbit_equiv,
  rw [orbit_equiv, card_congr (@group_equiv_left_cosets_times_subgroup _ _ 
    (stabilizer (conj_on_sylow hp) ⟨H, hH⟩) (by apply_instance)), card_prod],
  exact dvd_mul_right _ _
end

lemma sylow3_part2 [fintype G] {p : ℕ} (hp : nat.prime p) : 
  card {H : set G // is_sylow H hp} ≡ 1 [MOD p] :=
let ⟨H, hH⟩ := exists_sylow_p_subgroup G hp in
have h : orbit (conj_on_sylow hp) ⟨H, hH⟩ = set.univ := 
  set.eq_univ_iff_forall.2 (λ S, mem_orbit_iff.2 $ 
  let ⟨x, (hx : S.val = _)⟩ := @sylow2 _ _ _ _ hp H S S.2 hH in
  ⟨x, subtype.eq (hx.symm ▸ rfl)⟩),
by exactI
begin
  have : _ % p = _ := mpl hp (card_sylow H hp) (conj_on_sylow hp),
  show _ = _,
  refine ((eq.trans _) this).trans _,
  congr,

end

end sylow