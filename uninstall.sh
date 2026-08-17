#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="gas-optimizer"
ACCOUNT_ROOT="${ASIDE_ACCOUNT_ROOT:-}"
ASSUME_YES=0

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh [--account-root PATH] [--yes]

Backs up and removes GAS-Optimizer from an Aside account.
EOF
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --account-root)
      [ "$#" -ge 2 ] || { echo "Error: --account-root requires a path." >&2; exit 2; }
      ACCOUNT_ROOT="$2"
      shift 2
      ;;
    --yes)
      ASSUME_YES=1
      shift
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

TARGET_DIR="$ACCOUNT_ROOT/skills/user/$SKILL_NAME"
if [ -L "$TARGET_DIR" ]; then
  echo "Error: refusing to remove symbolic link: $TARGET_DIR" >&2
  exit 1
fi
if [ ! -f "$TARGET_DIR/SKILL.md" ]; then
  echo "GAS-Optimizer is not installed at: $TARGET_DIR"
  exit 0
fi
if ! grep -q '^name: "gas-optimizer"$' "$TARGET_DIR/SKILL.md"; then
  echo "Error: target does not contain the expected GAS-Optimizer skill." >&2
  exit 1
fi

if [ "$ASSUME_YES" -ne 1 ]; then
  printf 'Back up and remove %s? [y/N] ' "$TARGET_DIR"
  read -r answer
  case "$answer" in y|Y|yes|YES) ;; *) echo "Cancelled."; exit 0 ;; esac
fi

TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"
BACKUP_ROOT="$ACCOUNT_ROOT/backups/skills"
BACKUP_DIR="$BACKUP_ROOT/${SKILL_NAME}-uninstall-${TIMESTAMP}"
mkdir -p "$BACKUP_ROOT"
cp -R "$TARGET_DIR" "$BACKUP_DIR"
rm -rf "$TARGET_DIR"

echo "GAS-Optimizer removed."
echo "Backup: $BACKUP_DIR"
