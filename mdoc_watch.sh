#!/bin/bash

nix develop --command mdoc --in mdoc --out content --classpath "$CLASSPATH" --watch
