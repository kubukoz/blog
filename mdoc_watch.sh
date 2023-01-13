#!/usr/bin/env bash

set -e

ARTICLE_PATH="$1"
# if article name is not provided, fail.
if [ -z "$ARTICLE_PATH" ]; then
  echo "Please provide article path as an argument."
  exit 1
fi

# Build all mdoc files, just to populate the target directory
nix build .#mdoc_outputs
cp -rL --no-preserve=mode,ownership ./result/* ./content/


ARTICLE_NAME=$(basename "$ARTICLE_PATH")

CMD='mdoc --in mdoc/'$ARTICLE_NAME' --out content/'$ARTICLE_NAME' --classpath "$CLASSPATH" --watch'
nix develop .#mdoc_outputs."\"$ARTICLE_NAME\"" --command bash -c "$CMD"
