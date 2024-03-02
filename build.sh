#!/usr/bin/env bash

PACKAGE_PATH="$1"

nix build "git+file://$(pwd)?shallow=1&submodules${PACKAGE_PATH:-}" --print-build-logs
