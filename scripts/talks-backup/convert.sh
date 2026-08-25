#!/usr/bin/env bash
# Convert downloaded talk recordings to widely-playable MP4.
#
# Everything here is lossless for video; no video stream is ever re-encoded.
#
#   H.264 sources -> .mp4, video copied, audio re-encoded to AAC 192k so the
#                    result plays in Safari/QuickTime (neither supports Opus in MP4).
#   VP9/AV1 srcs  -> .webm, both streams copied verbatim. WebM is the container
#                    these codecs belong in, so no conversion is needed at all.
#
# Usage: convert.sh <src-dir> <dest-dir>
set -uo pipefail

SRC="${1:?usage: convert.sh <src-dir> <dest-dir>}"
DEST="${2:?usage: convert.sh <src-dir> <dest-dir>}"
mkdir -p "$DEST"

shopt -s nullglob
fail=0

for f in "$SRC"/*.mkv "$SRC"/*.webm; do
  base=$(basename "$f")
  vcodec=$(ffprobe -v error -select_streams v:0 \
    -show_entries stream=codec_name -of csv=p=0 -- "$f")

  # Pick the container each codec legally belongs in, so video is always copied.
  if [ "$vcodec" = "h264" ]; then
    out="$DEST/${base%.*}.mp4"
    opts=(-c:v copy -c:a aac -b:a 192k -movflags +faststart)
    label="h264 -> mp4 (video copy, audio -> aac)"
  else
    out="$DEST/${base%.*}.webm"
    opts=(-c copy)
    label="$vcodec -> webm (fully lossless)"
  fi

  if [ -s "$out" ]; then
    echo "SKIP   ${base:0:60} (already converted)"
    continue
  fi

  echo "CONVERT ${base:0:60} [$label]"
  # -map 0:v:0 -map 0:a:0 drops attachment/subtitle streams the target can't hold.
  if ffmpeg -nostdin -v error -y -i "$f" \
      -map 0:v:0 -map 0:a:0 \
      "${opts[@]}" \
      "$out"; then
    echo "  OK   ${base:0:60}"
  else
    echo "  FAIL ${base:0:60}"
    rm -f "$out"
    fail=$((fail+1))
  fi
done

echo "FAILURES=$fail"
exit $fail
