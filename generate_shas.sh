#!/bin/bash

# who needs to pin dependencies anyway?
nix shell nixpkgs#nodejs nixpkgs#coursier nixpkgs#nix --command \
  node ./sha256.js ./mdoc-lib-index.json
