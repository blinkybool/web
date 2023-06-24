---
layout: page
title: Translating Sentences to Predicate Logic
date: August 31, 2020
katex: True
---

# Translating Sentences to Predicate Logic
**Author**: *Billy Price*



$$\text{"Crows are black"}$$

The first step is to write down any predicates that might seem useful in translating.

> How about a zero-place predicate $P$, which means "crows are black"?

Sure, this is what we do in propositional logic, but in doing that, we have no direct way of relating it to another proposition like "Fred is a crow", since all we have is $P$. Most often we will be writing one or two place predicates, so try to find simple assertions about a one or two objects. Sensible choices here would be

  $$C(x): x \text{ is a crow} \\ B(x): x \text{ is black}$$

Now at this point we are able to translate things like "Fred is a crow" to $C(Fred)$, since we have something of the form "\_\_ $\text{ is a crow}$". This is not the case for "crows are black". Since there is no particular thing whose "crowness" or "blackness" is being discussed, it is safe to assume we either have an existential statement "there is at least one thing with this property" or a universal statement "all things have this property". Let's revisit the statement with these two situations emphasised.

  $$\text{"All crows are black"} \\ \text{"Some crows are black"}$$

As English speakers, it seems fairer to say that "All crows are black" is what we mean when we say "Crows are black", rather than "Some crows are black", which is clearly a different (weaker) claim.

Now we just have to come up with a formula $\varphi$ which says something about an arbitrary object $x$, so that $\forall x~ \varphi$ *means* "All crows are black". It would make sense for us to use atomic formulas like $C(x)$ and $B(x)$, where $x$ is the variable being universally quantified. Here are the two most common guesses.

1. $\forall x~ (C(x) \wedge B(x))$
2. $\forall x~ (C(x) \Rightarrow B(x))$

A motivation for the first formula, or something like it, is that we're just talking about crows, so perhaps we aren't interested in domains where there are non-crow things. However it would be perfectly sensible to make a statement like "All crows are black" in some context which does have non-crow things. In such a context, even if all the crows are black, this formula would be false, since there will be some object $a$ with $C(a)$ false, and therefore $C(a) \wedge B(a)$ is false, so $\forall x~ (C(x) \wedge B(x)$ is false (with counterexample $a$).

On the other hand, the second formula, using the implication, does behave well in these contexts. Any object which isn't a crow will satisfy $C(x) \Rightarrow B(x)$ by failing the premise (we purposely make the non-crow things trivially satisfy the formula). More importantly, every object $x$ which *is* a crow **must** also be black in order to make $C(x) \Rightarrow B(x)$ true.

By putting things in the premise of the implication, we restrict the kinds of things we want to make an assertion about. We make the statement "Everything which is a crow is black", by saying "For all things, if it's a crow then it's black".

----

So what about $\text{"Some crows are black"}$? Here we opt for existential quantification - that is, we will say "there exists at least one thing with this property". You might argue that the statement is really asserting something like "at least a few crows are black", but unfortunately we don't have the machinery yet to say *exactly* that kind of thing.

> So how about $\exists x~(C(x) \Rightarrow B(x))$, using the same trick as before to restrict our attention to crows?

Unfortunately a translation like this has disastrous consequences! The problem is that it is now *too easy* to satisfy it. Suppose you have a domain with an object $a$ which isn't a crow, that is $C(a)$ is false. Then $C(a) \Rightarrow B(a)$ is true, so $\exists x~(C(x) \Rightarrow B(x))$ is true - but we haven't even checked yet if the domain has a crow which is black! It may or may not have one, and this has no influence on the truth of $\exists x~(C(x) \Rightarrow B(x))$.

What we actually need is the conjunction statement, $\exists x~(C(x) \wedge B(x))$, which clearly asserts "there is a thing which is a crow and is black". Now, the existence of non-crow things in the domain has no influence on the truth of the formula, and the only way to satisfy it is to have a thing which is both a crow and is black.

## Conclusion

When translating sentences to predicate logic, more often than not, **universal quantification, $\forall$, is paired with an implication, $\Rightarrow$**, and **existential quantification, $\exists$, is paired with a conjunction, $\wedge$**. Beware the strength of the statement $\forall x~ (P(x) \wedge Q(x))$ (it might be *less often* true than you intend) and the weakness of the statement $\exists x~ (P(x) \Rightarrow Q(x))$ (it might be *more often* true than you intend).

