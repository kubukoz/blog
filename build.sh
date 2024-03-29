#!/usr/bin/env bash

PACKAGE_PATH="$1"

# shallow + there must be a hash: workaround for https://github.com/NixOS/nix/pull/10125
nix build "git+file://$(pwd)/.?shallow=1&submodules=1#${PACKAGE_PATH:-default}" --print-build-logs
