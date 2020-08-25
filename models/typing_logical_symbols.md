---
layout: page
title: Typing Logical Symbols
author: Billy Price
date: August 22, 2020
---
[← Models](/models)

# Typing Logical Symbols

This is a small glossary of symbol-commands for $\mathrm{\LaTeX}$, specifically the math-environment, which can be used in Microsoft's equation editor in OneNote and Word.

### OneNote/Word Usage

Unfortunately, equation editing is only supported in the desktop app version of OneNote - not the webapp embedded into Microsoft Teams. You can download the free desktop app [here](https://www.onenote.com/download), and open your shared notebook by choosing "Open in app" from your notebook in Teams.

To enter equation mode in OneNote use the keyboard shortcut
* `ctrl` + `=` on Mac
* `alt` + `=` on Windows.

## Common Symbols

To lookup any symbol not listed here, use [Detexify](https://detexify.kirelabs.org).

**Propositional Logic**
* $\bot$ - `\bot`
* $\top$ - `\top`
* $\neg$ - `\neg`
* $\wedge$ - `\wedge`
* $\vee$ - `\vee`
* $\Rightarrow$ - `\Rightarrow`
* $\Leftrightarrow$ - `\Leftrightarrow`
* $\oplus$ - `\oplus`
* $\equiv$ - `\equiv`
* $\not\equiv$ - `\not\equiv`
* $\vDash$ - `\vDash` or `\models`
* $\nvDash$ - `\nvDash`
* $\varphi$ - `\varphi`
* $\psi$ - `\psi`

**Predicate Logic**
* $\forall$ - `\forall`
* $\exists$ - `\exists`

**Set Notation**
* $\mapsto$ - `\mapsto`
* $\emptyset$ - `\emptyset`
* $\in$ - `\in`
* $\cup$ - `\cup`
* $\cap$ - `\cap`
* $\subseteq$ - `\subseteq`
* $\setminus$ - `\setminus`
* $$ \{ \} $$ - `\{ \}`

The backslash is necessary in front of each curly-brace, since by themselves they are used to group latex expressions.

### Examples

* $\forall x \exists y L(x,y)$ - `\forall x \exists y L(x,y)`
* $$(X \cup Y) \setminus \{P, \neg P\}$$ - `(X \cup Y) \setminus \{P, \neg P\}`
* $\varphi_1, \varphi_2, \varphi_3 \vDash \psi$ - `\varphi_1, \varphi_2, \varphi_3 \vDash \psi`
