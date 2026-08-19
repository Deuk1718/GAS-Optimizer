#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
VERSION="$(tr -d '[:space:]' < "$ROOT/VERSION")"
DIST="$ROOT/dist"
STAGE="$DIST/stage"
SKILL_ARCHIVE="gas-optimizer-v${VERSION}.zip"
MACOS_ARCHIVE="gas-optimizer-v${VERSION}-macos.tar.gz"
WINDOWS_ARCHIVE="gas-optimizer-v${VERSION}-windows.zip"
MACOS_PREFIX="gas-optimizer-v${VERSION}"
WINDOWS_PREFIX="gas-optimizer-v${VERSION}"

command -v zip >/dev/null 2>&1 || { echo "Error: zip command is required." >&2; exit 1; }
command -v tar >/dev/null 2>&1 || { echo "Error: tar command is required." >&2; exit 1; }
command -v node >/dev/null 2>&1 || { echo "Error: node is required to generate package manifests." >&2; exit 1; }

rm -rf "$DIST"
mkdir -p "$STAGE"
cp -R "$ROOT/skill/gas-optimizer" "$STAGE/gas-optimizer"
(
  cd "$STAGE"
  zip -qr "$DIST/$SKILL_ARCHIVE" gas-optimizer
)
rm -rf "$STAGE"

stage_common() {
  dest="$1"
  mkdir -p "$dest"
  cp "$ROOT/VERSION" "$ROOT/LICENSE" "$ROOT/README.md" "$dest/"
  cp -R "$ROOT/skill" "$dest/skill"
}

MACOS_STAGE="$DIST/stage-macos/$MACOS_PREFIX"
mkdir -p "$MACOS_STAGE/bin" "$MACOS_STAGE/installers"
stage_common "$MACOS_STAGE"
cp "$ROOT/bin/gas-optimizer" "$MACOS_STAGE/bin/gas-optimizer"
cp "$ROOT/install.sh" "$ROOT/uninstall.sh" "$MACOS_STAGE/"
cp "$ROOT/installers/install.sh" "$ROOT/installers/uninstall.sh" "$MACOS_STAGE/installers/"
chmod +x "$MACOS_STAGE/bin/gas-optimizer" "$MACOS_STAGE/install.sh" "$MACOS_STAGE/uninstall.sh" \
  "$MACOS_STAGE/installers/install.sh" "$MACOS_STAGE/installers/uninstall.sh"
tar -C "$DIST/stage-macos" -czf "$DIST/$MACOS_ARCHIVE" "$MACOS_PREFIX"
rm -rf "$DIST/stage-macos"

WINDOWS_STAGE="$DIST/stage-windows/$WINDOWS_PREFIX"
mkdir -p "$WINDOWS_STAGE/bin" "$WINDOWS_STAGE/installers"
stage_common "$WINDOWS_STAGE"
cp "$ROOT/bin/gas-optimizer.ps1" "$ROOT/bin/gas-optimizer.cmd" "$WINDOWS_STAGE/bin/"
cp "$ROOT/install.ps1" "$ROOT/uninstall.ps1" "$WINDOWS_STAGE/"
cp "$ROOT/installers/install.ps1" "$ROOT/installers/uninstall.ps1" "$WINDOWS_STAGE/installers/"
(
  cd "$DIST/stage-windows"
  zip -qr "$DIST/$WINDOWS_ARCHIVE" "$WINDOWS_PREFIX"
)
rm -rf "$DIST/stage-windows"

if command -v sha256sum >/dev/null 2>&1; then
  (cd "$DIST" && sha256sum "$SKILL_ARCHIVE" "$MACOS_ARCHIVE" "$WINDOWS_ARCHIVE" > SHA256SUMS.txt)
elif command -v shasum >/dev/null 2>&1; then
  (cd "$DIST" && shasum -a 256 "$SKILL_ARCHIVE" "$MACOS_ARCHIVE" "$WINDOWS_ARCHIVE" > SHA256SUMS.txt)
else
  echo "Error: sha256sum or shasum is required." >&2
  exit 1
fi

node "$ROOT/scripts/generate-package-manifests.js"

printf 'Built %s\n' "$DIST/$SKILL_ARCHIVE"
printf 'Built %s\n' "$DIST/$MACOS_ARCHIVE"
printf 'Built %s\n' "$DIST/$WINDOWS_ARCHIVE"
cat "$DIST/SHA256SUMS.txt"
