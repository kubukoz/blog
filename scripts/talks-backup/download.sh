#!/usr/bin/env bash
# Download every YouTube recording linked from talks-page.sc, at best quality.
#
# Video and audio are fetched as separate streams and merged into MKV without
# re-encoding, so these are bit-exact copies of YouTube's best available formats.
# MKV is used because it accepts any codec pair; convert.sh turns these into
# widely-playable files afterwards.
#
# Usage: download.sh <dest-dir>
set -uo pipefail

DEST="${1:?usage: download.sh <dest-dir>}"
REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
mkdir -p "$DEST"

ids=$(grep -ohE 'https?://[^"'"'"' )]*(youtube\.com|youtu\.be)[^"'"'"' )]*' \
        "$REPO_ROOT/talks-page.sc" \
      | sed -E 's#.*(v=|youtu\.be/)([A-Za-z0-9_-]{11}).*#\2#' \
      | sort -u)

echo "$ids" | yt-dlp \
  --no-update \
  -a - \
  -f 'bv*+ba/b' \
  --merge-output-format mkv \
  --embed-metadata --embed-thumbnail \
  --embed-subs --sub-langs all \
  --write-info-json \
  -o "$DEST/%(id)s - %(title).120B.%(ext)s" \
  --no-overwrites \
  --ignore-errors \
  --retries 10
