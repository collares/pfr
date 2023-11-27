import PFR.f2_vec
import PFR.first_estimate
import PFR.second_estimate

/-!
# Endgame

The endgame on tau-minimizers.

Assumptions:

* $X_1, X_2$ are tau-minimizers
* $X_1, X_2, \tilde X_1, \tilde X_2$ be independent random variables, with $X_1,\tilde X_1$ copies of $X_1$ and $X_2,\tilde X_2$ copies of $X_2$.
* $d[X_1;X_2] = k$
* $U := X_1 + X_2$
* $V := \tilde X_1 + X_2$
* $W := X_1 + \tilde X_1$
* $S := X_1 + X_2 + \tilde X_1 + \tilde X_2$.
* $I_1 := I[ U : V | S ]$
* $I_2 := I[ U : W | S ]$
* $I_3 := I[ V : W | S ]$ (not explicitly defined in Lean)

# Main results:

* `sum_condMutual_le` : An upper bound on the total conditional mutual information $I_1+I_2+I_3$.
* `sum_dist_diff_le`: A sum of the "costs" of $U$, $V$, $W$.
* `construct_good`: A construction of two random variables with small Ruzsa distance between them given some random variables with control on total cost, as well as total mutual information.
-/

universe u

open MeasureTheory ProbabilityTheory

open scoped BigOperators

variable {G : Type u} [addgroup: AddCommGroup G] [Fintype G] [hG : MeasurableSpace G]
  [MeasurableSingletonClass G] [elem: ElementaryAddCommGroup G 2] [MeasurableAdd₂ G]

variable {Ω₀₁ Ω₀₂ : Type u} [MeasureSpace Ω₀₁] [MeasureSpace Ω₀₂] [IsProbabilityMeasure (ℙ : Measure Ω₀₁)] [IsProbabilityMeasure (ℙ : Measure Ω₀₂)]

variable (p : refPackage Ω₀₁ Ω₀₂ G)

variable {Ω : Type u} [mΩ : MeasureSpace Ω] [IsProbabilityMeasure (ℙ : Measure Ω)]

variable (X₁ X₂ X₁' X₂' : Ω → G)
  (hX₁ : Measurable X₁) (hX₂ : Measurable X₂) (hX₁' : Measurable X₁') (hX₂' : Measurable X₂')

variable (h₁ : IdentDistrib X₁ X₁') (h₂ : IdentDistrib X₂ X₂')

variable (h_indep : iIndepFun (fun _i => hG) ![X₁, X₂, X₂', X₁'])

variable (h_min: tau_minimizes p X₁ X₂)

