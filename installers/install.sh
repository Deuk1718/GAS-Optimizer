#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="gas-optimizer"
SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
SOURCE_DIR="$REPO_ROOT/skill/$SKILL_NAME"
TARGET=""
SCOPE=""
PROJECT_ROOT=""
ASIDE_ROOT="${ASIDE_ACCOUNT_ROOT:-}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"

usage() {
  cat <<'EOF'
Usage: ./install.sh --target TARGET --scope SCOPE [options]

Targets:
  aside    Aside account skill
  claude   Claude Code skill
  agents   Shared Agent Skills location for Codex, Cursor, and GitHub Copilot
  all      All supported targets for the selected scope

Scopes:
  user     Personal skill installation
  project  Project-local installation; not available for Aside

Options:
  --project-root PATH         Required for project scope; defaults to an interactive prompt
  --aside-account-root PATH   Aside account root, default ~/.aside/u/0
  -h, --help                  Show this help

If target or scope is omitted in an interactive terminal, the installer asks.
Automation must pass both values explicitly.
EOF
}

lower() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]'; }

while [ "$#" -gt 0 ]; do
  case "$1" in
    --target) [ "$#" -ge 2 ] || { echo "Error: --target requires a value." >&2; exit 2; }; TARGET="$(lower "$2")"; shift 2 ;;
    --scope) [ "$#" -ge 2 ] || { echo "Error: --scope requires a value." >&2; exit 2; }; SCOPE="$(lower "$2")"; shift 2 ;;
    --project-root) [ "$#" -ge 2 ] || { echo "Error: --project-root requires a path." >&2; exit 2; }; PROJECT_ROOT="$2"; shift 2 ;;
    --aside-account-root|--account-root) [ "$#" -ge 2 ] || { echo "Error: $1 requires a path." >&2; exit 2; }; ASIDE_ROOT="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Error: unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if [ ! -f "$SOURCE_DIR/SKILL.md" ]; then
  echo "Error: packaged skill not found at $SOURCE_DIR" >&2
  exit 1
fi
if ! grep -q '^name: "gas-optimizer"$' "$SOURCE_DIR/SKILL.md"; then
  echo "Error: packaged SKILL.md failed the name check." >&2
  exit 1
fi

if [ -z "$TARGET" ]; then
  if [ -t 0 ]; then
    printf 'Install target [aside/claude/agents/all]: '
    read -r TARGET
    TARGET="$(lower "$TARGET")"
  else
    echo "Error: --target is required in non-interactive mode." >&2
    exit 2
  fi
fi
if [ -z "$SCOPE" ]; then
  if [ -t 0 ]; then
    printf 'Install scope [user/project]: '
    read -r SCOPE
    SCOPE="$(lower "$SCOPE")"
  else
    echo "Error: --scope is required in non-interactive mode." >&2
    exit 2
  fi
fi

case "$TARGET" in aside|claude|agents|all) ;; *) echo "Error: invalid target: $TARGET" >&2; exit 2 ;; esac
case "$SCOPE" in user|project) ;; *) echo "Error: invalid scope: $SCOPE" >&2; exit 2 ;; esac

if [ "$SCOPE" = project ]; then
  if [ "$TARGET" = aside ]; then
    echo "Error: Aside installation is account-scoped; use --scope user." >&2
    exit 2
  fi
  if [ -z "$PROJECT_ROOT" ]; then
    if [ -t 0 ]; then
      printf 'Project root: '
      read -r PROJECT_ROOT
    else
      echo "Error: --project-root is required for project scope." >&2
      exit 2
    fi
  fi
  [ -d "$PROJECT_ROOT" ] || { echo "Error: project root not found: $PROJECT_ROOT" >&2; exit 1; }
  PROJECT_ROOT="$(CDPATH= cd -- "$PROJECT_ROOT" && pwd)"
fi

install_one() {
  label="$1"
  skills_root="$2"
  backup_root="$3"
  target_dir="$skills_root/$SKILL_NAME"
  temp_dir="$skills_root/.${SKILL_NAME}.install.$$.$label"

  if [ -L "$target_dir" ]; then
    echo "Error: refusing to replace symbolic link: $target_dir" >&2
    exit 1
  fi

  mkdir -p "$skills_root"
  rm -rf "$temp_dir"
  cp -R "$SOURCE_DIR" "$temp_dir"

  for required in SKILL.md references/quality-rubric.md references/capability-matrix.md assets/analysis-plan-template.html; do
    if [ ! -f "$temp_dir/$required" ]; then
      rm -rf "$temp_dir"
      echo "Error: packaged installation is missing $required" >&2
      exit 1
    fi
  done

  if [ -e "$target_dir" ]; then
    mkdir -p "$backup_root"
    backup_dir="$backup_root/${label}-${SKILL_NAME}-${TIMESTAMP}"
    cp -R "$target_dir" "$backup_dir"
    echo "Existing $label installation backed up to: $backup_dir"
    rm -rf "$target_dir"
  fi

  mv "$temp_dir" "$target_dir"
  echo "Installed for $label: $target_dir"
}

install_aside() {
  if [ -z "$ASIDE_ROOT" ]; then ASIDE_ROOT="$HOME/.aside/u/0"; fi
  [ -d "$ASIDE_ROOT" ] || { echo "Error: Aside account root not found: $ASIDE_ROOT" >&2; exit 1; }
  install_one aside "$ASIDE_ROOT/skills/user" "$ASIDE_ROOT/backups/skills"
}

install_claude_user() { install_one claude "${CLAUDE_SKILLS_ROOT:-$HOME/.claude/skills}" "$HOME/.gas-optimizer/backups"; }
install_agents_user() { install_one agents "${AGENT_SKILLS_ROOT:-$HOME/.agents/skills}" "$HOME/.gas-optimizer/backups"; }
install_claude_project() { install_one claude-project "$PROJECT_ROOT/.claude/skills" "$PROJECT_ROOT/.gas-optimizer-backups"; }
install_agents_project() { install_one agents-project "$PROJECT_ROOT/.agents/skills" "$PROJECT_ROOT/.gas-optimizer-backups"; }

if [ "$SCOPE" = user ]; then
  case "$TARGET" in
    aside) install_aside ;;
    claude) install_claude_user ;;
    agents) install_agents_user ;;
    all) install_aside; install_claude_user; install_agents_user ;;
  esac
else
  case "$TARGET" in
    claude) install_claude_project ;;
    agents) install_agents_project ;;
    all) echo "Project scope installs Claude and shared Agent Skills targets; Aside remains account-scoped."; install_claude_project; install_agents_project ;;
  esac
fi

VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
echo "GAS-Optimizer $VERSION installation completed."
echo "Restart or reload the selected agent host if the skill is not discovered immediately."
