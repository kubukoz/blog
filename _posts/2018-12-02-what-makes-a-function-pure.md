---
layout: post
cover: 'assets/images/cover7.jpg'
navigation: True
title: What makes a function pure?
date: 2018-12-01 12:00
tags: fables fiction
subclass: 'post tag-test tag-content'
logo: 'assets/images/ghost.png'
author: kubukoz
categories: kubukoz
---
<br/>
Everyone knows that naming things is hard. In fact, often it seems to be one of the hardest things in computer science and programming in general. In addition, sometimes a single word has multiple meanings, or worse - a term is explained in a variety of slightly differing definitions. One such term is a pure function.

I'm by no means an expert in functional programming - I haven't read even a fraction of a significant part of all the papers published in the field. I haven't got a lot of war-proven experience in it either - most of my knowledge comes from other people's blogposts, talks, and stories, as well as a short period of writing production code using FP. But the definition of a pure function that I consider to be true is the same one as plenty of people use.

That definition doesn't distinguish pure and impure functions, though - all functions are pure, but the impure things we sometimes call functions, aren't. They are impure, and I call them procedures.

What makes a function a function, then?

The point of this post is to answer that question in a way that'll be relatively easy to understand for people with basic to intermediate experience with programming and Scala.

The definition for a function (and for functional programming) I use is very similar to the one [John A de Goes tweeted some time ago](https://twitter.com/jdegoes/status/936301872066977792). Functions are:

1. Total - they are defined for every input
1. Deterministic - a function will always return the same value given the same input.
1. Pure - their only effect is computing their output

If we define functions like the above, then functional programming is programming with functions, without procedures.

Let's look at these properties and see how they differ from those of what I defined as procedures.

## Totality

For a function to be total, we must make sure that it returns a value for every kind of input that the compiler allows it to take. That means it can't throw exceptions to the caller, like in the following example:

```scala
def validate(user: User): String = {
  val trimmed = user.name.trim
  if(trimmed.isEmpty) throw new Exception("Name is empty!")
  else trimmed
}
```

The above code compiles, and `validate("")` will compile too (as a method call with a result type of `String`), but it'll crash at runtime, unless the exception is caught. That makes `validate` a partial function, because it doesn't have a defined value of its declared type (`String`) for an empty string - in fact, it doesn't have one for any kind of input consisting exclusively of whitespace.

One functional alternative to this would be to use `Option`:

```scala
def validate(user: User): Option[String] = user.name.trim match {
  case "" => None
  case trimmed => Some(trimmed)
}
```

Or, if you want more information about the origin of failure, `Either` (if you like typed errors, that'd probably involve creating an ADT for possible errors):

```scala
sealed trait UserError extends Product with Serializable
case object NameIsEmpty extends UserError

def validate(user: User): Either[UserError, String] = user.name.trim match {
  case "" => Left(NameIsEmpty)
  case trimmed => Right(trimmed)
}
```

Another solution would involve tagless style with `ApplicativeError`:

```scala
type UserErrors[F[_]] = ApplicativeError[F, UserError]

def validate[F[_]: UserErrors](user: User): F[String] =
  user.name.trim.some.filter(_.nonEmpty).liftTo[F](NameIsEmpty: UserError)
  
type E[A] = Either[String, A]

validate[E](User("foo"))
```

By moving from throwing exceptions, we gain in at least a few ways:

- it becomes more explicit for the callers what kind of errors they can observe in case of failure
- the types will tell us whether a function actually can fail or not
- we avoid the overhead of creating an exception

and our function becomes total, because invalid inputs will give us a value (e.g. a `Left`)

## Determinism

In order for a function to be deterministic, it has to return the same value every time it's called with the same arguments. Because of that, something like the following is not pure:

```scala
def foo(): Int = {
  Random.nextInt()
}
```

The type of `foo` is `() => Int`, or `Unit => Int`, so we can basically say that it has one possible input (the value `()` of type `Unit`, in this case represented by "no arguments passed"). This would mean that eevery call to this function will return the same value, but it's quite the opposite - it'll usually return completely different values.

A simple way to ensure determinism of the above would be to allow passing a seed to the randomizer, instead of using a global Random instance:

```scala
def foo(seed: Int): Int = {
  new Random(seed).nextInt()
}
```

Now, calling `foo` with the same input will yield the same outputs.

Another example of a nondeterministic function can be a simple call to a database:

```scala
//let's pretend I'm using Slick
def findAllUsers(): List[User] = {
  val f = db.run {
    TableQuery[Users].to[List].result
  }
  
  //please don't do this in real code
  Await.result(f, 5.seconds)
}
```

The `Await` call was added only to make sure that we have a result immediately when the function completes.

If we change the state of the database between a few calls to this function, it'll yield different results. A functional, yet implausible solution would be to pass the state of the database as input to the function, or use some sort of `State` monad. An alternative, arguably better solution would be to suspend the side effect (reading from external mutable state) in an effect, which is what we'll discuss in the part of this post about **First-class effects**.

## Purity

I already said that a function is pure because its only effect is computing its output. Does it mean that by programming with functions we aren't allowed to write to a database or to standard output?

Not at all! Writing functions that execute I/O operations, or any other kind of effects, is possible, and it's way easier than naming things, in fact. However, it doesn't mean we're allowed to have functions with side effects.

What does it mean to have side effects, and how do we get effects (like talking to external systems) without side effects? We need referential transparency. And side effects are its exact opposite.

## Referential transparency

A definition of referential transparency found in [The red book (Functional Programming in Scala by Runar Bjarnason and Paul Chiusano)](https://www.manning.com/books/functional-programming-in-scala) says:

> An expression e is referentially transparent if, for all programs p, all occurrences of e in p can be replaced by the result of evaluating e without affecting the meaning of p. A function f is pure if the expression f(x) is referentially transparent for all referentially transparent x

Let me follow up with an example:

```scala
val a = 2 + 1
val e = a + 1
val p = e + e
```

Our `e` is `a + 1`. Our program `p` has two appearances of `e`.

In its current shape, the value of `p` can be computed by calculating `a`, `e` and `p` in that order:

```
a = 2 + 1 = 3
e = a + 1 = 3 + 1 = 4

p = e + e = 4 + 4 = 8
```

If we can apply the replacement of `e` in the original program with the result of evaluating `e` (`a + 1`), then `e` is referentially transparent. Let's do that:

```scala
val a = 2 + 1
val p = (a + 1) + (a + 1)
```

What's the value of `p` now?

`p = ((2 + 1) + 1) + (2 + 1) + 1) = (3 + 1) + (3 + 1) = 4 + 4 = 8`

As you see, the value of `p` hasn't changed. The behavior of the program `p` didn't change either, as its only effect was computing the value (which is `8`). That means `e` was referentially transparent - we replaced the reference to a value (`e`) with the value (`a + 1`).

This is very much like math from school - you didn't see anything impure in your textbooks, all your expressions were pure, and you could apply substitution in a similar way:

```
f(x) = x + 1

g(x) = f(x + 1) + f(x)
g(x) = ((x + 1) + 1) + (x + 1) = 2x + 3
```

So far, no side effects. Let's introduce some:

```scala
val x = {
  println("Foo")
  1
}

val p = x + x
```

If we ran the above lines in a REPL session, or as part of a larger program, the effects would be:

- the value of `p` becomes `2` (every time)
- the line `Foo` is printed to console output once.

What would happen if we inlined `x` into the places where it's used?

```scala
val p = {
  println("Foo")
  1
} + {
  println("Foo")
  1
}
```

Now, if we ran the above lines, the result would be vastly different from the previous one, perhaps unsurprisingly:

- the value of `p` still becomes `2` (every time)
- the line `Foo` is printed to console output **twice**.

Unless all the effects of your programs are idempotent (running them multiple times yields the same result as running them once), which I doubt, then this should feel troubling: after all, the only thing we did was inline a read-only variable (`val x`). And now the program behaves in a different way.

That's precisely because the implementation of `x` was impure - it had a secondary effect (or a side effect) of console output. This could just as well be a database-mutating call, or a `HTTP POST` request being sent to a remote server. In many cases, it would become a bug.

There are other ways to break referential transparency. If the value of `x` depended on external conditions (like if it was getting its value from console input), the correctness of the program after inlining could break in many more ways:

```scala
val x = StdIn.readLine()

val prog1 = (x, x)
val prog2 = (StdIn.readLine(), StdIn.readLine())

val b = prog1 == prog2
```

In the above code, the tuple contained by `prog1` will always have the same value in both fields. In fact, if we only ran the code up to the definition of `prog1`:

```scala
val x = StdIn.readLine()

val prog1 = (x, x)
```

We would be asked to enter console input once, and the value we typed would be stored in `x` for as long as `x`'s lifetime lasts. Because of that, it'd appear twice in `prog1`.

However, if we only ran the line where `prog2` is defined:

```scala
val prog2 = (StdIn.readLine(), StdIn.readLine())
```

We would be asked for input **twice**, and assuming there are `n` possible strings we could input, the chance that both values in `prog2` would be the same would be equal to only `1/n` (as opposed to `100%` in `prog1`). And the only difference between `prog1` and `prog2` was the inlining of `x = StdIn.readLine()`.

There are many other ways to break referential transparency in Scala, for example throwing exceptions:

```scala
val prog1 = Try(throw new Exception)

val x = throw new Exception
val prog2 = Try(x)
```

or executing any kind of impure logic inside `scala.concurrent.Future`:

```scala
val x = Future { println("Foo") }

val prog1 = (x zip x)
val prog2 = (Future { println("Foo") } zip Future { println("Foo") })
```

`Future` behaves just like a raw, uncut side effect: its value is cached, so regardless of how many times you use an already created `Future`, it'll only run once and it'll always contain the same value upon completion or failure. That's because `Future` isn't a description of an asynchronous computation: it's already running one.

If we can't rely on `Future` to give us the safety of refactoring (inlining values or extracting expressions to values), does it mean we're doomed to have side effects in meaningful Scala programs?

Thankfully, it doesn't.

## First-class effects

A term often used to describe effects without side effects is "first class effects". They are effects that don't break referential transparency. A workaround often used to simulate support for first class effects in Scala involves by-name parameters:

```scala
//artificial type
final class Effectful[T] private(run: () => T) {
  def zip[U](b: Effectful[U]): Effectful[(T, U)] = new Effectful(() => (run(), b.run()))
}

//function with by-name parameter
def effect[T](f: => T): Effectful[T] = new Effectful(() => f)

val x = effect(println("Foo"))

val prog1 = x zip x

val prog2 = effect(println("Foo")) zip effect(println("Foo"))
```

In this example, we created a new, "artificial" type `Effectful[T]` (it's probably not a good idea to try and come up with a type like this on your own). It describes a computation that will complete with a value of type `T`. We gave it a method `zip` that will produce a new `Effectful` that will run two `Effectful` programs sequentially.

If we were to call `prog1.run()` or `prog2.run()`, you'd see that they behave identically - they'll both print `Foo` twice.

Thankfully, we don't need to come up with a type like this (and I don't recommend that you do - unless you're absolutely sure the existing ones don't meet your needs).

There's plenty of competing options one can use in a similar way to how we used `Effectful` and `def effect`. 
Here are a few that are the most popular in late 2018:

- cats-effect `IO[+A]`
- scalaz-zio `IO[+E, +A]`
- Monix `Task[+A]`.

From the referential transparency/purity point of view, they behave in the same way - if we "suspend" side-effecting operations using an operator that allows "delaying" a computation (for example, by taking a by-name parameter), they'll give us the properties we need. One significant difference in the above is in terms of error handling - `zio` allows an `IO` to fail with an error value of type `E` that you can specify on your own, but the other two (cats-effect IO and Monix Task) only allow failure with values that extend `Throwable`. Whether one solution has significant advantages over the other is a question for a different post ;)

All things considered, all of the above types support suspending synchronous effects (like printing to standard output, or executing a JDBC call) and asynchronous, non-blocking effects (like communicating through HTTP or listening for messages from Kafka). The main difference between these types and `Future` is that they are able to *describe a computation* that can be ran at some point after they're defined, while `Future` is a handle to an already running computation.

For the next part of the post, I'll use cats-effect's `IO`.

Let's recreate the printing example that we were able to make referentially transparent with `Effectful`:

```scala
import cats.syntax.apply._
import cats.effect.IO

//expands to `IO.apply(println(...))`, defined as `def apply[T](f: => T): IO[T]`
//`IO.apply` is equivalent to `IO.delay`
val x = IO(println("Foo"))

val prog1 = (x, x).tupled

val prog2 = (IO(println("Foo")), IO(println("Foo"))).tupled
```

Again, running `prog1` and/or `prog2` will involve printing twice in each of them. That's why we say IO is referentially transparent, or pure.

## A word on determinism and IO

Earlier, I claimed that a function needs to return the same output for the same input. Would this be a function, then?

```scala
def foo: IO[Int] = IO {
  Random.nextInt()
}
```

Some people would argue that it's not - because it's not deterministic. They argue that calling `foo` multiple times will give you different results. But that's not true - just calling `foo` always gives you the same action - nothing happens until you evaluate the IO. In fact, the whole function could be a constant:

```scala
val foo: IO[Int] = IO { Random.nextInt() }
```

And as a constant it must be deterministic. The fact that evaluating it multiple times will give us different results doesn't matter. One of the points of functions being deterministic is to allow storing them as values, and reusing them. Take a look:

```scala
def foo(i: Int): IO[Unit]
val program = foo(5) *> bar <* foo(5)

val program2 = baz <* foo(5)
```

Because all the calls to `foo` are the same, we can store the result of such a call and reuse it, while maintaining the original behavior:

```scala
def foo(i: Int): IO[Unit]

val foo5: IO[Unit] = foo(5)

val program = foo5 *> bar <* foo5

val program2 = baz <* foo5
```

"How do we evaluate an IO?", you may ask. I'll respond, "with IOApp" (for example):

```scala
import cats.effect._
import cats.implicits._

object Main extends IOApp {
  def run(args: List[String]): IO[ExitCode] = {
    val foo = IO(println("Foo"))
    
    foo *> foo *> foo
  }.as(ExitCode.Success)
}
```

## Thanks for reading

I hope that you liked this not-so-short explanation of pure functions and that you'll benefit from it as much as me and other people who believe in functional programming. If you still have any questions, feel free to reach out to me in the comments or through my Twitter/email :)

If you think this post helped you, please share it on Twitter/Reddit/whatever you like. And while you're at it, please leave a comment ;)

If you want to keep an eye out for the next thing I write, follow me and I'll make sure you don't miss anything readworthy.

## Links

To learn more about referential transparency, first-class effects and IO, check out [the documentation of cats.effect.IO](https://typelevel.org/cats-effect/datatypes/io.html), or [Fabio Labella's comments in this Reddit thread](https://www.reddit.com/r/scala/comments/8ygjcq/can_someone_explain_to_me_the_benefits_of_io/e2jfp9b). You may also want to see [Luka Jacobowitz's talk about the other benefits of RT](https://www.youtube.com/watch?v=X-cEGEJMx_4), [Rob Norris's introduction to Effects](https://www.youtube.com/watch?v=po3wmq4S15A) and [Fabio's talk about shared mutable state in pure FP](https://vimeo.com/294736344
).

If you don't mind seeing a bunch of slides without an audible explanation, you can also check out [the slides for my latest talk](https://kubukoz.github.io/talks/incremental-purity/slides), but sooner or later I'm planning to have it recorded and the video published.

For examples with ZIO, see [ZIO's page on purity](https://scalaz.github.io/scalaz-zio/usage/purity.html).

I also recommend following [the Typelevel blog](https://typelevel.org/blog/) and chatting to folks who love FP on [the cats gitter](https://gitter.im/typelevel/cats) and [other](https://gitter.im/typelevel/cats-effect) related [rooms](https://gitter.im/typelevel/general).
