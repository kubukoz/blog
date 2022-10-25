+++
title = "Nix Flakes: first steps"
date = "2022-10-22"

[taxonomies]
tags = ["nix"]

[extra]
cover = "/images/snowflakes.jpg"
disqus = true
+++

I keep getting questions about how to start with Nix. I believe the way to go in 2022 is to start with Flakes, so in this post I'll describe just that.

If you want to learn Nix from first principles instead, I recommend [Nix Pills][pills] and [nix.dev][nixdev].

<!-- more -->

## Teaser: what's in it for me?

Imagine you wanted to try out a program someone recommended to you, but you didn't want to install it before getting an impression.
Or maybe you want to ensure your team's project is always built with the same version of your build tools, regardless of what versions your team members might have installed on their machines.
Maybe you already _have_ a version of Node that's too new for a project, and you'd like to downgrade in the scope of that project (while keeping the latest version installed).

Nix's shells allow you to do all of these. A shell creates a temporary environment in which the selected programs are available.

For example, without writing any Nix files I can open a shell with the `scala-cli` package:

```bash
$ nix shell nixpkgs#scala-cli

$ scala-cli version
Scala CLI version: 0.1.16
Scala version (default): 3.2.0
```

Now get this: that command didn't actually _install_ anything. When I leave the shell (with `exit` or `ctrl+d`), `scala-cli` is no longer usable, and it doesn't pollute my user environment.

To avoid repetition, share our shells with the team, and make them reproducible, we can define them in files. In that case, we would call `nix develop` inside the project's directory to open the shell it provides:

```bash
$ ls # making sure we're in a directory containing a flake
flake.lock      flake.nix

$ nix develop # loads the environment

$ node --version
v16.17.1

$ exit # restores the parent process's environment

$ node --version # doesn't work anymore
zsh: command not found: node
```

Shells are just one usecase of Nix, but I find that they're the one that brings the most value with minimal learning effort.
Read on, and you will learn:

- how to make isolated, reproducible and shareable shells with Nix Flakes
- where to find packages for those shells
- some bits of Nix syntax and semantics

and more. Let's get to it!

## What is Nix?

To get started with Flakes, it'd be nice if we knew what Nix was in the first place.

