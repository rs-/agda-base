{-# OPTIONS --without-K #-}

module m where

open import level
open import sum
open import equality.core
open import equality.calculus
open import function.core
open import function.extensionality

infix 1000 ♯_

postulate
  ∞  : ∀ {a} (A : Set a) → Set a
  ♯_ : ∀ {a} {A : Set a} → A → ∞ A
  ♭  : ∀ {a} {A : Set a} → ∞ A → A

{-# BUILTIN INFINITY ∞  #-}
{-# BUILTIN SHARP    ♯_ #-}
{-# BUILTIN FLAT     ♭  #-}

module Definition (I : Set)
                  (A : I → Set)
                  (B : {i : I} → A i → Set)
                  (r : {i : I}{a : A i} → B a → I) where

  -- functor associated to this indexed container
  F : (I → Set) → I → Set
  F X i = Σ (A i) λ a → (b : B a) → X (r b)

  -- homsets in the slice category
  _↝_ : (X Y : I → Set) → Set
  X ↝ Y = {i : I} → X i → Y i

  -- morphism map for the functor F
  imap : (X : I → Set)
       → {Y : I → Set}
       → (X ↝ Y)
       → (F X ↝ F Y)
  imap _ g {i} (a , f) = a , g ∘ f

  -- definition of indexed M-types using native Agda coinduction
  data M (i : I) : Set where
    inf : (a : A i) → ((b : B a) → ∞ (M (r b))) → M i

  -- the terminal coalgebra
  out : M ↝ F M
  out (inf a f) = a , ♭ ∘ f

  -- normally, the constructor can be defined in terms of out and unfold, but
  -- Agda provides it natively, together with a definitional β rule
  inM' : F M ↝ M
  inM' (a , f) = inf a (λ x → ♯ (f x))

  inM'-β : {i : I}(x : F M i) → out (inM' x) ≡ x
  inM'-β x = refl

  module Elim {X : I → Set}
              (α : X ↝ F X) where
    -- anamorphisms
    unfold : X ↝ M
    unfold {i} x = inf a f
      where
        u : F X i
        u = α x

        a : A i
        a = proj₁ u

        f : (b : B a) → ∞ (M (r b))
        f b = ♯ unfold (proj₂ u b)

    -- computational rule for anamorphisms
    -- this holds definitionally
    unfold-β : {i : I}(x : X i)
             → out (unfold x) ≡ imap X unfold (α x)
    unfold-β x = refl

    -- the corresponding η rule doesn't hold, so we postulate it
    postulate
      unfold-η : (h : X ↝ M)
               → (∀ {i} (x : X i) → out (h x) ≡ imap X h (α x))
               → ∀ {i} (x : X i) → h x ≡ unfold x
  open Elim

  -- using η, we can prove that the unfolding of out is the identity
  unfold-id : ∀ {i} (x : M i) → unfold out x ≡ x
  unfold-id x = sym (unfold-η out id (λ _ → refl) x)

  -- the usual definition of the constructor
  inM : F M ↝ M
  inM = unfold (imap M out)

  -- the constructor is the inverse of the destructor
  inM-η : ∀ {i} (x : M i) → inM (out x) ≡ x
  inM-η x = unfold-η out (inM ∘ out) (λ _ → refl) x ⊚ unfold-id x

  inM-β : ∀ {i} (x : F M i) → out (inM x) ≡ x
  inM-β {i} x = cong u (impl-ext' (λ i → ext' inM-η))
    where
      u : (M ↝ M) → F M i
      u h = imap M h {i} x

  -- now we can prove that the constructor provided by Agda is equal to the
  -- usual one
  inM-alt : ∀ {i} (x : F M i) → inM' x ≡ inM x
  inM-alt x = sym (inM-η (inM' x))
open Definition