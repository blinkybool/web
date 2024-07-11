---
layout: post
title: "Intro to streams: control-flow and data-flow in Luau"
updated: 2024-07-11
---

[Stream.luau](https://gist.github.com/blinkybool/1390d53a730493e2ce72549c5bf7eaec)
<style type="text/css">
  /* .gist {width:500px !important;} */
  .gist-file
  .gist-data {max-height: 300px;max-width: 1000px;}
</style>
<script src="https://gist.github.com/blinkybool/1390d53a730493e2ce72549c5bf7eaec.js?file=Stream.luau"></script>

This is (part 1 of) a conceptual intro to `Stream.luau`, a (very new) library I wrote for managing the complexity of event-driven programming in Roblox (with types!).
It is directly inspired by [Rx (Nevermore)](https://quenty.github.io/NevermoreEngine/api/Rx/), which itself is a port of [RxJS](https://rxjs.dev/) to lua (also see the [standalone version by Anaminus](https://gist.github.com/Anaminus/1f31af4e5280b9333f3f58e13840c670)). See the "IAQ" (immediately anticipated questions) section at the end for comparisons to observables and Rx. For now we will not assume prior familiarity with observables.

## What is a Stream?
It's a function (there are no classes in this library - just typed-functions), which takes a `listener: (T...) -> ()` (a function that can be fed arguments of the appropriate type) and returns a CleanupTask. A CleanupTask is usually something like an `RBXScriptConnection`, and cleaning it means to disconnect it.
```lua
export type CleanupTask = -- omitted
export type Stream<T...> = (listener: (T...) -> ()) -> CleanupTask
-- example: `Stream<number,string>` is the type `(listener: (number, string) -> ()) -> CleanupTask`
```
When a `stream : Stream<number>` is called with a `listener`, it can call `listener(x)` with any number `x` whenever it likes (synchronously or asynchronously), but it must cancel all future calls once it's `CleanupTask` is "cleaned".
Here is a toy-example to illustrate (we use the terminology "emits `x`" when the stream calls the listener with `x`).

```lua
local function myStream(listener: (number) -> ()): CleanupTask
	-- Emits synchronously
	listener(1)
	listener(2)

	-- Emits asynchronously
	local value = 3
	local thread = task.spawn(function()
		while true do
			task.wait(1)
			listener(value)
			value += 1
		end
	end)

	-- This is the cleanup - `clean(thread)` will stop this stream.
	return thread
end

local cleanup = myStream(print) -- prints 1 and 2 immediately
-- will print 3,4,5,6... every second until cleanup is called
task.wait(4.5)
clean(cleanup)
```

Streams are about control-flow and data-flow. By listening to a stream, i.e. giving it a callback/behaviour, you yield control to the stream to decide when and with-what-data that behaviour is executed. In this sense, they can be thought of as a common generalisation of for-loops and events, which both provide data from some source, and execute a behaviour synchronously (for-loops) or asynchronously (events).

But do not be mistaken, they are strictly more-powerful than either concept!

The reason is that setting up control-flow (connecting to events/streams), while managing the timely clean up all associated connections, can explode in complexity. You will do one of the following:
1. Grit your teeth and pollute your code with layers of housekeeping logic
2. Half-grit your teeth and implement the correct control flow, but with memory leaks (not disconnecting connections)
3. Fail to implement the control flow correctly (slack-jawed?)

The first cause of complexity, which we will explore in this post, is the need to connect to a dynamically-defined event (Spoiler: it is solved by `switchMap`!).

## Dynamically defined events

Suppose the local player's character-model has a "Damage" attribute which we want to display on the screen.
A first approximation might look like:
```lua
local function updateDamageGui(damage: number?)
	-- do stuff
	-- ...
	-- ...
end

updateDamageGui(Players.LocalPlayer.Character:GetAttribute("Damage"))
local connection = Players.LocalPlayer.Character:GetAttributeChangedSignal("Damage"):Connect(function()
	updateDamageGui(Players.LocalPlayer.Character:GetAttribute("Damage"))
end)
-- disconnect the connection when done displaying
```
If only it was that simple!
Problems:
1. `Players.LocalPlayer.Character` might be nil (and will be on startup), and therefore we do not have static access to the "PropertyChanged" event - it is dependent on the character instance, so it is a *dynamically defined event*.
2. The call to `updateDamageGui` has been duplicated, hence the abstraction into a function.
Problem 2 is not so-bad here, but, as we'll see, can worsen arbitrarily when behaviour is scattered amongst a mess of housekeeping logic.

Problem 1 is terrible. Let's chuck a `:Wait()` on it!
```lua
local character = Players.LocalPlayer.Character or Players.LocalPlayer.CharacterAdded:Wait()
updateDamageGui(character:GetAttribute("Damage"))
local connection = character:GetAttributeChangedSignal("Damage"):Connect(function()
	updateDamageGui(character:GetAttribute("Damage"))
end)
```

Oh no, our damage stops updating after our character respawns, because `Players.LocalPlayer.Character` is a different instance now!
Let's jump ahead to a fully-correct implementation. Grit your teeth!
```lua
local attributeConnection = nil
local function handleCharacter(character: Model?)
	if character == nil then
		updateDamageGui(nil)
		return
	end
	updateDamageGui(character:GetAttribute("Damage"))
	if attributeConnection ~= nil then
		attributeConnection:Disconnect()
	end
	attributeConnection = character:GetAttributeChangedSignal("Damage"):Connect(function()
		updateDamageGui(character:GetAttribute("Damage"))
	end)
end
handleCharacter(Players.LocalPlayer.Character)
local characterConnection = Players.LocalPlayer:GetPropertyChangedSignal("Character"):Connect(function()
	handleCharacter(Players.LocalPlayer.Character)
end)
-- Disconnect attributeConnection (if not nil!) and characterConnection when done displaying
```
🤮
Problems:
1. This is a mess: our important behaviour is getting harder to locate
2. We are polluting our local variables with housekeeping variables, which are obtaining more complex names to distinguish themselves.
3. When we are done with this behaviour, we have to disconnect our connections in a specific way (`attributeConnection` if it's not nil and then `characterConnection`). If the nature of the behaviour changes, we must maintain the cleanup logic accordingly, which likely exists in another location. 

Let's start by separating the behaviour from the housekeeping, and encapsulate the cleanup logic.

```lua
local function onDamageAttribute(callback: (number?) -> ()): CleanupTask
	-- We have replaced `updateDamageGui` with `callback`.
	local attributeConnection = nil
	local function handleCharacter(character: Model?)
		if character == nil then
			callback(nil)
			return
		end
		callback(character:GetAttribute("Damage"))
		if attributeConnection ~= nil then
			attributeConnection:Disconnect()
		end
		attributeConnection = character:GetAttributeChangedSignal("Damage"):Connect(function()
			callback(character:GetAttribute("Damage"))
		end)
	end
	handleCharacter(Players.LocalPlayer.Character)
	local characterConnection = Players.LocalPlayer:GetPropertyChangedSignal("Character"):Connect(function()
		handleCharacter(Players.LocalPlayer.Character)
	end)
	
	-- Wrapped cleanup logic (made idempotent)
	local cleanup = function()
		if attributeConnection ~= nil then
			attributeConnection:Disconnect()
			attributeConnection = nil
		end
		if characterConnection ~= nil then
			characterConnection:Disconnect()
			characterConnection = nil
		end
	end
end

local cleanup = onDamageAttribute(updateDamageGui)
-- call `clean(cleanup)` when done displaying
```
🤔
We have separated our housekeeping logic from our behaviour, and encapsulated the cleanup logic.
Hiding/moving complexity is not virtuous in itself, but we will find that we can
decompose `onDamageAttribute` into *reusable* and *composable* parts, which clearly express the
intended behaviour.

From here on, we start using stream terminology. We see `onDamageAttribute` has type `Stream<number?> = ((number?) -> ()) -> CleanupTask`, so we'll call it `damageStream`, and instead of `callback`, we opt for the term `listener`.

Here is the full decomposition of `onDamageAttribute`, with nothing omitted (except `clean`).
```lua
local characterStream: Stream<Model?> = function(listener: (Model?) -> ())
	listener(Players.LocalPlayer.Character)
	return Players.LocalPlayer:GetPropertyChangedSignal("Character"):Connect(function()
		listener(Players.LocalPlayer.Character)
	end)
end

-- Make a stream which emits an Attribute of an instance (immediately and on-change)
local function attributeOf(instance: Instance, name: string): Stream<any?>
	return function(listener: (any?) -> ())
		listener(instance:GetAttribute(name))
		return instance:GetAttributeChangedSignal(name):Connect(function()
			listener(instance:GetAttribute(name))
		end)
	end
end

-- A Stream<T?> which just emits nil once (immediately)
local function nilOnce<T>(listener: (T?) -> ()): CleanupTask
	listener(nil)
	return nil
end

local damageStreamStream: Stream<Stream<number?>> = function(listener: (Stream<number?>) -> ()): CleanUpTask
	-- The return here returns the CleanUpTask of the character stream
	-- (in this case, a :GetPropertyChangedSignal("Character") connection)
	return characterStream(function(character)
		if character then
			local innerStream = attributeOf(character, "Damage")
			listener(innerStream)
		else
			listener(nilOnce)
		end
	end)
end

-- (this logic is just what switchAll does)
-- Note that `cleanupInner`, `cleanupStream` will be what we previously called `attributeConnection` and `characterConnection`
local damageStream: Stream<number> = function(listener: (Stream<number?>) -> ())
	local cleanupInner = nil
	local cleanupStream = damageStreamStream(function(innerStream: Stream<T>): ()
		clean(cleanupInner)
		cleanupInner = nil
		cleanupInner = innerStream(listener)
	end)
	return function()
		clean(cleanupInner)
		cleanupInner = nil
		clean(cleanupStream)
		cleanupStream = nil
	end
end

local cleanup = damageStream(updateDamageGui)
-- call `clean(cleanup)`
```

Now we have some simple components here that we can extract into reusable library functions,
such as `attributeOf` and `propertyOf` (a generalisation of `characterStream`).
However what is the best way to decompose/understand the creation of `damageStream`
from `characterStream` via `damageStreamStream`?

The answer is `switchMap(fn)(characterStream)`, where `fn` maps characters to damage streams.
Internally, `switchMap` maps the emitted characters to damage streams, and uses `switchAll`
to emit from the latest damage stream.

```lua
local function switchAll<T...>(stream: Stream<Stream<T...>>): Stream<T...>
	return function(listener: (T...) -> ()): CleanupTask
		local cleanupInner = nil
		local cleanupStream = stream(function(innerStream: Stream<T...>): ()
			clean(cleanupInner)
			cleanupInner = nil
			cleanupInner = innerStream(listener)
		end)
		return function()
			clean(cleanupInner)
			cleanupInner = nil
			clean(cleanupStream)
			cleanupStream = nil
		end
	end
end

local function switchMap<T...,U...>(fn: (T...) -> Stream<U...>): (Stream<T...>) -> Stream<U...>
	return function(source: Stream<T...>): Stream<U...>
		return switchAll(function(streamListener: (Stream<U...>) -> ()): CleanupTask
			-- Apply fn to every emitted value to get a stream, and give it to the streamListener
			return source(function(...: T...): ()
				streamListener(fn(...))
			end)
		end)
	end
end

local characterStream: Stream<Model?> = propertyOf(Players.LocalPlayer, "Character")
local function characterToDamageStream(character: Model)
	if character then
		return attributeOf(character, "Damage")
	else
		return nilOnce
	end
end
local damageStream: Stream<number?> = switchMap(characterToDamageStream)(characterStream)
```

This kind of combination of `switchMap` with `attributeOf` or `propertyOf` is common enough that we provide a shorthand `toAttribute(name): (Stream<Instance?>) -> Stream<any?>` (resp. `toProperty`) for it, which allows a terse/idiomatic presentation.
```lua
local damageStream = pipe1(
	propertyOf(Players.LocalPlayer, "Character"),
	toAttribute("Damage")
)
local cleanup = listen(damageStream, updateDamageGui)
```
Some notes:
- This definition of `damageStream` evaluates to `toAttribute("Damage")(propertyOf(Players.LocalPlayer, "Character"))`. Piping is just a way to reverse application syntax, so that stream-transformers are sequenced after the stream.
- `listen` is again just syntax, it just does `damageStream(updateDamageGui)` - don't use it if you don't like it
- Since `updateDamageGui` is no longer duplicated, we can simply write it's contents within the listen call, like this:
```lua
local cleanup = listen(damageStream, function(damage: number?)
	-- do stuff
	-- ...
	-- ...
end)
```

Okay, what if our requirements evolve, and instead, we have an `ObjectValue` pointing at a `Player?`, and we want to display their damage? Here's how it might look using the functions in this library.
```lua
local selectedPlayer = Instance.new("ObjectValue")
local damageStream = pipe2(
	fromValueBase(selectedPlayer),
	toProperty("Character"),
	toAttribute("Damage")
)
local cleanup = listen(damageStream, updateDamageGui)
```
Imagine writing all of the housekeeping logic for this in the first style!


## Reflection

In reflection: is this good programming?

The real test is whether working with these abstractions in practice is easier in the long run than working with the original mess.
- Is it flexible and maintainable?
- Is it easy to understand and debug?
- How much overhead does it add - both cognitively and computationally?

I have written `Stream.luau` with these things in mind. In particular, streams are just functions, and their internal state is entirely implemented through local variables in their closure. In many cases, it is straightforward to take an abstractly presented stream, such as our `damageStream` example, and repeatedly beta-reduce (for every function `f(x)`, and expression `exp`, replace `f(exp)` with the body of `f` with `x` replaced by `exp`) until the code resembles the original barebones implementation (with `attributeConnection` and `characterConnection`). This is basically reversing the process of abstraction that we followed - and this thought process is useful for keeping your feet on the ground about what you are doing.

I deliberately avoid using abstractions like maids, signals, brios inside this library - because the cleanup logic is not that difficult to write manually! We are writing a library to do housekeeping for the user, we do not need housekeeping help ourselves. I have also done this to try make stepping-through-the-code-debugging a less miserable experience - it's easier if we're not venturing into the guts of a maid every other line.

This library of functions is not an API. I am not doing any complex optimisations under the hood to make up for abstraction overhead. Instead, I've tried to walk the road of non-pessimism and wrote the dead-simplest code I could to implement the behaviour. I recommend just reading all of the code and changing whatever design decisions you disagree with.

From my experience with Rx, I don't think this goes without saying: don't use streams as a universal hammer for every problem, and try not to get too big-brained about fancy ways of combining streams together. It is possible to do some very complicated stream-piping karate to construct the perfect stream to feed into a short listener function, where in-fact you could have just moved more code into your listener function for a more readable result, or just split your problem into two streams. Sometimes the most readable stream is one you define from scratch (it's just a function!) - you don't need to build every stream out of stream primitives and transformers. Conversely, you *should* use the library functions when they do some real, non-trivial work for you, like `switchMap` and `combineLatest` (or it's typed interfaces: `combine1`, `compute2` etc).

We've only discussed dynamically defined events, and their solution `switchMap`.
Next time we'll talk about managing lifetimes with `listenTidyEach` in the simplest possible way.

Future posts:
- Lifetimes (`listenTidyEach`, `eachPlayer`, `eachChildOf`, ...)
- `combineLatest` (state management)
- `mount`/`new` (the bones of a flexible, reactive UI framework in about 400 LOC)
- a fruitful relationship with the luau typechecker

## IAQ (immediately anticipated questions)
> Is this battle-tested?

Nope. I've barely used it yet.

> How do I install it?

Just copy it: [Stream.luau](https://gist.github.com/blinkybool/1390d53a730493e2ce72549c5bf7eaec)

> What's the difference between streams and observables, and why did you write this if we already have Rx?

In short: streams+listeners are a simplified version of observables+subscribers, where `stream(listener)` corresponds to `observable:Subscribe(onFire)`. The `:Subscribe(onFire, onFail, onComplete)` method constructs a `Subscriber` object using the provided functions, while for listeners,there's no object, it's just an `onFire` function.

This library is a (typed) distillation of the core concepts in [Rx](https://quenty.github.io/NevermoreEngine/api/Rx/), [Brio](https://quenty.github.io/NevermoreEngine/api/Brio/) and [Blend](https://quenty.github.io/NevermoreEngine/api/Blend/) that I personally have found useful for programming in Roblox, which are: connecting to dynamically defined events, binding creation+cleanup or behaviour to lifetimes, declarative instance creation, and reactive state management.

I concluded that I could achieve all of this without subscribers having an `onFail` and `onComplete`, which, in Rx, spend most of their time being passed around, while `onFire` is where all the interesting stuff happens. Using `onFail` and `onComplete` makes observables more comparable to promises, which you may find beneficial.

The removal of `onFail` and `onComplete` causes many simplifications - there is no need for a subscriber to have state, so it's essentially just a wrapper around the `onFire` callback-function - therefore why not make it just a function? The choice to make the observable/stream object itself a function, rather than a class-object, is less essential but has the following motivations: 
+ I originally just wanted to write a typed version of Rx, because my most frequent and annoying bugs are all type errors (usually not handling nil). Typing for OOP classes/objects in Luau is not-so-well supported - there are multiple ways to achieve it, but there are tradeoffs and complications with each. On the other-hand, typing for function inputs/outputs is dead simple and quite reliable.
+ In most contexts I don't like to think of streams as "objects" or "data". Listening to a stream is closer to using a compiler macro that inserts the listener logic between the housekeeping logic. Why introduce an object for this?
+ I would like to claim that not allocating a table for every stream (like observables/maids/brios) is an advantage for streams over observables, but I lack the proper knowledge of luau to back this up (nor have I tested it - yet).
+ Step-through-the-code debugging is important to me, not just for fixing bugs but understanding what my code is actually doing (how much non-essential busywork is it doing?). So reducing non-fundamental operations like entering an object constructor or entering a class method just to call the real-function stored in the object, makes a big difference to that experience.

A compromise, that you may not like to give up, is that streams are less inspectable at runtime - the best you can do is `typeof(thing) == "function"`, and it's not possible to distinguish a stream from any other function. You may have a programming style that necessitates object inspection like this, in which case you could go ahead and refactor everything to use a constructor like this.
```lua
export type Stream<T...> = { ClassName: "Stream", onListen: ((T...) -> ()) -> CleanupTask } 
local function newStream<T...>(onListen: ((T...) -> ()) -> CleanupTask): Stream<T...>
	return { ClassName = "Stream", onListen = onListen }
end
-- then replace every `stream(listener)` with `stream.onListen(listener)`

-- Alternatively (up to you to give a type for the output)
local function newStream<T...>(onListen: ((T...) -> ()) -> CleanupTask)
	return setmetatable({ ClassName = "Stream" }, { __call = function(_, ...) return onListen(...) end})
end
```
For my use-cases (including `mount`), I've found it sufficient to just assume functions are streams.

> Should I use this?

If you want a third-party-maintainer to promise you a quality developer-experience and provide versioned-updates, you probably shouldn't.
I will probably update the gist a few times in the coming weeks, and eventually integrate it into my own work, but `Stream.luau` aims to be dead-simple in implementation, so that you can debug and fix problems yourself.
You can also chop it up if you don't like that it's all dumped in one file, and make whatever changes you think will make it a better fit for your specific project or programming style. If there are useful transformers in [RxMarbles](https://rxmarbles.com) or [ReactiveX](https://reactivex.io/documentation/operators.html) you find useful, just add them (but remember there's no fail/complete - unless you add them :P).

-Billy