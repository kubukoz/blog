---
layout: post
cover: 'assets/images/coherence-bg.jpg'
navigation: True
title: Data coherence at large
date: 2019-04-14 16:00
tags:
  - scala
  - functional programming
subclass: 'post tag-test tag-content'
logo: 'assets/images/jk_white.svg'
author: kubukoz
disqus: true
categories: kubukoz
---

A week ago, while coming back from [Scalar](http://scalar-conf.com), I was thinking about coherent data. In particular, I was wondering if it's possible to perform certain simple validations and encode their results in types. Here's what i found.

## [What is coherent data](#what-is-coherent-data)

The concept of coherent data was introduced to me when I watched [Daniel Spiewak's talk about coherence](https://www.youtube.com/watch?v=gVXt1RG_yN0). Data coherence is achieved when we have a single source of truth about our data. Let's look at an example:

```scala
val name: Option[String] = Some("Rachel")

val result: String =
  if(name.isEmpty) "default"
  else name.get
```

In this code we don't have any sort of coherence in the data. One condition that we check - the emptiness of `name` - gives us information that is immediately lost in the rest of the code. Even if we've checked for the emptiness and are sure that the Option isn't empty, there's nothing in the type system or any other feature of the language that would tell us whether we can call `Option#get` on it safely. We only know that because we keep in mind that we've already checked for the emptiness ourselves.

Another example involves lists:

```scala
val names: List[String] = List("Phoebe", "Joey", "Ross")

val firstNameLength: Option[Int] =
  if(names.isEmpty) None
  else Some(names.head.length)
```

Even though we've checked for the list's emptiness, we still have no guarantee that `head`, which is in general not a safe method to call on a list, won't throw an exception.

There's no connection between `isEmpty` and `head`/`get` enforced by the compiler. It's just incapable of helping us avoid mistakes like this:

```scala
if(elems.isEmpty) println(elems.head) //boom!
```

Is this the way it's meant to be? Is it possible to make the compiler work with us to ensure some guarantees about our data?

In Kotlin, another language that works on the JVM (mostly), there is a feature that solves this particular problem we had with Option: [smart casts](https://kotlinlang.org/docs/reference/typecasts.html#smart-casts). But the feature is limited to checking types or nullity, while we're looking for something that'll work in the general case.

Thankfully, there're features in Scala that allow us to reason about our data as coherent: pattern matching and higher-order functions.

## [Data coherence with pattern matching](#data-coherence-with-pattern-matching)

Let's rewrite the examples from the previous section using pattern matching:

```scala
val name: Option[String] = Some("Rachel")

val result = name match {
  case None    => "default"
  case Some(v) => v
}
```

Much better - now we managed to get both the emptiness check and the extraction in one go (in the pattern match). We're not calling any unsafe methods, and we get additional help from the compiler in the form of exhaustivity checking. What about lists?

```scala
val names: List[String] = List("Phoebe", "Joey", "Ross")

val firstNameLength: Option[Int] = names match {
  case Nil       => None
  else head :: _ => Some(head.length)
}
```

Again, we're not calling `head` or any other unsafe method. And the check is again combined with the extraction in a single pattern match.

I mentioned higher-order functions, so what about them? Turns out that pattern matches (and functions implemented using them) can often be rewritten using a single call to `fold` for the given data type. It's more obvious in the case of Option:

```scala
val name: Option[String] = Some("Rachel")

val result = name.fold("default")(identity)
```

Or `Either`:

```scala
val name: Either[NameNotFound, String] = Right("Rachel")

val result = name.fold(extractError, identity)
```

However, `fold` doesn't appear to be the right choice if we only care about part of the data (like in the list example, where we only needed the head of the list). In that particular case, a good old `headOption` would work just fine.

## [Data coherence at scale](#data-coherence-at-scale)

This is all nice and pretty - the promise of having data that doesn't require us to watch our backs every step we take sounds encouraging. But when the data is part of other data, things start to break very soon.

Suppose we're working with a `User` class:

```scala
case class User(name: String, lastName: Option[String])
```

Now imagine we want to run a code path only if the user has a `lastName` set. The caveat: we still want to pass the `User` instance:

```scala
def withValidatedUser(lastName: String, user: User): IO[Int] = ...

val user = User("Katie", Some("Bouman"))

user.lastName match {
  case Some(last) => withValidatedUser(last, user)
  case None       => IO.pure(42)
}
```

What's the problem? Well, even though we did the validation in a coherent way using a pattern match, we lose the coherence inside `withValidatedUser`: `lastName` is now completely separated from the `User` object it came from. And now we have two `lastName`s: one optional, one required.

```scala
def withValidatedUser(lastName: String, user: User): IO[Int] = IO {
  println((lastName, user.lastName))
}
```

This is terrible news. It appears like we can't maintain data coherence when the data is part of something else. Or can we?

Surely there are ways to get what we want - one of them is adding a new variant of the `User` class, but with a required `lastName`:

```scala
case class UserWithLast(name: String, lastName: String)
```

...but you can probably already imagine how much boilerplate it'd bring to your codebase if you needed a new class for every combination of optional fields if the `User` type had more than one:

```scala
case class User(
  name: String,
  lastName: Option[String],
  email: Option[String])

case class UserWithLastAndEmail(
  name: String,
  lastName: String,
  email: String)

case class UserNoEmail(name: String, lastName: String)

case class UserNoLast(name: String, email: String)
...
```

It doesn't seem like a viable solution to the problem. In fact, it'd create more problems than it solved.

I entertained the idea that we could parameterize our original `User` with type parameters a bit:

```scala
case class User[LastName](name: String, lastName: LastName)

//just so that we have some distinction below
type LastName = String

def withValidatedUser(user: User[LastName]): IO[Int] = ...

val user: User[Option[LastName]] = User("Katie", Some("Bouman"))

// try it at home: this could be a fold!
user.lastName match {
  case Some(last) => withValidatedUser(user.copy(lastName = last))
  case None       => IO.pure(42)
}
```

Now a few things happened:

1. We're not passing the `lastName` value separately now
2. `lastName` being required is now a type-level prerequisite in `withValidatedUser`
3. We're copying the `user` value with `lastName` substituted with the value extracted from `Option` using a pattern match
4. We only have one data type that supports all combinations of emptiness/non-emptiness using type parameters.

What does this give us?

We gained type safety in `withValidatedUser` - the function now can't be called with a `User` whose `lastName` hasn't been checked for non-emptiness. It just won't compile if we pass an `Option` in that field. One less test case to worry about.

It's also pretty interesting that we can now write functions that require the user to **not** have a second name:

```scala
def withInvalidUser(user: User[Unit]): String = user.name
```

For me, the most surprising part here was that I couldn't use `Nothing` as the type of `lastName` - which I wanted to do to guarantee that `lastName` just isn't there. However, we can't create values of type `Nothing`, and we can't pass them as constructor parameters of a class. I used `Unit` instead, which is a type with only one value, which is obviously not the user's last name. Creating a user with `LastName = Unit` is also very easy: `User("Joe",  ())`.

What's the problem with the latest solution?

1. We made it more difficult to work with the User type - now everyone who uses that type needs to be aware that the `lastName` field is parameterized. And it's viral - pretty soon all the codebase will be littered with type parameters irrelevant in these regions of code.
2. We can insert any type we want as `LastName`. It could even be `IO[Unit]`. And it's very easy to do so.

Looks like we aren't quite there yet. What can we do to make our type easier to work with?

## [A different kind of coherence](#a-different-kind-of-coherence)

Our original goal in the exercise was to encode validations and invariants of our data in the data's type. Let's get back to our `User` example. This time we'll encode it using higher-kinded types (but with two "variable-effect" fields):

(if you're not familiar with higher-kinded types, I suggest you [check out some blog posts](https://typelevel.org/blog/2016/08/21/hkts-moving-forward.html). For now, it should be enough to know that a higher-kinded type is a type-level function, or a type that needs to be applied with another type to construct a fully concrete type that can be assigned to a value. For example `Option` needs an `A` to become `Option[A]`, a type that has values.

If we parameterize `User` with higher-kinded types, we get this:

```scala
case class User[LastName[_], Email[_]](
  name: String,
  lastName: LastName[String],
  email: Email[String]
)
```

Cool. How do we create a `User` with all fields optional now?

```scala
val jon: User[Option, Option] =
  User[Option, Option]("Jon", Some("Snow"), None)
```

How do we create one with some fields required?

```scala
// old trick from scalaz/cats/shapeless
type Id[A] = A

val jon: User[Id, Option] = User[Id, Option]("Jon", "Snow", None)
```

Also cool. We can't assign `None` as the value of `lastName` if `LastName` is `Id`. How would we encode the requirement that there's no email now?

```scala
type Void[A] = Unit

val donald: User[Id, Void] = User[Id, Void]("Donald", "Duck", ())
```

As you can see, we cheated a bit - the goal of parameterizing our type with higher-kinded types was to ensure that we always have `String` (or whatever used to be in an `Option`) in an effect (like `Option` or `Id`), but if the effect is `A => Unit`, we have no `String` in the result whatsoever. Is it bad?

Maybe, maybe not.

If we have type parameters for our data, we can't make it obligatory to have `String` anywhere in the type of `Email`. (well, maybe we could, using some more type-level machinery and implicits, but I don't want to go that deep into it).

However, we're making it harder to use a type that doesn't have the `String` in it (`Option` is a more obvious choice for a type parameter than, say, `λ[A => Int]`, which would mean that `lastName` is of type `Int`). And we still get an escape hatch that allows us to omit some fields in a `User` value (by saying that `lastName` is of type `Unit`).

Instead of a custom `Void` type, we could've used `Const`:

```scala
import cats.data.Const

val john = User[Id, Const[(), ?]]("John", "De Goes", Const(()))
john.lastName.getConst // equals ()
```

We had at least two problems with the previous solution:

1. the type parameters would spread out to every place in the codebase where `User` appears.
2. we didn't have type-level hints as to what type we should use.

I believe the second problem is not an issue anymore (see above argument about `Unit`), but the first one remains: everywhere we had

`def foo: User => A`, we'll now have

`def foo[F[_], G[_]]: User[F, G] => A`. What can we do to make this a little more pleasant, and to avoid spreading every single type parameter to pieces of code that don't care about the contents of our parameterized fields?

## [Variance and higher kinded types](#variance-and-higher-kinded-types)

Thankfully, Scala has quite powerful support for variance annotations. We can use it to our advantage: to make our type easier to work with.

Suppose we are writing a function that takes a user but only uses their first name - which isn't type parameterized. Let's recall the definition of `User`:

```scala
case class User[LastName[_], Email[_]](
  name: String,
  lastName: LastName[String],
  email: Email[String]
)
```

Let's add some variance annotations...

```scala
case class User[+LastName[_], +Email[_]](
  name: String,
  lastName: LastName[String],
  email: Email[String]
)

object User {
  // apparently, Any is kind-polymorphic
  // and counts as a suitable * -> * kinded type!
  type Arb = User[Any, Any]
}
```

Making our type covariant in both type parameters should allow us to pass a `User[F, G]` for any `F` and `G` where a `User[Any, Any]` (`User.Arb`) is required. Let's see if it works:

```scala
def nameTwice(user: User.Arb): String = user.name ++ user.name

> nameTwice(User[Option, Id]("Mike", None, "mike@evilmail.com"))
res0: String = "MikeMike"
```

Looks like it does. However, maybe hardcoding `Any, Any` isn't the best solution there - what if at some point we actually want to perform some validation and use the parameterized fields? Maybe a better encoding would be this:

```scala
//class User defined as above

object User {
  type Canonical = User[Option, Option]
}
```

Now we could write functions taking `User.Canonical` as the base case, and only customize the functions that we want to work with certain types of `User` specifically.

```scala
def worksWithAllUsers(user: User.Canonical): (String, String) =
  (user.lastName, user.email) match {
    case (Some(lastName), Some(email)) =>
      withFullUser(
        user.copy[Id, Id](
          lastName = lastName,
          email = email
        )
      )

    case (Some(lastName), None) =>
      withPartialUser(user.copy[Id, Option](lastName = lastName))

    case _ =>
      ("Default", "default@evilmail.com")
}

def withFullUser(user: User[Id, Id]): (String, String) =
  (user.lastName, user.email)

def withPartialUser(user: User[Id, Any]): (String, String) =
  (user.lastName, "default@evilmail.com")
```

## [Other possible use cases](#other-possible-use-cases)

What other invariants can we encode?

- `Option[A]` can become `A` or `Unit`.
- `Either[A, B]` can become `B` or `A`.
- `List[A]` can become `Unit` (empty list) or `(A, List[A])` (`NonEmptyList[A]`).

(note how we're deconstructing the data types, which happen to be ADTs, into coproducts)

If we're really trying to experiment, we can go the extra mile:

- `List[A]` can be checked for length and encoded as `Sized[List[A], 5]`.
- `User[IO[A]]` can become `IO[User[A]]` (sounds like [`Traverse`](https://typelevel.org/cats/typeclasses/traverse.html), doesn't it?) - we can run the IO outside and keep the result to avoid unnecessary recalculation.
- `User[Stream[IO, A]]` can become `IO[User[List[A]]]` - we can run the stream and work with it as a list, once it's all consumed (that is, if it fits into the memory).

There's a lot we can do, really:

- `String` -> `NonEmptyString`, `regex"(a-Z)+"`, `IPv4`, `INetAddress` refined types
- `Int` -> `PosInt` / `EvenInt` refined types, smaller primitives (`Byte`, etc.)

## [Summary](#summary)

There are a few good reasons for trying to make our data coherent, including but not limited to using the techniques mentioned in this post:

- additional type safety by enforcing constraints locally on the type level
- increased ease of putting code under test - if your function doesn't depend on `lastName`, you can pass `()` in that field safely

However, there are difficulties associated with all that:

- type parameters creeping into all your functions (possibly can be avoided by introducing a canonical type and only being specific when it's needed)
- it's questionable whether parameterizing data with types scales (e.g. if we have `case class Users[Collection[_], LastName[_]](users: Collection[User[LastName]])`, is it going to be easy to change?)
- the benefit might not be that significant after all
- possibly more problems that I haven't figured out yet

I haven't seen this approach to abstracting on data used anywhere, so I don't know what the best practice is, and whether the idea is feasible for use in real projects, but it certainly seems worth investigating.

Maybe type-parameterized data would work better with lenses (e.g. from [Monocle](http://julien-truffaut.github.io/Monocle)) to make the work with copying more pleasant and less boilerplatey?

As some of our validations involved e.g. breaking up `Option` into a tagged coproduct of `Unit` and `A` (which it is), maybe the techniques mentioned in this post could be used together with optics like Prisms (which are meant for working with coproducts) to form more powerful abstractions?

Maybe we could have a `Monad`/`Traverse`/whatever instance for a type like `case class User[LastName[_], Email[_]](...)` for each of its fields to get additional functionality for free using the functions defined on the appropriate typeclass?

As you can see, more insight into the possibilities is needed to determine if the concept can be used more widely in our code.

## [Parting words](#parting-words)

Thank you for reading. 

These ideas are very fresh for me, and I haven't spent a lot of time researching them yet. In the future, I hope to spend more time in this area and to develop a more formal or constrained description of the ideas mentioned here.

Most importantly, I hope to find out whether these ideas actually help achieve more type safety without sacrificing maintainability in real world programming.

Let me know what you think about the ideas presented in this post, and whether you enjoyed reading it!
