# FAQ

Here are some questions that I've answered at least a few times on the Internet, on conferences or at work. Hopefully you'll find the answers to some of yours here.

## Why are there no Cats instances for `Seq`?

TODO fact check

`Seq` is a very general type. Subtypes of this type are, amongst others, `List` and `Stream`. Because of that, an instance of e.g. `Traverse[Seq]` won't know about some important characteristics of the actual type of the collection it's traversing: for example, `Stream` is lazy and memoizes its elements. In fact, it is potentially infinite (up to the limits of stack space).

Also, due to subtyping and the Liskov Substitution Principle, `Traverse[Seq]` given a List should work in the same way as `Traverse[List]` does.
