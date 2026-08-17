#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
DIST="$ROOT/dist"
STAGE="$DIST/stage"
ARCHIVE="gas-optimizer-v${VERSION}.zip"

command -v zip >/dev/null 2>&1 || { echo "Error: zip command is required." >&2; exit 1; }
rm -rf "$DIST"
mkdir -p "$STAGE"
cp -R "$ROOT/skill/gas-optimizer" "$STAGE/gas-optimizer"
(
  cd "$STAGE"
  zip -qr "$DIST/$ARCHIVE" gas-optimizer
)
rm -rf "$STAGE"

if command -v sha256sum >/dev/null 2>&1; then
  (cd "$DIST" && sha256sum "$ARCHIVE" > SHA256SUMS.txt)
elif command -v shasum >/dev/null 2>&1; then
  (cd "$DIST" && shasum -a 256 "$ARCHIVE" > SHA256SUMS.txt)
else
  echo "Error: sha256sum or shasum is required." >&2
  exit 1
fi

printf 'Built %s\n' "$DIST/$ARCHIVE"
cat "$DIST/SHA256SUMS.txt"