[Nix][nix] is a purely functional package manager.
It has a unique combination of features that make it an interesting tool that can be used to solve a variety of problems - one of which is packaging a website (which is exactly how the page you're reading was generated and packaged).

## What are flakes?

Flakes are a feature of Nix meant to enable distribution of Nix packages in a decentralized and reproducible manner.
They provide a standardized and consistent approach to dependency management, caching and the general user experience.

The **main purpose** of a Flake is to provide _outputs_: things like package definitions and shells.

Flakes can also depend on each other to produce these outputs. Flake dependencies are generally called _inputs_.

If you want to get a more in-depth understanding of Flakes, there's [documentation for the flake CLI][nix-docs], as well as [a wiki entry][wiki-flakes] and [other][xe-flakes] blog [posts][ghedam-flakes] trying to [introduce][serokell-flakes] you to flakes.

For now, let's try to use the feature, and hopefully, we'll get a better understanding of it along the way.

<!-- todo: what's a shell? add a "why" and a demo -->

## Enabling flakes

> **Note:**
>
> Flakes are a (currently) experimental feature of Nix, and they've been present in the default distribution of Nix since release 2.4.
> The "experimental" part sounds scary, but I've had a good and consistent experience for a year now, and it's probably a matter of (less rather than more) time until they are considered stable.

First of all, you need Nix installed. For that, follow [the official installation guide][download-nix] for your system.

[The wiki][wiki-flakes] lists several ways to enable flakes. I prefer this one:

Create the file `~/.config/nix/nix.conf` (if it doesn't exist) and add this line to it:

```conf
experimental-features = nix-command flakes
```

## Using flakes

The beauty of flakes is that you can build an arbitrary flake's output without dealing with the Nix language.

Now that you have enabled Flakes, you can run this:

```bash
$ nix shell nixpkgs#cowsay

$ cowsay boo
 _____
< boo >
 -----
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

If that works, you've enabled flakes correctly. It's time to make our own flake.

## Your first flake

The simplest flake possible is one that produces no outputs:

```nix
{
  outputs = _ : {};
}
```

We'll talk about the syntax later.

Save this as `flake.nix` in a new directory and you'll be able to run:

```bash
$ nix flake check
```

The command should succeed with no output. Now let's make our flake a little more complicated...

![Draw the rest of the owl](/images/rest-of-owl.jpg)

```nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs = { nixpkgs, ... }:
    let
      system = builtins.currentSystem;
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.cowsay ];
      };
    };
}
```

I know, that's a lot, but I promise we'll talk about it once we get it to work.

Save the file and run `nix flake check` again. It might take a little while, but ultimately you should see the following happen:

- A `flake.lock` file is created
- The command fails spectacularly:

  ```
  error: attribute 'currentSystem' missing

        at /nix/store/ll6cvswyh6cm59rj3zzawlm8922fcfl0-source/flake.nix:6:16:

              5|     let
              6|       system = builtins.currentSystem;
              |                ^
              7|       pkgs = import nixpkgs { inherit system; };
  (use '--show-trace' to show detailed location information)
  ```

There's a reason why it failed (don't worry about it yet). You can get it to succeed if you add `--impure` to the command, but it's a workaround - as you can guess, we'll try to get rid of that soon.

```bash
$ nix flake check --impure
```

Let's talk about what we've done so far. Specifically, let's talk about syntax!

## Nix syntax 101

In the parts that the two languages share, Nix is actually quite similar to JSON (see [manual for the Nix syntax][nix-syntax-manual]).
The following JSON object:

```json
{
  "name": "Jakub",
  "power_level": 9001,
  "languages": ["Polish", "English"],
  "uses_nix": true
}
```

translates to the following Nix:

```nix
# by the way, this is a line comment.
{
  name = "Jakub";
  power_level = 9001;
  languages = ["Polish" "English"];
  uses_nix = true;
}
```

You should note the following key differences:

- entries in the object (Nix calls these _attribute sets_, or attrsets) are separated with **semicolons**
- the trailing semicolon is **required**
- keys/values are separated with the **equals sign**
- keys aren't wrapped in **quotes**
- array elements are **separated with whitespace**
- **comments** are allowed.

## Nix syntax 102: functions

In addition to features known from formats like JSON, Nix has functions.
Functions in Nix are anonymous (they're lambdas), and they always take **one** argument each (multi-parameter functions are emulated either by means of currying or passing an attrset).

This is the general syntax for a function literal:

```nix
input : body
```

Looks familiar? We saw a similar one in the first flake we've made:

```nix
_ : {}
```

Here, we're seeing a new piece of syntax: the underscore. That just means we **ignore** the input and don't give it a name.

Functions are applied to arguments when they're separated by whitespace:

```bash
# try this in `nix repl`!
nix-repl> inc = x : x + 1

nix-repl> inc 1
2
```

To sum up all of the above, here's our initial flake definition, annotated:

```nix
# This object right here defines a flake.
# You'll see an object on the top level of every Nix flake in existence.
{
  # `outputs` is a special name in Nix
  # which lets the tools know about all the possible outputs of a flake.
  # It is a function that returns the outputs,
  # and it receives the flake's inputs as the argument.
  outputs =
    # We don't produce any outputs, so we don't need any inputs.
    # Thus, we ignore the argument.
    _ :
    # Returning an empty object - no flake outputs yet.
    {};
}
```

## A flake as a function

Just to repeat and rephrase: a flake's `outputs` attribute is a function that takes the flake's inputs as an argument.

In the second flake, we saw this function literal as the definition of `outputs`:

```nix
{
  outputs = { nixpkgs, ... } : {/* more stuff below */};
}
```

What is `nixpkgs`? What are the three dots? Let's start with the dots.

### Triple-dot syntax

Whenever you see something like

```nix
{ key1, key2, ... } :
```

it means you're looking at a pattern match (or destructuring) of an attribute set, and attributes `key1` and `key2` are required in the function input. However, because of the three dots, any extra attributes will be ignored - normally, if you only list specific attributes like in

```nix
{ key1, key2 } :
```

then any extra attributes provided at the call site will cause an error.

### Nixpkgs

[Nixpkgs][nixpkgs] is the main repository containing definitions of packages for Nix. At the time of writing, it's [the largest package repository tracked by Repology][repology-graphs].

The `nixpkgs` parameter is the result of fetching the `nixpkgs` input. Remember, we defined our inputs as:

```nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  # ...
}
```

which is syntactic sugar for the following:

```nix
{
  inputs = {
    nixpkgs = {
      url = "github:nixos/nixpkgs";
    };
  };
  # ...
}
```

and it's Nix's equivalent of saying:

```bash
$ git clone https://github.com/nixos/nixpkgs
```

The `nixos/nixpkgs` GitHub repository will be tracked by Nix and within our flake aliased under the name `nixpkgs` (the name we defined for the input). By convention you'll usually see these names match the repository that the flake is coming from.

The first time an input is used in a flake command, Nix will _pin_ it.
Pinning an input means that Nix will figure out the exact revision that it fetched, and it will make sure that everybody using this flake gets the exact same one.

At the time I'm writing this, pinning `github:nixos/nixpkgs` creates the following `flake.lock` file:

```json
{
  "nodes": {
    "nixpkgs": {
      "locked": {
        "lastModified": 1666564341,
        "narHash": "sha256-WXv7Ry6F9B8OtM0K1ye1ncaPaW/4Dwn8nDxFf2UPDWY=",
        "owner": "nixos",
        "repo": "nixpkgs",
        "rev": "09217f05bf29922c7e108c3143f11e0135ae0ded",
        "type": "github"
      },
      "original": {
        "owner": "nixos",
        "repo": "nixpkgs",
        "type": "github"
      }
    },
    "root": {
      "inputs": {
        "nixpkgs": "nixpkgs"
      }
    }
  },
  "root": "root",
  "version": 7
}
```

We don't need to talk about all of it (the file's main purpose is to be machine-readable), but please notice this part:

```json
"rev": "09217f05bf29922c7e108c3143f11e0135ae0ded",
```

That's [the commit hash][nixpkgs-reference-today] of Nixpkgs's `master` branch that was found when I referenced the flake.

The lockfile makes sure that the flake's inputs are reproducible. In fact, if you copy-pasted `flake.nix` and `flake.lock` to another machine, Nix would guarantee that the same version of Nixpkgs would be used - kind of like saying "after you clone this Git repository, always check out this revision".

Until you explicitly ask Nix to update an input (with something like `nix flake update`), it will remain unchanged. When you change it, the lockfile will be updated as well.

## Flake outputs

Let's look at the output we defined for our flake earlier.

```nix
# `nixpkgs` is in scope - we're in the body of the `outputs` function.
let
  system = builtins.currentSystem;
  pkgs = import nixpkgs { inherit system; };
