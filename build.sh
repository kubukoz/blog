#!/usr/bin/env bash

PACKAGE_PATH="$1"

nix build "git+file://$(pwd)?submodules=1&shallow=1${PACKAGE_PATH:-}" --print-build-logs
