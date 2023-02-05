#!/bin/bash

nix develop .#generate_shas --command \
  scala-cli --server=false ./sha256.sc -- ./mdoc-lib-index.json