in
{
  devShells.${system}.default = pkgs.mkShell {
    packages = [ pkgs.cowsay ];
  };
}
```

Here, you can see _let bindings_ in play: it's another feature of the Nix language.
A let binding declares a named value that can be used in the statements that follow.
In the snippet above, we define `system` and `pkgs` in a single binding so they can refer to each other.

Let's assume we're running an ARM-based Mac machine. The `builtins.currentSystem` string would have a value of `"aarch64-darwin"`, and our flake would return a single output: `devShells.aarch64-darwin.default`.

Some other popular system values you might want to use:

- `aarch64-linux`, for ARM-based Linux
- `x86_64-linux`, for Intel-based Linux
- `x86_64-darwin`, for ARM-based macOS

We can use that output by entering the development shell it defines:

```bash
$ nix develop --impure # we still need this flag

bash-5.1$ cowsay boo
 _____
< boo >
 -----
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
bash-5.1$
```

We're relying on a couple defaults here, but the `nix develop` command opened a Bash shell with the `cowsay` package already available on our `$PATH`. How did it happen?

First, we're relying on a couple defaults: `nix develop` on its own is equivalent to `nix develop .`, meaning "the default shell for the flake in the working directory".

On top of that, `nix develop .` means Nix will try to use the first output it finds when trying the following:

- `devShells.<currentSystem>.default`, or
- `packages.<currentSystem>.default`.

For this article, we don't care about the latter.

Reading the "current system" is considered an impurity in Nix, and as such it's allowed in the command line, but not in pure evaluation mode (the default for Flakes): the expansion of the command happens in the CLI, whereas the evaluation of a flake happens in the Nix build system.

> An "impurity" here means it's not "purely functional".
> The purely functional paradigm only allows an expression to depend on the values of other expressions, and something like "the current system", "the current time" or "the current text of the file at path `/xyz`" would require reaching beyond the scope of our code and getting the value from the local system.
>
> Nix relies on purity to deliver some of its guarantees, so it encourages pure definitions for the code you write for it.
> In Flakes, `--impure` is an escape hatch that allows breaking some of these rules of purity.

## Shells and packages

Back to our output - it's defined as the following:

```nix
pkgs.mkShell {
  packages = [ pkgs.cowsay ];
}
```

`mkShell` is a [function in Nixpkgs][mkShell] that takes an attrset as an argument. One of the attributes in it is `packages`, which can be used to list... packages (who knew, right?) that will be available in the shell environment once it's loaded.

`pkgs.cowsay` is a reference to one of the packages in Nixpkgs - you can search for these packages in a variety of ways, one which is [search.nixos.org][nixos-search].

We could get more packages into our shell by listing them in the attribute:

```nix
[ pkgs.scala-cli pkgs.openjdk11 ]
```

> As a matter of fact, these two packages showcase one of Nix's greatest features - isolation.
> scala-cli has a runtime dependency on a Java runtime, and it requires it to be version 17 or above. "But we're also adding openjdk11, surely that'll conflict, right?"
> Well, no - scala-cli's dependency is isolated: no other packages will see it.

But wait! We didn't talk about `pkgs`, did we? Also, we still have this impurity of `builtins.currentSystem` that we should deal with, so that we don't need that `--impure` parameter in every call to the Nix CLI.

## systems and pkgs

`pkgs` was defined by using the `import` function (part of Nix's standard library):

```nix
let
  system = builtins.currentSystem;
  pkgs = import nixpkgs { inherit system; };
