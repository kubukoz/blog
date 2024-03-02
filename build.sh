#!/usr/bin/env bash

PACKAGE_PATH="$1"

nix build "git+file://$(pwd)/${PACKAGE_PATH:-.?submodules=1}" --print-build-logs
