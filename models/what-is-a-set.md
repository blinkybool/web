---
layout: page
title: What is a Set?
date: August 22, 2020
katex: True
---
[← Models of Computation Notes](../models.md)

# What *is* a Set?
**Author**: Billy Price


What is a set? A computer scientist might tell you its a kind of collection data-type, perhaps a list, with two special features:
* The order of elements doesn't matter.
* Each element appears at most once in any set - OR - adding the same element multiple times doesn't change what the set *is*.

Perhaps the data type should also be expected to check if something is in the set with reasonable efficiency.
This leads to an expectation of work required to maintain the set when adding, removing and inspecting elements of the set.

You might wonder how this fits into the *logic* treatment of sets.
* Must the elements of the set be orderable in order to have a set?
* Does this re-ordering and duplicate-element-removal happen magically?
* Are we allowed to have infinite sets? Why?

## What a set actually is

The view we will take is that the *only* thing important about a set is the elementhood test, that is, a set, $A$, is *whatever you want*, as long as, given any *object*, $x$, we can answer true or false to the statement $x \in A$ ($x$ is an element of $A$). In fact, its best to just think of the data of a set as the elementhood test itself, i.e. a one-place-predicate, in the sense that there is nothing more that defines it. In the opposite direction, we can think of any one-place-predicate, $P(x)$, as a set, but to dress it up we use this **set-comprehension** syntax,
  
$$\{x \mid P(x) \}$$

i.e., "the set of all $x$ such that $P(x)$". Despite this description, there is no actual obligation to gather all of these elements into some collection. We just have a thing which becomes the predicate that it holds when called on by the $\in$ symbol. So when we posit a statement like

$$y \in \{ x \mid P(x)\}$$

we're actually just saying $P(y)$.

Given an anonymous set, $A$, you might imagine $A$ to secretly have the form $\{x \mid P(x)\}$ for some predicate $P(x)$. Of course $P(x)$ must always agree with $x \in A$, so we can bring this full circle by saying:

$$A = \{x \mid x \in A\}$$

## Set equality and subset

This view on sets as predicates motivates what it means for two sets to be equal - it just means that their associated one-place-predicates (unary predicates) are the same. So given two predicates $P(x)$ and $Q(x)$, what do we mean when we say they are the same? How about, they have the same truth value for every possible $x$? We can package this as the assertion:

$$\forall x~(P(x) \Leftrightarrow Q(x))$$

which may or may not be true at some interpretation, $\mathcal{I}$.

By extension, given sets $A$ and $B$, we define $A = B$ to mean $$\forall x~ (x \in A \Leftrightarrow x \in B)$$ You can see that this reduces to the original statement when $A$ is $\{ x \mid P(x)\}$ and $B$ is $\{y \mid Q(y)\}$.

Now what would it mean if we weakened the use of biimplication, $\Leftrightarrow$, to implication, $\Rightarrow$?

$$\forall x~(x \in A \Rightarrow x \in B)$$

This is precisely what we mean when we say $A \subseteq B$. Notice that we can combine $A \subseteq B$ and $B \subseteq A$ to conclude $A = B$, since

$$ \begin{aligned} A \subseteq B \wedge B \subseteq A &\equiv \forall x~(x \in A \Rightarrow x \in B) \wedge \forall y~(y \in B \Rightarrow y \in A) \\ &\equiv \forall x~[(x \in A \Rightarrow x \in B) \wedge (x \in B \Rightarrow x \in A)] \\ &\equiv \forall x~(x \in A \Leftrightarrow x \in B) \\ &\equiv A = B \end{aligned}$$

Notice that $A \subseteq B$ doesn't rule out the possibility that $A = B$, and to express "proper subset", $A \subset B$, we must say something like $(A \subseteq B) \wedge \exists x~( x \in A \wedge x \not\in B)$ or $A \subseteq B \wedge A \neq B$. Don't be misled by the pronounciation "subset or equal to" for $\subseteq$ sounding like a compound statement involving $\subset$ "subset", as a component - it's really the other way around.

## A few kinds of sets and constructions

### Empty set
Perhaps the most important, yet often forgetten set, is the empty set. This is just the "always false" predicate, so we define it like this.

$$\emptyset := \{x \mid \mathbf{f}\}$$

> HOT TIP: Whenever a question mentions some arbitrary-unspecified set, consider what would happen if it was the empty set. 

### Singleton sets

Given an object $a$, we can define the set just containing $a$, written $\{a\}$, like this:

$$\{x \mid x = a\}$$

### Finite sets

Given some objects, say $a,b,c,d$, we can describe a set which contains those elements, and nothing else. $\{a,b,c,d\}$ But is this the same as $\{a,a,d,c,b\}$? How would we demonstrate this? The problem is we haven't defined what $\{a,b,c,d\}$ *is* - what is the underlying predicate? Here's a simple way to define it:
  
  $$\{a,b,c,d\} := \{x \mid x = a \vee x = b \vee x = c \vee x = d\}$$

Now it's clear that we could demonstrate $\{a,b,c,d\} = \{a,a,d,c,b\}$, since this is just proving that

