#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="gas-optimizer"
TARGET=""
SCOPE=""
PROJECT_ROOT=""
ASIDE_ROOT="${ASIDE_ACCOUNT_ROOT:-}"
ASSUME_YES=0
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"

usage() {
  cat <<'EOF'
Usage: ./uninstall.sh --target TARGET --scope SCOPE [options]

Targets: aside, claude, agents, all
Scopes: user, project
Options:
  --project-root PATH
  --aside-account-root PATH
  --yes
  -h, --help
EOF
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }
while [ "$#" -gt 0 ]; do
  case "$1" in
    --target) [ "$#" -ge 2 ] || exit 2; TARGET="$(lower "$2")"; shift 2 ;;
    --scope) [ "$#" -ge 2 ] || exit 2; SCOPE="$(lower "$2")"; shift 2 ;;
    --project-root) [ "$#" -ge 2 ] || exit 2; PROJECT_ROOT="$2"; shift 2 ;;
    --aside-account-root|--account-root) [ "$#" -ge 2 ] || exit 2; ASIDE_ROOT="$2"; shift 2 ;;
    --yes) ASSUME_YES=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Error: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ -z "$TARGET" ]; then
  if [ -t 0 ]; then printf 'Uninstall target [aside/claude/agents/all]: '; read -r TARGET; TARGET="$(lower "$TARGET")"; else echo "Error: --target is required." >&2; exit 2; fi
fi
if [ -z "$SCOPE" ]; then
  if [ -t 0 ]; then printf 'Uninstall scope [user/project]: '; read -r SCOPE; SCOPE="$(lower "$SCOPE")"; else echo "Error: --scope is required." >&2; exit 2; fi
fi
case "$TARGET" in aside|claude|agents|all) ;; *) echo "Error: invalid target: $TARGET" >&2; exit 2 ;; esac
case "$SCOPE" in user|project) ;; *) echo "Error: invalid scope: $SCOPE" >&2; exit 2 ;; esac

if [ "$SCOPE" = project ]; then
  [ "$TARGET" != aside ] || { echo "Error: Aside installation is account-scoped." >&2; exit 2; }
  if [ -z "$PROJECT_ROOT" ]; then
    if [ -t 0 ]; then printf 'Project root: '; read -r PROJECT_ROOT; else echo "Error: --project-root is required." >&2; exit 2; fi
  fi
  [ -d "$PROJECT_ROOT" ] || { echo "Error: project root not found: $PROJECT_ROOT" >&2; exit 1; }
  PROJECT_ROOT="$(CDPATH= cd -- "$PROJECT_ROOT" && pwd)"
fi

remove_one() {
  label="$1"
  target_dir="$2"
  backup_root="$3"

  if [ -L "$target_dir" ]; then
    echo "Error: refusing to remove symbolic link: $target_dir" >&2
    exit 1
  fi
  if [ ! -f "$target_dir/SKILL.md" ]; then
    echo "Not installed for $label: $target_dir"
    return
  fi
  if ! grep -q '^name: "gas-optimizer"$' "$target_dir/SKILL.md"; then
    echo "Error: target is not GAS-Optimizer: $target_dir" >&2
    exit 1
  fi
  if [ "$ASSUME_YES" -ne 1 ]; then
    printf 'Back up and remove %s? [y/N] ' "$target_dir"
    read -r answer
    case "$answer" in y|Y|yes|YES) ;; *) echo "Skipped $label."; return ;; esac
  fi

  mkdir -p "$backup_root"
  backup_dir="$backup_root/${label}-${SKILL_NAME}-uninstall-${TIMESTAMP}"
  cp -R "$target_dir" "$backup_dir"
  rm -rf "$target_dir"
  echo "Removed $label installation. Backup: $backup_dir"
}

remove_aside() {
  if [ -z "$ASIDE_ROOT" ]; then ASIDE_ROOT="$HOME/.aside/u/0"; fi
  remove_one aside "$ASIDE_ROOT/skills/user/$SKILL_NAME" "$ASIDE_ROOT/backups/skills"
}
remove_claude_user() { remove_one claude "${CLAUDE_SKILLS_ROOT:-$HOME/.claude/skills}/$SKILL_NAME" "$HOME/.gas-optimizer/backups"; }
remove_agents_user() { remove_one agents "${AGENT_SKILLS_ROOT:-$HOME/.agents/skills}/$SKILL_NAME" "$HOME/.gas-optimizer/backups"; }
remove_claude_project() { remove_one claude-project "$PROJECT_ROOT/.claude/skills/$SKILL_NAME" "$PROJECT_ROOT/.gas-optimizer-backups"; }
remove_agents_project() { remove_one agents-project "$PROJECT_ROOT/.agents/skills/$SKILL_NAME" "$PROJECT_ROOT/.gas-optimizer-backups"; }

if [ "$SCOPE" = user ]; then
  case "$TARGET" in
    aside) remove_aside ;;
    claude) remove_claude_user ;;
    agents) remove_agents_user ;;
    all) remove_aside; remove_claude_user; remove_agents_user ;;
  esac
else
  case "$TARGET" in
    claude) remove_claude_project ;;
    agents) remove_agents_project ;;
    all) remove_claude_project; remove_agents_project ;;
  esac
fi
