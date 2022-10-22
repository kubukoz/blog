#!/usr/bin/env bash

nix build '.?submodules=1' --print-build-logs