$$(x = a \vee x = b \vee x = c \vee x = d) \equiv (x = a \vee x = a \vee x = d \vee x = c \vee x = b)$$

### Infinite Sets

Gathering a complete collection containing infinitely many things is a questionable thing to do, but we do not run into this problem with sets. Why? Because we do not need to generate/nor collect any of the elements in the set, we just need to be able to answer yes or no whenever prompted with an object. If there are infinitely objects that we *would* say yes to, then we have an infinite set.

You might protest at my presumption that *there are* infinitely many things to test for elementhood, and you'd be absolutely right. Every foundational theory which rigorously defines what a set is, will have an axiom stating that there is at least one infinite set, usually the set of natural numbers $\mathbb{N}$.
<!-- 
Once we have an infinite set, it's easy to construct new infinite sets, for example $$\texttt{Even} := \{n \in \mathbb{N} \mid \exists i\}$$ -->

<!-- Perhaps the most common infinite set you'll come across in this subject is the set of words constructed from some *finite* alphabet. For example, if $\Sigma = \{a,b,c\}$ is our finite alphabet, then we denote the "Kleene Star" of this set as
$$\Sigma^* := \bigcup_{n\in \mathbb{N}} \left\{a_1 a_2 \dots a_n \mid \forall i~ (1 \leq i \leq n \Rightarrow a_i \in \Sigma \right\}$$ -->

### Union and Intersection sets

The union of two sets is quite plainly related to the disjunction connective. Given sets $A$ and $B$, we define

$$A \cup B := \{x \mid x \in A \vee x \in B\}$$

Looking back at the finite set example, notice that
  
$$\{a,b,c,d\} = \{a\} \cup \{b\} \cup \{c\} \cup \{d\}$$

Likewise, the intersection is constructed using the conjunction connective. Given sets $A$ and $B$, we define

$$A \cap B := \{x \mid x \in A \wedge x \in B\}$$

Just like disjunction of logical formulas creates a formula where (usually) *more* models make it true, the union of sets create (usually) *larger* sets. Likewise, the intersection of sets create (usually) *smaller* sets, since the conjunction of logical formulas creates one which is true at (usually) *less* models.

## The important difference between sets and unary predicates

Hopefully by now you are convinced that a set "is just a predicate". However I want to make a careful distinction now. A set is a set, and only becomes a logical statement via the $\in$ symbol. Likewise, a unary predicate, or any logical statement $\varphi(x)$, is not a set, and only becomes a set once we *lift* it to a set by writing $\{x \mid \varphi(x)\}$.

Essentially, a set is a *wrapper* for a predicate, and that predicate is accessed via the $\in$ symbol.

As an example, if $A$ and $B$ are sets, then the following statement does **not** make sense,

$$\color{red}{(A \cap B)} \Leftrightarrow (x \in B \wedge x \in A)$$

because the thing on the left side of the $\Rightarrow$ is not a logical assertion. We cannot assert a set, we must assert something *about* a set. 

Likewise the following statement doesn't make sense either

$$(A \cap B) = \color{red}{(x \in B \wedge x \in A)}$$

since the thing on the right side of the equals sign should be a set, not a logical assertion. We can fix both sentences as follows.

$$\begin{aligned}(x \in A \cap B) &\Leftrightarrow (x \in B \wedge x \in A) \\
(A \cap B) &= \{x \mid x \in B \wedge x \in A\} \end{aligned}$$

For similar reasons, the reading of $x \in A \cap B$ should be unambiguously $x \in (A \cap B)$, and not $(x \in A) \cap B$, because we can only intersect *sets*, not logical statements like $x \in A$. Of course we can *lift* any logical statement to a set, but that would be written $\{x \mid x \in A\} \cap B$, which is just $A \cap B$, and likely not what we mean when we write $x \in A \cap B$.

----

In the following table, notice how $\subseteq$ and $=$ turn two sets in a logical statement, while $\cup, \cap, \setminus, \oplus, \times$ turn two sets into a new set. Also notice that anything written in the **Set Construction** column can be written as $\{x \mid \varphi\}$, where $\varphi$ is the corresponding formula in the **Equivalent Statement** column with $x$ free. The last row (set product) is an exception - we would write $\{(x,y) \mid x \in A \wedge y \in B \}$.

|Set Construction|Logical Statement|Equivalent statement|
|---|---|---|
|   | $A \subseteq B$| $\forall x~ (x \in A \Rightarrow x \in B)$ |
|   | $A = B$| $\forall x~ (x \in A \Leftrightarrow x \in B)$ |
|$A \cup B$ | $x \in A \cup B$| $x \in A \vee x \in B$ |
|$A \cap B$ | $x \in A \cap B$| $x \in A \wedge x \in B$ |
|$A \setminus B$ | $x \in A \setminus B$| $x \in A \wedge x \not\in B$ |
|$A \oplus B$ | $x \in A \oplus B$| $x \in A \oplus x \in B$ |
|$A \times B$ | $(x,y) \in A \times B$| $x \in A \wedge y \in B$ |