in {}
```

A couple things to explain here: `import x` means:

1. read the file at path `x`
2. parse it as a Nix expression
3. return that expression

Additionally, we have a function call just after the import: you could've written the same thing as

```nix
let pkgs = (import nixpkgs) { inherit system; };
```

Finally, `inherit system` is syntactic sugar for `system = system`. We forward the value of `system` currently in scope or, in other words, we make the attrset "inherit" the `system` value from its definition's scope.

Reminder: `nixpkgs` is the input Nix fetched for our flake based on how we defined `nixpkgs` in the `inputs` section on the top-level of the flake.

Flake inputs are fetched to paths on the file system, and the value of the input (the `nixpkgs` value we got as a parameter of `outputs`) is that path. Given what we now know, we can tell that `pkgs` will be the result of calling some function defined in the Nix expression for Nixpkgs.

Here's the thing: packages in Nix can have different needs and different ways of being built, depending on what system they're being built for.
Most packages have dependencies on other, low-level packages (like the C compiler or another build tool), which are inherently platform-specific.
This is why you need to specify the system that Nixpkgs should use as a default when giving you access to packages.

So... we need a `system`. But `builtins.currentSystem` is impure, so how do we deal with that?

Remember: Nix's CLI already does the `currentSystem` check. We only really used it in the flake for convenience.

Assuming you only need your flake to work on one platform, you might as well hardcode the system like this:

```nix
let system = "aarch64-darwin"; # or whatever system you have
```

and it would work! Also, it would have no impurities. The day is saved... but is that it?

## Supporting multiple systems

With the change from above, our flake looks like this:

```nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs = { nixpkgs, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.cowsay ];
      };
    };
}
```

We can list all of its outputs using the `nix flake show` command:

```bash
$ nix flake show

path:/Users/kubukoz/projects/flake-demos?lastModified=1666577116&narHash=sha256-uq5VoRshQbQxkE0BL5Mgmb1eNguUIdtGaus1H50Oz6Y=
└───devShells
    └───aarch64-darwin
        └───default: development environment 'nix-shell'
```

We've eliminated the impurity from our flake, but at the cost of only supporting one system.
How can we add support for others?

Let's recap a couple facts:

1. Flake outputs are system specific
2. `builtins.currentSystem` is not allowed in pure evaluation mode
3. The Nix CLI (e.g. `nix develop`) knows what system it's running on
4. we _need_ a system to make a `pkgs`

In theory, there's nothing stopping us from copy-pasting a bunch of code to support more systems:

```nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";

  outputs = { nixpkgs, ... }: {
    devShells.aarch64-darwin.default = { /* ... */ };
    devShells.x86_64-darwin.default = { /* ... */ };
    devShells.aarch64-linux.default = { /* ... */ };
    devShells.x86_64-linux.default = { /* ... */ };
  };
}
```

but in practice, it gets real tedious real quick. It's boilerplate of the kind that we wouldn't like to maintain!

Thankfully, Nix's language and standard library offer ways to generate attrsets given a list of keys.
I won't get into the gnarly details (this is the kind of thing you learn in [Nix Pills][pills]), but the solution I like most is a higher-order function that'll take the following arguments:

- a list of system names
- a closure (function) that receives a system name and produces outputs _for that system_.

The usage of that function, let's call it `eachSystem`, would look like this:

```nix
eachSystem ["aarch64-darwin" "x86_64-darwin" /* etc. */] (system :
  let pkgs = import nixpkgs { inherit system; };
  in
  {
    devShells.default = pkgs.mkShell { packages = [ pkgs.cowsay ]; };
  })
