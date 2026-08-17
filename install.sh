#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="gas-optimizer"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/skill/$SKILL_NAME"
ACCOUNT_ROOT="${ASIDE_ACCOUNT_ROOT:-}"

usage() {
  cat <<'EOF'
Usage: ./install.sh [--account-root PATH]

Installs GAS-Optimizer into an Aside account's skills/user directory.
The default account root is ~/.aside/u/0. Set ASIDE_ACCOUNT_ROOT or use
--account-root when Aside uses another account directory.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --account-root)
      [ "$#" -ge 2 ] || { echo "Error: --account-root requires a path." >&2; exit 2; }
      ACCOUNT_ROOT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
done

if [ -z "$ACCOUNT_ROOT" ]; then
  ACCOUNT_ROOT="$HOME/.aside/u/0"
fi

if [ ! -f "$SOURCE_DIR/SKILL.md" ]; then
  echo "Error: packaged skill not found at $SOURCE_DIR" >&2
  exit 1
fi

if [ ! -d "$ACCOUNT_ROOT" ]; then
  echo "Error: Aside account root not found: $ACCOUNT_ROOT" >&2
  echo "Start Aside once, or pass --account-root with the correct path." >&2
  exit 1
fi

SKILLS_ROOT="$ACCOUNT_ROOT/skills/user"
TARGET_DIR="$SKILLS_ROOT/$SKILL_NAME"
BACKUP_ROOT="$ACCOUNT_ROOT/backups/skills"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
TEMP_DIR="$SKILLS_ROOT/.${SKILL_NAME}.install.$$"

if [ -L "$TARGET_DIR" ]; then
  echo "Error: refusing to replace symbolic link: $TARGET_DIR" >&2
  exit 1
fi

mkdir -p "$SKILLS_ROOT"
rm -rf "$TEMP_DIR"
cp -R "$SOURCE_DIR" "$TEMP_DIR"

if ! grep -q '^name: "gas-optimizer"$' "$TEMP_DIR/SKILL.md"; then
  rm -rf "$TEMP_DIR"
  echo "Error: packaged SKILL.md failed the name check." >&2
  exit 1
fi

if [ -e "$TARGET_DIR" ]; then
  mkdir -p "$BACKUP_ROOT"
  BACKUP_DIR="$BACKUP_ROOT/${SKILL_NAME}-${TIMESTAMP}"
  cp -R "$TARGET_DIR" "$BACKUP_DIR"
  echo "Existing installation backed up to: $BACKUP_DIR"
  rm -rf "$TARGET_DIR"
fi

mv "$TEMP_DIR" "$TARGET_DIR"

for required in SKILL.md references/quality-rubric.md assets/analysis-plan-template.html; do
  if [ ! -f "$TARGET_DIR/$required" ]; then
    echo "Error: installation is incomplete; missing $required" >&2
    exit 1
  fi
done

VERSION="$(tr -d '[:space:]' < "$SCRIPT_DIR/VERSION")"
echo "GAS-Optimizer $VERSION installed successfully."
echo "Location: $TARGET_DIR"
echo "Restart Aside or start a new session to refresh skill discovery."
