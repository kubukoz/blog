#!/usr/bin/env bash

PACKAGE_PATH="$1"

nix build "git+file://$(pwd)/.?shallow=1&submodules=1#${PACKAGE_PATH:-default}" --print-build-logs
