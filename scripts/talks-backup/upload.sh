#!/usr/bin/env bash
# Upload converted talk recordings to S3 Glacier Instant Retrieval.
#
# Idempotent: an object already present with a matching size is skipped, so this
# can be re-run safely to pick up newly converted files.
#
# Videos go to GLACIER_IR (cheap, but still readable with a plain GET -- no
# restore step). The small .info.json sidecars stay in STANDARD so the archive
# stays browsable without touching the video objects.
#
# Usage: upload.sh <src-dir> [bucket]
set -uo pipefail

SRC="${1:?usage: upload.sh <src-dir> [bucket]}"
BUCKET="${2:-talks-backup-855041393262}"
export AWS_PROFILE="${AWS_PROFILE:-default}"
export AWS_REGION="${AWS_REGION:-eu-central-1}"

shopt -s nullglob
fail=0

upload() { # <file> <key> <storage-class>
  local f=$1 key=$2 sc=$3
  local local_size remote_size
  local_size=$(stat -f%z "$f")
  remote_size=$(aws s3api head-object --bucket "$BUCKET" --key "$key" \
                  --query ContentLength --output text 2>/dev/null)

  if [ "$remote_size" = "$local_size" ]; then
    echo "SKIP   $(basename "$key")"
    return 0
  fi

  echo "UPLOAD $(basename "$key") ($local_size bytes, $sc)"
  if aws s3 cp "$f" "s3://$BUCKET/$key" --storage-class "$sc" --only-show-errors; then
    echo "  OK   $(basename "$key")"
  else
    echo "  FAIL $(basename "$key")"
    fail=$((fail+1))
  fi
}

for f in "$SRC"/*.mp4 "$SRC"/*.webm; do
  upload "$f" "talks/$(basename "$f")" GLACIER_IR
done

for f in "$SRC"/*.info.json; do
  upload "$f" "metadata/$(basename "$f")" STANDARD
done

echo "FAILURES=$fail"
exit $fail
