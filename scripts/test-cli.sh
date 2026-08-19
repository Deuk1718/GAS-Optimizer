#!/usr/bin/env bash
set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  echo "SKIP: scripts/test-cli.sh requires jq to validate the CLI registry JSON." >&2
  exit 77
fi

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
CLI="$REPO_ROOT/bin/gas-optimizer"
VERSION="$(tr -d '[:space:]' < "$REPO_ROOT/VERSION")"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/gas-optimizer-cli.XXXXXX")"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

export HOME="$TMP_ROOT/home"
export GAS_OPTIMIZER_HOME="$TMP_ROOT/state"
export CLAUDE_SKILLS_ROOT="$TMP_ROOT/user-claude/skills"
export AGENT_SKILLS_ROOT="$TMP_ROOT/user-agents/skills"
export ASIDE_ACCOUNT_ROOT="$TMP_ROOT/aside-account"
mkdir -p "$HOME" "$GAS_OPTIMIZER_HOME" "$CLAUDE_SKILLS_ROOT" "$AGENT_SKILLS_ROOT" "$ASIDE_ACCOUNT_ROOT"

REGISTRY="$GAS_OPTIMIZER_HOME/installations.json"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_under_tmp() {
  case "$1" in
    "$TMP_ROOT"/*) ;;
    *) fail "path escaped isolated temp root: $1" ;;
  esac
}

assert_no_real_user_paths() {
  assert_under_tmp "$HOME"
  assert_under_tmp "$GAS_OPTIMIZER_HOME"
  assert_under_tmp "$CLAUDE_SKILLS_ROOT"
  assert_under_tmp "$AGENT_SKILLS_ROOT"
  assert_under_tmp "$ASIDE_ACCOUNT_ROOT"
  if [ -f "$REGISTRY" ]; then
    jq -e --arg tmp "$TMP_ROOT/" '
      (.installations // [])
      | all((.path // "") | startswith($tmp))
    ' "$REGISTRY" >/dev/null || fail "registry contains a path outside the isolated temp root"
  fi
}

assert_registry_count() {
  expected="$1"
  [ -f "$REGISTRY" ] || fail "registry missing: $REGISTRY"
  jq -e --argjson expected "$expected" '
    .schemaVersion == 1
    and (.installations | type == "array")
    and (.installations | length == $expected)
  ' "$REGISTRY" >/dev/null || fail "registry does not have schemaVersion=1 and $expected record(s)"
  assert_no_real_user_paths
}

assert_single_record() {
  expected_target="$1"
  expected_scope="$2"
  expected_path="$3"
  assert_registry_count 1
  jq -e \
    --arg target "$expected_target" \
    --arg scope "$expected_scope" \
    --arg path "$expected_path" \
    --arg version "$VERSION" '
      .installations[0].target == $target
      and .installations[0].scope == $scope
      and .installations[0].path == $path
      and .installations[0].installedVersion == $version
    ' "$REGISTRY" >/dev/null || fail "registry record does not match the installed target"
}

expect_output_contains() {
  output="$1"
  needle="$2"
  case "$output" in
    *"$needle"*) ;;
    *) fail "expected output to contain '$needle'; got: $output" ;;
  esac
}

version_output="$("$CLI" version)"
expect_output_contains "$version_output" "$VERSION"
assert_no_real_user_paths

agents_path="$AGENT_SKILLS_ROOT/gas-optimizer"
"$CLI" install --target agents --scope user
[ -f "$agents_path/SKILL.md" ] || fail "user agents install did not create $agents_path"
assert_single_record agents user "$agents_path"

status_output="$("$CLI" status --target agents --scope user)"
expect_output_contains "$status_output" "current"
expect_output_contains "$status_output" "$agents_path"
assert_single_record agents user "$agents_path"

sentinel="$agents_path/STALE-FILE"
printf 'stale\n' > "$sentinel"
"$CLI" sync
[ -f "$agents_path/SKILL.md" ] || fail "sync did not reinstall the agents record"
[ ! -e "$sentinel" ] || fail "sync retained stale content instead of reinstalling"
backup_match=0
for candidate in "$GAS_OPTIMIZER_HOME"/backups/*/STALE-FILE "$HOME"/.gas-optimizer/backups/*/STALE-FILE; do
  if [ -f "$candidate" ]; then backup_match=1; fi
done
[ "$backup_match" -eq 1 ] || fail "sync did not back up the prior agents installation"
assert_single_record agents user "$agents_path"

"$CLI" uninstall --target agents --scope user --yes
[ ! -e "$agents_path" ] || fail "uninstall did not remove $agents_path"
uninstall_backup_match=0
for candidate in "$GAS_OPTIMIZER_HOME"/backups/*/SKILL.md "$HOME"/.gas-optimizer/backups/*/SKILL.md; do
  if [ -f "$candidate" ]; then uninstall_backup_match=1; fi
done
[ "$uninstall_backup_match" -eq 1 ] || fail "uninstall did not back up the removed agents installation"
assert_registry_count 0

project_root="$TMP_ROOT/project"
mkdir -p "$project_root"
project_agents_path="$project_root/.agents/skills/gas-optimizer"
"$CLI" install --target agents --scope project --project-root "$project_root"
[ -f "$project_agents_path/SKILL.md" ] || fail "project agents install did not create $project_agents_path"
assert_single_record agents project "$project_agents_path"

project_status="$("$CLI" status --target agents --scope project --project-root "$project_root")"
expect_output_contains "$project_status" "current"
expect_output_contains "$project_status" "$project_agents_path"

"$CLI" uninstall --target agents --scope project --project-root "$project_root" --yes
[ ! -e "$project_agents_path" ] || fail "project agents uninstall did not remove $project_agents_path"
assert_registry_count 0
assert_no_real_user_paths

echo "PASS: gas-optimizer CLI lifecycle contract"