local notation3 "k" => d[ X₁ # X₂]

local notation3 "U" => X₁ + X₂

local notation3 "V" => X₁' + X₂

local notation3 "W" => X₁' + X₁

local notation3 "S" => X₁ + X₂ + X₁' + X₂'

local notation3 "I₁" => I[ U : V | S ]

local notation3 "I₂" => I[ U : W | S ]

/-- The quantity $I_3 = I[V:W|S]$ is equal to $I_2$. -/
lemma I₃_eq : I[ V : W | S ] = I₂ := by
  -- Note(kmill): I'm not sure this is going anywhere, but in case some of this reindexing
  -- is useful, and this setting-up of the `I'` function, here it is.
  -- Swap X₁ and X₁'
  let perm : Fin 4 → Fin 4 | 0 => 1 | 1 => 0 | 2 => 2 | 3 => 3
  have hp : ![X₁, X₁', X₂, X₂'] = ![X₁', X₁, X₂, X₂'] ∘ perm := by
    ext i
    fin_cases i <;> rfl
  let I' (Xs : Fin 4 → Ω → G) := I[Xs 0 + Xs 2 : Xs 1 + Xs 0 | Xs 0 + Xs 2 + Xs 1 + Xs 3]
  have hI₂ : I₂ = I' ![X₁, X₁', X₂, X₂'] := rfl
  have hI₃ : I[V : W | S] = I' ![X₁', X₁, X₂, X₂'] := by
    rw [add_comm X₁' X₁]
    congr 1
    change _ = X₁' + X₂ + X₁ + X₂'
    simp [add_assoc, add_left_comm]
  rw [hI₂, hI₃, hp]
  -- ⊢ I' ![X₁', X₁, X₂, X₂'] = I' (![X₁', X₁, X₂, X₂'] ∘ perm)
  sorry

/--
$$ I(U : V | S) + I(V : W | S) + I(W : U | S) $$
is less than or equal to
$$ 6 \eta k - \frac{1 - 5 \eta}{1-\eta} (2 \eta k - I_1).$$
-/
lemma sum_condMutual_le :
    I[ U : V | S ] + I[ V : W | S ] + I[ W : U | S ]
      ≤ 6 * η * k - (1 - 5 * η) / (1 - η) * (2 * η * k - I₁) := by
  have : I[W:U|S] = I₂ := by
    rw [condMutualInformation_comm]
    · exact Measurable.add' hX₁' hX₁
    · exact Measurable.add' hX₁ hX₂
  rw [I₃_eq, this]
  have h₂ := second_estimate X₁ X₂ X₁' X₂'
  have h := add_le_add (add_le_add_left h₂ I₁) h₂
  convert h using 1
  field_simp [η]
  ring

local notation3:max "c[" A " # " B "]" => d[p.X₀₁ # A] - d[p.X₀₁ # X₁] + d[p.X₀₂ # B] - d[p.X₀₂ # X₂]

local notation3:max "c[" A " ; " μ " # " B " ; " μ' "]" => d[p.X₀₁ ; ℙ # A ; μ] - d[p.X₀₁ # X₁] + d[p.X₀₂ ; ℙ # B ; μ'] - d[p.X₀₂ # X₂]

local notation3:max "c[" A " | " B " # " C " | " D "]" => d[p.X₀₁ ; ℙ # A|B ; ℙ] - d[p.X₀₁ # X₁] + d[p.X₀₂ # C|D] - d[p.X₀₂ # X₂]


/--
$$ \sum_{i=1}^2 \sum_{A\in\{U,V,W\}} \big(d[X^0_i;A|S] - d[X^0_i;X_i]\big)$$
is less than or equal to
$$ \leq (6 - 3\eta) k + 3(2 \eta k - I_1).$$
-/
lemma sum_dist_diff_le : c[U|S # U|S] + c[V|S # V|S]  + c[W|S # W|S] ≤ (6 - 3 * η)*k + 3 * (2*η*k - I₁) := by sorry

/-- $U+V+W=0$. -/
lemma sum_uvw_eq_zero : U+V+W = 0 := by
  funext ω
  dsimp
  rw [add_comm (X₁' ω) (X₂ ω)]
  exact @sum_add_sum_add_sum_eq_zero G addgroup elem _ _ _

section construct_good
variable {Ω' : Type u} [MeasureSpace Ω'] [IsProbabilityMeasure (ℙ : Measure Ω')]
variable (T₁ T₂ T₃ : Ω' → G) (hT₁ : Measurable T₁) (hT₂ : Measurable T₂) (hT₃ : Measurable T₃)
  (hT : T₁+T₂+T₃ = 0)

local notation3:max "δ[" μ "]" => I[T₁:T₂ ; μ] + I[T₂:T₃ ; μ] + I[T₃:T₁ ; μ]
local notation3:max "δ" => I[T₁:T₂] + I[T₂:T₃] + I[T₃:T₁]


local notation3:max "ψ[" A " # " B "]" => d[A # B] + η * (c[A # B])

/-- If $T_1, T_2, T_3$ are $G$-valued random variables with $T_1+T_2+T_3=0$ holds identically and
$$ \delta := \sum_{1 \leq i < j \leq 3} I[T_i;T_j]$$
Then there exist random variables $T'_1, T'_2$ such that
$$ d[T'_1;T'_2] + \eta (d[X_1^0;T'_1] - d[X_1^0;X_1]) + \eta(d[X_2^0;T'_2] - d[X_2^0;X_2]) $$
is at most
$$ \delta + \eta ( d[X^0_1;T_1]-d[X^0_1;X_1]) + \eta (d[X^0_2;T_2]-d[X^0_2;X_2]) $$
$$ + \tfrac12 \eta \bbI[T_1:T_3] + \tfrac12 \eta \bbI[T_2:T_3].$$
-/
lemma construct_good_prelim :
    k ≤ δ + η * c[T₁ # T₂] + η * (I[T₁:T₃] + I[T₂:T₃])/2 := by sorry


/-- If $T_1, T_2, T_3$ are $G$-valued random variables with $T_1+T_2+T_3=0$ holds identically and
$$ \delta := \sum_{1 \leq i < j \leq 3} I[T_i;T_j]$$
Then there exist random variables $T'_1, T'_2$ such that
$$ d[T'_1;T'_2] + \eta (d[X_1^0;T'_1] - d[X_1^0;X_1]) + \eta(d[X_2^0;T'_2] - d[X_2^0;X_2]) $$
is at most
$$\delta + \frac{\eta}{3} \biggl( \delta + \sum_{i=1}^2 \sum_{j = 1}^3 (d[X^0_i;T_j] - d[X^0_i; X_i]) \biggr).$$
-/
lemma construct_good :
    k ≤ δ + (η/3) * (δ + c[T₁ # T₁] + c[T₂ # T₂] + c[T₃ # T₃]) := by sorry

lemma construct_good' (μ : Measure Ω'):
    k ≤ δ[μ] + (η/3) * (δ[μ] + c[T₁ ; μ # T₁ ; μ] + c[T₂ ; μ # T₂ ; μ] + c[T₃ ; μ # T₃ ; μ]) := by
  letI : MeasureSpace Ω' := ⟨μ⟩
  apply construct_good p X₁ X₂ T₁ T₂ T₃

lemma cond_c_eq_integral {Y Z : Ω' → G} (hY : Measurable Y) (hZ : Measurable Z) : c[Y | Z # Y | Z] =
    (Measure.map Z ℙ)[fun z => c[Y ; ℙ[|Z ⁻¹' {z}] # Y ; ℙ[|Z ⁻¹' {z}]]] := by
  simp only [integral_eq_sum, smul_sub, smul_add, smul_sub, Finset.sum_sub_distrib, Finset.sum_add_distrib]
  simp_rw[←integral_eq_sum]
  rw[←cond_rdist'_eq_integral _ hY hZ, ←cond_rdist'_eq_integral _ hY hZ, integral_const, integral_const]
  have : IsProbabilityMeasure (Measure.map Z ℙ) := isProbabilityMeasure_map hZ.aemeasurable
  simp

variable {R : Ω' → G} (hR : Measurable R)
local notation3:max "δ'" => I[T₁:T₂|R] + I[T₂:T₃|R] + I[T₃:T₁|R]

lemma delta'_eq_integral : δ' = (Measure.map R ℙ)[fun r => δ[ℙ[|R⁻¹' {r}]]] := by
  simp_rw [condMutualInformation_eq_integral_mutualInformation, integral_eq_sum, smul_add,
    Finset.sum_add_distrib]

lemma cond_construct_good :
    k ≤ δ' + (η/3) * (δ' + c[T₁ | R # T₁ | R] + c[T₂ | R # T₂ | R] + c[T₃ | R # T₃ | R])  := by
  rw[delta'_eq_integral, cond_c_eq_integral _ _ _ hT₁ hR, cond_c_eq_integral _ _ _ hT₂ hR,
    cond_c_eq_integral _ _ _ hT₃ hR]
  simp_rw[integral_eq_sum, ←Finset.sum_add_distrib, ←smul_add, Finset.mul_sum, mul_smul_comm,
    ←Finset.sum_add_distrib, ←smul_add]
  simp_rw[←integral_eq_sum]
  have : IsProbabilityMeasure (Measure.map R ℙ) := isProbabilityMeasure_map (by measurability)
  calc
    k = (Measure.map R ℙ)[fun _r => k] := by
      rw [integral_const]; simp
    _ ≤ _ := ?_
  simp_rw[integral_eq_sum]
  apply Finset.sum_le_sum
  intro r _
  simp_rw [smul_eq_mul]
  gcongr (?_ * ?_)
  · apply rdist_nonneg hX₁ hX₂
  · rfl
  apply construct_good'

end construct_good

/-- If $d[X_1;X_2] > 0$ then  there are $G$-valued random variables $X'_1, X'_2$ such that
Phrased in the contrapositive form for convenience of proof. -/
theorem tau_strictly_decreases_aux : d[X₁ # X₂] = 0 := by
  have hη : η = 1/9 := by rw [η, one_div]
  have h0 := cond_construct_good p X₁ X₂ hX₁ hX₂ U V W (by measurability)
    (by measurability) (by measurability) (show Measurable S by measurability)
  have h1 := sum_condMutual_le X₁ X₂ X₁' X₂' hX₁ hX₂ hX₁'
  have h4 := sum_dist_diff_le p X₁ X₂ X₁' X₂'
  have h : I₁ ≤ 2*η*k := first_estimate p X₁ X₂ X₁' X₂' hX₁ hX₂ hX₁' hX₂' h₁ h₂ h_indep h_min

  have : (1-5*η)/(1-η)*(1+η/3)-η = 11/27 := by
    rw [hη]; norm_num

  have h : k ≤ (8*η + η^2) * k := calc
    k ≤ (1+η/3) * (6*η*k - (1-5*η) / (1-η) * (2*η*k - I₁)) + η/3*((6-3*η)*k + 3*(2*η*k-I₁)) := by
      rw[hη] at *
      linarith
    _ = (8*η+η^2)*k - ((1-5*η)/(1-η)*(1+η/3)-η)*(2*η*k-I₁) := by
      ring
    _ ≤ (8*η + η^2) * k := by
      rw[hη] at *
      norm_num
      linarith

  have : 0 ≤ k := rdist_nonneg hX₁ hX₂
  rw[hη] at *
  linarith
