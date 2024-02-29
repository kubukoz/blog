+++
title = "Flavors of shared state in Cats Effect"
date = "2024-03-01"

[taxonomies]
tags = [ "scala", "functional programming", "cats"]

[extra]
disqus.enable = true
disqus.ident_suffix = "?disqus_revision=1"

scalaLibs = ["cats-effect-3.5.3", "http4s-client-0.23.25"]
+++

In this post, we will explore the various ways to share state in a Cats Effect application, including their combinations.

<!-- more -->

# Introduction: why do we need shared state?

One may think that Functional Programming eliminates the need for shared state altogether - however, sooner or later, we have to interact with the so called "Real World". Turns out, the world is ~~a JoJo reference~~ a stateful thing, so interacting with it requires some form of [effects](https://typelevel.org/cats-effect/docs/concepts#effects).

As if that wasn't enough, sometimes we want to keep some state in our own application: even something like a "request counter", which keeps a running total of the requests handled by the service, requires some form of shared in-memory state.

Then we have more complex concepts such as connections, resource pools, queues, rate limiters and so on, all of which are by nature stateful as well.

<!-- this might need cleaning up but I think that's the gist -->

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

We can now share that counter in a concurrent scenario:

```scala mdoc:silent
import cats.implicits.*

val useCounter = for {
  counter <- refCounter
  _       <- counter.increment
  _       <- counter.increment
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

A request handler may look like this (with http4s):

```scala mdoc
import org.http4s.*
import org.http4s.client.Client

def sampleRequest(client: Client[IO]): IO[Unit] = client.run(Request()).use_
```

```scala mdoc:compile-only
def routes(client: Client[IO]): HttpRoutes[IO] = HttpRoutes.of[IO] {
  case _ =>
    sampleRequest(client) *>
      sampleRequest(client) *>
      IO.pure(Response())
}
```

Can we use `refCounter` for this purpose? Sure, why not. We'll increment before the request, to avoid dealing with error handling. We'll also print the final value before returning the response:

```scala mdoc:compile-only
def routes(client: Client[IO]): HttpRoutes[IO] = HttpRoutes.of[IO] {
  case _ =>
    refCounter.flatMap { c =>
      c.increment *>
        sampleRequest(client) *>
        c.increment *>
        sampleRequest(client) *>
        c.get.flatMap(IO.println) *>
        IO.pure(Response())
    }
}
```

It... does work. Notably, we can't put the `refCounter.flatMap` part outside of our router, as that'd make the counter shared across all requests.

Let's hide the increments in a client middleware, to declutter the code a bit:

```scala mdoc:compile-only
def withCount(client: Client[IO], counter: Counter): Client[IO] = Client { req =>
  counter.increment.toResource *>
    client.run(req)
}

def routes(client: Client[IO]): HttpRoutes[IO] = HttpRoutes.of[IO] {
  case _ =>
    refCounter.flatMap { c =>
      val countedClient = withCount(client, c)

      sampleRequest(countedClient) *>
        sampleRequest(countedClient) *>
        c.get.flatMap(IO.println) *>
        IO.pure(Response())
    }
}
```

It still feels cluttered, doesn't it? Also, that's probably the most obvious problem with our example - but there's an even more serious one that's likely to bite us in something real. Let's discuss that.

In our example, the client calls are happening directly in the route (the request handler). However, in a real application it's very likely to be wrapped in at least one layer of abstraction: this could be a `UserService`, which would in turn use a `UserClient`, which would be the one actually using `Client`.

It might look a little like this:

```scala
def routes(userService: UserService[IO]): HttpRoutes[IO] = HttpRoutes.of[IO] {
  case POST -> Root / "users" / id =>
    userService.find(id).flatMap {
      case None => NotFound()
      case Some(u) => userService.notify(u, SubscriptionExpired())
    }
}
```

In such a design, the http4s `Client` is nowhere to be seen - it's encapsulated in the definition of `UserService` (and possibly even further). How do we tell it about the counter, then? Do we add a `Counter` parameter to all the methods of `UserService` and its dependencies, all the way until we have access to the http4s `Client`?

Well, that'd work, but it'd certainly go against the point of all this abstraction. Surely we can find something else.

All we need is to propagate the `Counter` from our request handler to the client. If this sounds to you like a reader monad, that's certainly one tool to achieve this! However, we're not always going to be able to use it:

- it implies that `UserService`'s methods have a reader monad in their return types
  - this means that we either use polymorphic effects (AKA Tagless Final), or hardcode the exact reader monad with the exact type of context that we we need (`Counter`)
- this approach is still "viral", i.e. it infects the interfaces of not only `UserService`, but also its peers (the `UserClient` mentioned earlier)

So let's not do that here. If we're not going to pass the counter as parameters (or a reader monad), could we inject the counter to the `UserService` at construction time, then?

```scala
def routes(mkUserService: Counter => UserService[IO]): HttpRoutes[IO] = HttpRoutes.of[IO] {
  case POST -> Root / "users" / id =>
    refCounter.flatMap { counter =>
      val userService = mkUserService(counter)

      userService.find(id).flatMap {
        case None => NotFound()
        case Some(u) => userService.notify(u, SubscriptionExpired())
      }
    }
}
```

Looks like we can. However, this is a bit of a code smell: the fact that `UserService` depends (indirectly) on the counter is now visible to our routing. In addition, whenever we receive a request, we have to construct not only a `UserService`, but also every component that carries the `Counter` dependency. We'd have to measure the performance impact of such allocations on the hot path, and it'd certainly have severe implications if any of these components are stateful themselves.

We won't be doing that, then. So what are our demands?

- The counter dependency should be hidden from intermediate layers of abstraction (only the client and router need to know about it)
- The counter's state should be isolated between requests, including concurrent ones.

Readers with Java experience may recognize this as something similar to `ThreadLocal`. However, in Cats Effect we can't simply use a `ThreadLocal`, because a single request may be processed on any number of threads (and on non-JVM platforms like Scala.js, we might not have more than one thread to begin with). What we need is more like a... "fiber" local.

Cats Effect provides an `IOLocal`.
