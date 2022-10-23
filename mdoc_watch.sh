#!/usr/bin/env bash


CMD='mdoc --in mdoc --out content --classpath "$CLASSPATH" --watch'
nix develop .#mdoc_outputs --command bash -c "$CMD"
