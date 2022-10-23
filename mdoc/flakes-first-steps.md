+++
title = "Nix Flakes: first steps"
date = "2022-10-22"

[taxonomies]
tags = ["nix"]
+++

I keep getting questions about how to start with Nix. I believe the way to go in 2022 is to start with Flakes, so in this post I'll describe just that.

<!-- more -->

## What is Nix?

If you're one of the people trying to learn Nix, you probably don't need much of an introduction to the idea.
Regardless, I'd like to have a couple sentences about Nix that'll make it more familiar to people who haven't heard about it.

---

[Nix](https://nixos.org/) is a purely functional package manager.
It has a unique combination of features that make it an interesting tool that can be used to solve a variety of problems - one of which is building a website (which is exactly how the page you're reading was produced).

## What are flakes?

Nix Flakes are a (currently) experimental feature of Nix, and they've been present in the default distributions of Nix since release 2.4.
The "experimental" part sounds scary, but it's been a rather stable experience for years now, and it's probably a matter of (less rather than more) time until they are considered stable.

As an intuition, we can treat a flake as something similar to a Git repository.
Very often, that happens to be an accurate analogy, because people tend to host their flakes on a service like [GitHub](https://github.com), but that's not a requirement - rather a special case.

In fact, Nix supports that special case rather well, because syntax like `github:kubukoz/blog` is a valid representation of a flake input (which happens to link to this blog's repository).
For the remaining ways to refer to a flake, check out [the documentation](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-inputs).

Flakes can depend on each other, and any dependencies are pinned in a lockfile named `flake.lock` (currently using a JSON encoding). They can also _output_ certain things, such as package definitions. The inputs (the dependencies) can be used to produce these outputs in a reproducible way.

If you want to learn more, there's [documentation](https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html) for the flake CLI, as well as [a wiki entry](https://nixos.wiki/wiki/Flakes) and [other](https://serokell.io/blog/practical-nix-flakes) [blog](https://xeiaso.net/blog/nix-flakes-1-2022-02-21) [posts](https://ghedam.at/a-tour-of-nix-flakes) trying to introduce you to flakes.

For now, let's try to use the feature, and hopefully, we'll get a better understanding of it along the way.

## Enabling flakes

First of all, you need Nix installed. Follow [the official installation guide](https://nixos.org/download.html) for your system.

[The wiki](https://nixos.wiki/wiki/Flakes) lists several ways to enable flakes. I prefer this one:

Create the file `~/.config/nix/nix.conf` (if it doesn't exist) and add this line to it:

```conf
experimental-features = nix-command flakes
```

## Using flakes

The beauty of flakes is that you can build an arbitrary flake's output without dealing with the Nix language.

Now that you have enabled Flakes, you can run this:

```bash
nix build nixpkgs#hello

./result/bin/hello
```

and the `hello` package from Nixpkgs will be built with Nix (or, more likely, fetched from a [cache](https://cache.nixos.org)).
The action will produce `./result`, a symlink to a read-only directory in the Nix store (`/nix/store`).
`./result/bin/hello` runs the program.

It's time to make our own flake.

## Your first flake

The simplest flake possible is one with no outputs:

```nix
{
  outputs = _ : {};
}
```

We'll talk about syntax later.

Save this as `flake.nix` in a new directory and you'll be able to run:

```bash
nix flake check
```

The command should succeed with no output.

Let's make our flake a little more complicated.

![Draw the rest of the owl](/images/rest-of-owl.jpg)

```nix
{
  outputs = { self, nixpkgs }:
    let
      system = builtins.currentSystem;
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${builtins.currentSystem}.default = pkgs.mkShell {
        packages = [ pkgs.hello ];
      };
    };
}
```

I know, that's a lot, but I promise we'll talk about it once we get it to work.

Save the file and run `nix flake check` again. It might take a little while, but ultimately you should see the following happen:

- A `flake.lock` file is created
- The command fails spectacularly:

  ```
  warning: creating lock file '/Users/kubukoz/projects/flake-demos/flake.lock'
  error: attribute 'currentSystem' missing

        at /nix/store/g2c7l0j12pdb6k9lij1i584khhna49d9-source/flake.nix:8:19:

              7|     {
              8|       devShells.${builtins.currentSystem}.default = pkgs.mkShell {
              |                   ^
              9|         packages = [ pkgs.hello ];
  (use '--show-trace' to show detailed location information)
  ```

There's a reason why it failed. You can get it to succeed if you add `--impure`, but as you can guess we'll try to get rid of that soon.

```bash
nix flake check --impure
```

Let's talk about what we've done so far. Specifically, let's talk about syntax!

## Nix syntax 101

In general, a Nix file contains a Nix expression. These are quite similar to JSON (see [manual for the Nix syntax](https://nixos.org/manual/nix/stable/language/index.html)).
Compare the following:

```json
{
  "name": "Jakub",
  "age": -1,
  "languages": ["Polish", "English"],
  "uses_nix": true
}
```

This translates to the following Nix:

```nix
{
  name = "Jakub";
  age = -1;
  languages = ["Polish" "English"];
  uses_nix = true;
}
```

You should note the following key differences:

- entries in the object (Nix calls these _attribute sets_, or attrsets) are separated with semicolons
- a semicolon is required after each entry, including the last
- keys/values are separated with the equals sign
- keys aren't wrapped in quotes
- array elements are separated with whitespace.

## Nix syntax 102: functions

In addition to features known from formats like JSON, Nix has functions.
Functions in Nix are anonymous (lambdas), and they always take one argument each (multi-parameter functions are emulated either by means of currying or wrapping a ).

This is the general syntax for a function literal:

```nix
input : body
```

Looks familiar? We saw a similar one in the first flake we've made:

```nix
{
  outputs = _ : {};
}
```

Here, we're seeing a new piece of syntax: the underscore. That just means we ignore the input and don't give it a name.
Here's our initial flake, annotated:

```nix
# By the way, this is a line comment.
/* Nix also has multi-line comments. */
# This object right here defines a flake. You'll see an object on the top level of every Nix flake in existence.
{
  # `outputs` is a special name in Nix which lets the tools know about all the possible outputs of a flake.
  # It is a function that returns the outputs, and it receives the flake's inputs as the argument.
  outputs =
    # We don't produce any outputs, so we don't need any inputs. Thus, we ignore the argument.
    _ :
    # Returning an empty object.
    {};
}
```

## A flake as a function

Just to repeat and rephrase: a flake's `outputs` attribute is a function from that flake's inputs to its outputs.

In the second flake, we saw this as the definition of `outputs`:

```nix
{
  outputs = { self, nixpkgs } : {/* more stuff below */};
}
```

<!-- todo talk about nixpkgs, self... explain second flake -->
