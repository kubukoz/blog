+++
title = "Flavors of shared state in Cats Effect"
date = "2024-03-01"

[taxonomies]
tags = [ "scala", "functional programming", "cats"]

[extra]
disqus.enable = true
disqus.ident_suffix = "?disqus_revision=1"

scalaLibs = ["http4s-client-0.23.25", "http4s-dsl-0.23.25"]
+++

In this post, we will explore the various ways to share state in a [Cats Effect](https://typelevel.org/cats-effect) application.

<!-- more -->

# Introduction: why do we need shared state?

One may think that Functional Programming eliminates the need for shared state altogether - however, sooner or later, we have to interact with the so called "Real World". Turns out, the world is ~~a JoJo reference~~ a stateful thing, so interacting with it requires some form of [effects](https://typelevel.org/cats-effect/docs/concepts#effects).

As if that wasn't enough, sometimes we want to keep some state in our own application: even something like a "request counter", which keeps a running total of the requests handled by the service, requires some form of shared in-memory state.

Then we have more complex concepts such as connections, resource pools, queues, rate limiters and so on, all of which are by nature stateful as well.
Let's take Cats Effect for a spin and see what tools we can use to build such mechanisms.

## Working example: simple counter

Following the idea of a request counter, let's use this concept for our example.

Our counter will have two operations:

```scala mdoc
import cats.effect.IO

trait Counter {
  def increment: IO[Unit]
  def get: IO[Int]
}
```

## Starting simple: `Ref`

First, we'll define a helper to reduce the boilerplate in our implementations:

```scala mdoc
def makeCounter(inc: IO[Unit], retrieve: IO[Int]): Counter = new {
  val increment: IO[Unit] = inc
  val get: IO[Int] = retrieve
}
```

Now let's try and implement the counter with our good old friend, `cats.effect.kernel.Ref`.

```scala mdoc:silent
// conveniently aliased
import cats.effect.Ref

val refCounter: IO[Counter] = Ref[IO].of(0).map { ref =>
  makeCounter(
    ref.update(_ + 1),
    ref.get
  )
}
```

We can now instantiate such a counter and use it, including in concurrent scenarios:

```scala mdoc:silent
import cats.implicits.*

val useCounter = for {
  counter <- refCounter
  _       <- counter.increment.parReplicateA(2)
  v       <- counter.get
} yield v
```

Let's see what that gives us:

```scala mdoc
import cats.effect.unsafe.implicits.*
useCounter.unsafeRunSync()
```

Clearly, some sharing happened: the value was updated twice!

What are the characteristics of this counter?

- It can be atomically updated from multiple fibers
- The count is shared everywhere within the scope where the counter is visible, i.e. within the for comprehension.

That makes it suitable for a counter of all requests an application has received while it's up. However, let's imagine we need some more isolation: let's try to count all _client requests_ that we've made while handling a _server request_.

We'll make the simplest client call possible:

```scala mdoc
import org.http4s.*
import org.http4s.client.Client

def sampleRequest(client: Client[IO]): IO[Unit] = client.run(Request()).use_
```

and our request handler may look like this (with http4s):

```scala mdoc:compile-only
def routes(client: Client[IO]): HttpRoutes[IO] = HttpRoutes.of[IO] {
  case req =>
    sampleRequest(client) *>
      sampleRequest(client) *>
      IO.pure(Response())
}
```

Can we use `refCounter` for this purpose? Sure, why not. We'll increment before the request, to avoid dealing with error handling. We'll also return the final value in the response:

```scala mdoc
def routes(client: Client[IO]): HttpRoutes[IO] = HttpRoutes.of[IO] {
  case req =>
    refCounter.flatMap { c =>
      c.increment *>
        sampleRequest(client) *>
        c.increment *>
        sampleRequest(client) *>
        c.get.map(_.show).map(Response().withEntity(_))
    }
}
```

Let's try it out:

```scala mdoc
def testRoute(route: Client[IO] => IO[HttpRoutes[IO]]): IO[List[String]] = {
  // our fake client, which simply succeeds
  val c = Client.fromHttpApp[IO](HttpApp.pure(Response()))

  // build the route: the "IO" part will be useful later
  route(c).flatMap { handler =>
    // run the route with a simple request and grab its body
    val runAndGetBody = handler.orNotFound.run(Request()).flatMap(_.bodyText.compile.string)

    // Run the request 10 times in parallel
    runAndGetBody
      .parReplicateA(10)
  }
}
// validate results
.flatTap {
  case results if results.forall(_ == "2") => IO(println("Success!"))
  case results                             => IO(println("Failure!"))
}
```

```scala mdoc
testRoute(client => IO.pure(routes(client))).unsafeRunSync()
```

It... does work. Notably, we can't put the `refCounter.flatMap` part outside of our router, as that'd make the counter shared across all requests: remember, we wanted to isolate the counts of each request we handle.

Let's hide the increments in a client middleware, to declutter the code a bit:

```scala mdoc
def withCount(client: Client[IO], counter: Counter): Client[IO] = Client { req =>
  counter.increment.toResource *>
    client.run(req)
}
```

Now here's the updated routing code:

```scala mdoc:compile-only
def routes(client: Client[IO]): HttpRoutes[IO] = HttpRoutes.of[IO] {
  case _ =>
    refCounter.flatMap { c =>
      val countedClient = withCount(client, c)

      sampleRequest(countedClient) *>
        sampleRequest(countedClient) *>
        c.get.map(_.show).map(Response().withEntity(_))
    }
}
```

It still feels cluttered, doesn't it? Also, that's probably the most obvious problem with our example - but there's an even more serious one that's likely to bite us when we try to build something real. Let's discuss that.

In our example, the client calls are happening directly in the route (the request handler). However, in a real application it's very likely to be wrapped in at least one layer of abstraction: this could be a `UserService`, which would in turn use a `UserClient`, which would be the one actually using `Client`.

It might look a little like this:

```scala mdoc:invisible
case class SubscriptionExpired()
trait UserService[F[_]] {
  type User
  def find(id: String): F[Option[User]]
  def notify(u: User, e: SubscriptionExpired): F[Unit]
}

import org.http4s.dsl.io.*
```

```scala mdoc:compile-only
def routes(userService: UserService[IO]): HttpRoutes[IO] = HttpRoutes.of[IO] {
  case POST -> Root / "users" / id =>
    userService.find(id).flatMap {
      case None => NotFound()
      case Some(u) => userService.notify(u, SubscriptionExpired()) *> NoContent()
    }
}
```

In such a design, the http4s `Client` is nowhere to be seen - it's encapsulated in the definition of `UserService` (and possibly even further). How do we tell it about the counter, then? Do we add a `Counter` parameter to all the methods of `UserService` and its dependencies, all the way until we have access to the http4s `Client`?

Well, that'd work, but it'd certainly go against the point of all this abstraction. Surely we can find something else.

All we need is to propagate the `Counter` from our request handler to the client. If this sounds to you like a `Reader` monad, that's certainly one tool to achieve this! However, we're not always going to be able to use it:

- it implies that `UserService`'s methods have a reader monad in their return types
  - this means that we either use polymorphic effects (AKA Tagless Final), or hardcode the exact reader monad with the exact type of context that we we need (`Counter`)
- this approach is still "viral", i.e. it infects the interfaces of not only `UserService`, but also its peers (the `UserClient` mentioned earlier)

So let's not do that here. If we're not going to pass the counter as parameters (or a reader monad), could we inject the counter to the `UserService` at construction time, then?

```scala mdoc:compile-only
def routes(mkUserService: Counter => UserService[IO]): HttpRoutes[IO] = HttpRoutes.of[IO] {
  case POST -> Root / "users" / id =>
    refCounter.flatMap { counter =>
      val userService = mkUserService(counter)

      userService.find(id).flatMap {
        case None => NotFound()
        case Some(u) => userService.notify(u, SubscriptionExpired()) *> NoContent()
      }
    }
}
```

Looks like we can. However, this is a bit of a code smell: the fact that `UserService` depends (indirectly) on the counter is now visible to our routing. In addition, whenever we receive a request, we have to construct not only a `UserService`, but also every component that carries the `Counter` dependency. We'd have to measure the performance impact of such allocations on the hot path, and it'd certainly have severe implications if any of these components are stateful themselves.

We won't be doing that, then. So what are our demands?

- The counter dependency should be hidden from intermediate layers of abstraction (only the client and router need to know about it)
- The counter's state should be isolated between requests, including concurrent ones.

Readers with Java experience may recognize this as something similar to `ThreadLocal`. However, in Cats Effect we can't simply use a `ThreadLocal`, because due to its [fiber-based concurrency model](https://typelevel.org/cats-effect/docs/thread-model), a single request may be processed on any number of threads (and on non-JVM platforms like Scala.js, we might only have one thread to begin with).

What we need is more of a... "fiber" local.

## Isolated state with `IOLocal`

Cats Effect provides an `IOLocal`. It does exactly what we want! Let's implement the counter with it:

```scala mdoc:silent
import cats.effect.IOLocal

val localCounter: IO[Counter] = IOLocal(0).map { ref =>
  makeCounter(
    ref.update(_ + 1),
    ref.get
  )
}
```

Now, we can create one `IOLocal`-backed Counter for our entire application, and share it.
As a good practice we'll reset each counter after each server request finishes processing (just in case any fibers are recycled between serial requests), but in reality it's likely that we'll just get a new fiber for each request.

For this, we'll need to enhance our definition of `localCounter` with the ability to reset it after we're done. I'm choosing to do this by composition, although inheritance could also be a reasonable choice:

```scala mdoc:silent
import cats.~>
import cats.effect.Resource

case class CounterWithReset(c: Counter, withFreshCounter: IO ~> IO)

val localCounterR: IO[CounterWithReset] = IOLocal(0).map { ref =>
  val c = makeCounter(
    ref.update(_ + 1),
    ref.get
  )

  CounterWithReset(c, Resource.make(IO.unit)(_ => ref.reset).surroundK)
}
```

We'll also need to enhance our router so that it actually resets the local. Let's make another middleware:

```scala mdoc
import cats.data.Kleisli
import cats.data.OptionT

def withCountReset(r: HttpRoutes[IO], c: CounterWithReset): HttpRoutes[IO] = Kleisli { req =>
  OptionT {
    c.withFreshCounter(r.run(req).value)
  }
}
```

If you want to be more concise:

```scala mdoc:compile-only
def withCountReset(r: HttpRoutes[IO], c: CounterWithReset): HttpRoutes[IO] =
  r.mapF(_.mapK(c.withFreshCounter))
```

Now we're armed and we can get to the action:

```scala mdoc
def appR(rawClient: Client[IO]): IO[HttpRoutes[IO]] =
  // 1
  localCounterR.map { counterWithReset =>
    val counter = counterWithReset.c

    // 2
    val client = withCount(rawClient, counter)

    // 3
    val r = routes(client, counter)

    // 4.
    withCountReset(
      r,
      counterWithReset
    )
  }

def routes(client: Client[IO], c: Counter): HttpRoutes[IO] = HttpRoutes.of[IO] {
  case _ =>
    sampleRequest(client) *>
      sampleRequest(client) *>
      c.get.map(_.show).map(Response().withEntity(_))
}
```

And we've achieved our desired goal! To sum up, here's what's happening:

1. We create an `IOLocal`-based counter and open a scope of sharing by mapping on it. The resultant `IO` can be flatMapped on directly in your IOApp, as soon as you have a Client. If you only `flatMap` once, you'll have a globally-shared `IOLocal` (which is likely what you want).
2. We wrap the "real" http4s Client with middleware that increments the count before sending any request.
3. We pass the wrapped client to the routes. In the `UserService` example above, at this point we could deal with the construction of any `UserService` dependencies, and it'd only happen once, instead of on every request.
4. We wrap the routes in middleware that resets the counter after processing each request.

Let's test that as well:

```scala mdoc
testRoute(appR).unsafeRunSync()
```

So... is that it? Well, sort of.

## Child fibers

In our desire to share the `Counter` instance across the entire app, we've forgotten something important: we actually want some isolation. And yes, we do have isolation between the requests processed by the application, but what if the request itself is split into multiple fibers?

What if the route actually looks like this?

```scala mdoc:compile-only
def routes(client: Client[IO], c: Counter): HttpRoutes[IO] = HttpRoutes.of[IO] {
  case _ =>
    (
      sampleRequest(client) &>
      sampleRequest(client)
    ) *> c.get.map(_.show).map(Response().withEntity(_))
}
```

It's a critical difference: the two requests will now be executed in parallel. Because `IOLocal` doesn't propagate changes from a child fiber to its parent, the global counter will now be unaffected by anything that's been forked! This could be a problem. And it is!

<details style="background-color: #eee">

<summary style="display: list-item">Some boilerplate to prepare for that test run</summary>

```scala mdoc
def appRWithParallel(rawClient: Client[IO]): IO[HttpRoutes[IO]] =
  localCounterR.map { counterWithReset =>
    val counter = counterWithReset.c
    val client = withCount(rawClient, counter)
    val r = routesWithParallel(client, counter)
    withCountReset(r, counterWithReset)
  }

def routesWithParallel(client: Client[IO], c: Counter): HttpRoutes[IO] = HttpRoutes.of[IO] {
  case _ =>
    (
      sampleRequest(client) &>
      sampleRequest(client)
    ) *> c.get.map(_.show).map(Response().withEntity(_))
}
```
</details>

```scala mdoc
testRoute(appRWithParallel).unsafeRunSync()
```

Here's the thing: `Ref` didn't care about the fibers' family drama. If only we could pick and choose which parts of `IOLocal` and `Ref` we get...

Well, why don't we? Why don't we put a `Ref` inside `IOLocal`? Let's ponder:

`IOLocal[A]` ensures that updates of `A` are not propagated to parent/child fibers. This can be done without inspecting the internals of the `A` value, by relying on its immutability to avoid sharing changes.

If `A` contains mutable state (which `Ref` pretty much is), you could mutate that state without ever calling `update` on the `IOLocal`... and it'll be visible in all offspring of the fiber that inserted that value.

Here's what this trick would look like: we can use `CounterWithReset` to encapsulate the "swapping" of the Ref for each request:

```scala mdoc:silent
val localRefCounter: IO[CounterWithReset] =
  // 1
  Ref[IO].of(0).flatMap(IOLocal(_)).map { local =>
    // 2
    val c = makeCounter(
      local.get.flatMap(_.update(_ + 1)),
      local.get.flatMap(_.get)
    )

    // 3
    val withFreshK = Resource.make(Ref[IO].of(0).flatMap(local.set))(_ => local.reset).surroundK

    // 4
    CounterWithReset(c, withFreshK)
  }
```

This may be a lot to take, so let's go through the steps one by one:

1. We create a `Ref` as an initial value for the `IOLocal`. You could avoid this by making the `IOLocal` store an `Option[Ref]`, but I figured this would make it easier to implement the other parts. That `Ref` is immediately used to create the `IOLocal`.
2. We make a `Counter` instance based on the composed `IOLocal` and `Ref`. Neither of the methods of the counter actually update the Local: they both read from it and then behave just like a normal `Ref`-based counter would.
3. Before each request, we'll create a fresh `Ref` and put it into the Local. Afterwards, we'll reset the Local to its previous state, for good measure.
4. Finally, we return the counter with its reset button.

The usage of `localRefCounter` is identical to that of `localCounterR`.

<details style="background-color: #eee">

<summary style="display: list-item">Some boilerplate to prepare for that test run</summary>

```scala mdoc
def appRWithParallelAndRef(rawClient: Client[IO]): IO[HttpRoutes[IO]] =
  localRefCounter.map { counterWithReset =>
    val counter = counterWithReset.c
    val client = withCount(rawClient, counter)
    val r = routesWithParallelAndRef(client, counter)
    withCountReset(r, counterWithReset)
  }

def routesWithParallelAndRef(client: Client[IO], c: Counter): HttpRoutes[IO] = HttpRoutes.of[IO] {
  case _ =>
    (
      sampleRequest(client) &>
      sampleRequest(client)
    ) *> c.get.map(_.show).map(Response().withEntity(_))
}
```
</details>

Does it resolve the issue?

```scala mdoc
testRoute(appRWithParallelAndRef).unsafeRunSync()
```

Apparently, it does!

## What about the opposite?

Perhaps you were wondering if we can flip the order of "state carriers" around and have `Ref[IO, IOLocal[A]]`. I would be inclined to say no, because the standard `Ref` implementation relies on a CAS (compare and set) loop for its updates, and that might not play well with how `IOLocal` is implemented. However, you're welcome to try... in a controlled environment :)

## Can we go deeper?

We've established that with the composition of `IOLocal` and `Ref` we have more control over when we "fork" the scope of our state than if we were using either of them separately.

Just how much control are we talking, exactly?

Turns out, we can freely "fork" whenever we want - just like we do in `withFreshK` - it's just a matter of exposing such a feature through our counter's API.

```diff
trait Counter {
  def increment: IO[Unit]
  def get: IO[Int]
+ def fork: IO ~> IO
}
```

It's worth noting that at this point we cannot really implement a valid `Counter` based on just a `Ref` - by giving out API more power, we've constrained the number of valid implementations - [constraints liberate, liberties constrain](https://www.youtube.com/watch?v=GqmsQeSzMdw).

Of course, if you want to control the value that forked counters will start with, you'll need to further adjust the API to accomodate that feature. This is left as [an exercise for the reader](https://en.wikipedia.org/wiki/Small_matter_of_programming).

### Trivia: Natchez's Trace algebra

[The Natchez library](https://github.com/typelevel/natchez), which is used for distributed tracing, uses a similar idea in its `Trace` algebra:

```scala
trait Trace[F[_]] {
  def span[A](name: String /*, ... */)(k: F[A]): F[A]
  // other methods here
}
```

Its two main implementations (based on `Kleisli` or `IOLocal`) both carry a `Span`, which is backed by mutable state - depending on the backend it's sometimes a `Ref`, sometimes a plain mutable object like an OpenTracing `Span`.

## Comparison

We've explored a bunch of options for sharing state, with various degrees of isolation. Which one should _you_ use?

It depends on the problem you're trying to solve. If your goal is to share the state for the entire application (for example, for a client's rate limiter), `Ref` will do just fine. If you want to prioritize isolation and avoid any race conditions, `IOLocal` may work well for you. However, if you want more precise control and the ability to "disconnect" from a more "global" state, it's likely that you'll want to wrap some mutable state in an `IOLocal` - such as a `Ref`.

Personally, I believe for most usecases in HTTP applications that desire "reader monad" semantics of state, `IOLocal` + `Ref` should be preferred over just `IOLocal`. Using the latter is likely to lead to subtle bugs, such as changes not being propagated upwards when a library down the call stack starts to involve concurrency.

I hope this article helps you make an informed decision. Thanks for reading!
