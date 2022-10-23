#!/usr/bin/env bash

nix flake check '.?submodules=1' --print-build-logs
