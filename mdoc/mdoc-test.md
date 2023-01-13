+++
title = "Mdoc in nix"
date = "2023-01-13"

[taxonomies]
tags = ["scala", "functional-programming"]

[extra]
scalaLibs = ["colorize-0.1"]
+++


Hello world! This is an mdoc post built with Nix, which declares its own Scala dependencies.

```scala mdoc
import org.polyvariant.colorize._


println("hello".red.render)
```
