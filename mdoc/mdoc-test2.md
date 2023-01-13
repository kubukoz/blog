+++
title = "Mdoc in nix, vol 2"
date = "2023-01-13"

[taxonomies]
tags = ["scala", "functional-programming"]

[extra]
scalaLibs = ["colorize-0.3"]
+++

Same thing, but this one uses another version of the dependency.

```scala mdoc
import org.polyvariant.colorize._

println("hello".red.render)
```