```

By pure accident and not a completely deliberate choice of naming/syntax, this already exists!
It's indeed named `eachSystem` and it's provided by [the `flake-utils` flake][flake-utils].

With flake-utils, our final flake could look like this:

```nix
{
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachSystem [ "aarch64-darwin" "x86_64-darwin" ] (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [ pkgs.cowsay ];
        };
      });
}
```

flake-utils provides a `lib` output that doesn't require a system - it only uses Nix's standard library to transform the list of systems and the function we pass to it.

The `eachSystem` function will take the list of systems we want to support, and make sure the `default` entry in `devShells` ends up under the key specific to each system:

```bash
$ nix flake show

path:/Users/kubukoz/projects/flake-demos?lastModified=1666579399&narHash=sha256-l3Vr9psJPPsbBzZ00XSWhlcZHGonMX3rVxO51G+G1zc=
└───devShells
    ├───aarch64-darwin
    │   └───default: development environment 'nix-shell'
    └───x86_64-darwin
        └───default: development environment 'nix-shell'
```

You might also want to try [`eachDefaultSystem`][each-default-system], which hardcodes the list of systems to the "default" platforms [listed in flake-utils][default-systems]. Also, check out [`simpleFlake`][simple-flake].

## On ease of use

Now, I know all of this is pretty complicated. There's still a high barrier to entry and a steep learning curve to getting started with Nix, even with Flakes being an attempt to simplify the ways of working with it.
There are [ongoing][nix-issue-3843] discussions around the [usability][nix-issue-3849] of Nix and of Flakes, and we're likely to see improvements to it in the future, but so far it's as simple as it gets.

While I wish it could be simplified for the beginner user, I understand that Nix deals with a lot of essential complexity (inherent to the problem it attempts to solve). It's not optimizing for the "hello world" experience - it optimizes for the build system working at scale, when the builds and shells get more convoluted.
I trust that its creators know how complex the average build can get, given they've been working with this ecosystem for almost 20 years.

There are other tools built on top of Nix that provide a more newcomer-friendly experience. One of them is [devshell][devshell] (which I think could use some simplification in the documentation). If you want to get the Nix shell powers without forcing your entire team to learn the language, that might work for you.

## Parting words

To sum up, in this article we covered:

- a brief introduction to Nix and Flakes
- defining a Nix shell in a flake
- some parts of the Nix language's syntax
- supporting multiple systems

as well as a couple other things.

I hope that it gives you a decent enough introduction to Flakes that will help you start enjoying the benefits of Nix, as well as encourage you to learn the parts we didn't cover, on your own.

If you have any questions that you feel this post should've answered but didn't, let me know in the comments below.
Thanks for reading!

[flake-docs-flake-inputs]: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html#flake-inputs
[github]: https://github.com
[nix]: https://nixos.org/
[nix-docs]: https://nixos.org/manual/nix/stable/command-ref/new-cli/nix3-flake.html
[wiki-flakes]: https://nixos.wiki/wiki/Flakes
[serokell-flakes]: https://serokell.io/blog/practical-nix-flakes
[xe-flakes]: https://xeiaso.net/blog/nix-flakes-1-2022-02-21
[ghedam-flakes]: https://ghedam.at/a-tour-of-nix-flakes
[download-nix]: https://nixos.org/download.html
[nixos-cache]: https://cache.nixos.org
[nix-syntax-manual]: https://nixos.org/manual/nix/stable/language/index.html
[nixpkgs]: https://github.com/NixOS/nixpkgs
[repology-graphs]: https://repology.org/repositories/graphs
[nixpkgs-reference-today]: https://github.com/NixOS/nixpkgs/tree/09217f05bf29922c7e108c3143f11e0135ae0ded
[mkShell]: https://nixos.org/manual/nixpkgs/stable/#sec-pkgs-mkShell
[pills]: https://nixos.org/guides/nix-pills/
[nixdev]: https://nix.dev/
[default-systems]: https://github.com/numtide/flake-utils/blob/c0e246b9b83f637f4681389ecabcb2681b4f3af0/default.nix#L3-L9
[simple-flake]: https://github.com/numtide/flake-utils/#simpleflake---attrs---attrs
[each-default-system]: https://github.com/numtide/flake-utils/#eachdefaultsystem---system---attrs
[nixos-search]: https://search.nixos.org/packages
[flake-utils]: https://github.com/numtide/flake-utils/
[nix-issue-3843]: https://github.com/NixOS/nix/issues/3843
[nix-issue-3849]: https://github.com/NixOS/nix/issues/3849
[devshell]: https://github.com/numtide/devshell
