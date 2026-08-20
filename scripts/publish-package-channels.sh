#!/usr/bin/env bash
set -euo pipefail

# Copy the published Homebrew Formula and Scoop manifest from a GAS-Optimizer
# GitHub Release into the tap and bucket repositories.
#
# Usage:
#   ./scripts/publish-package-channels.sh [tag]
#
# Defaults to the latest release. Requires `gh` authenticated with write access
# to Deuk1718/homebrew-tap and Deuk1718/scoop-gas-optimizer.

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)"
SOURCE_REPO="Deuk1718/GAS-Optimizer"
TAP_REPO="Deuk1718/homebrew-tap"
BUCKET_REPO="Deuk1718/scoop-gas-optimizer"
TAG="${1:-}"

command -v gh >/dev/null 2>&1 || { echo "Error: gh is required." >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "Error: python3 is required." >&2; exit 1; }

if [ -z "$TAG" ]; then
  TAG="$(gh release view -R "$SOURCE_REPO" --json tagName --jq .tagName)"
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

gh release download "$TAG" -R "$SOURCE_REPO" \
  --pattern 'gas-optimizer.rb' \
  --pattern 'gas-optimizer.json' \
  --dir "$TMP"

test -s "$TMP/gas-optimizer.rb"
test -s "$TMP/gas-optimizer.json"
grep -q 'bin.write_exec_script' "$TMP/gas-optimizer.rb"

python3 - "$TAG" "$TAP_REPO" "$BUCKET_REPO" "$TMP/gas-optimizer.rb" "$TMP/gas-optimizer.json" <<'PY'
import base64
import json
import pathlib
import subprocess
import sys

tag, tap_repo, bucket_repo, formula_path, manifest_path = sys.argv[1:6]


def update_file(owner_repo, repo_path, local_file, message):
    local = pathlib.Path(local_file).read_bytes()
    meta = json.loads(
        subprocess.check_output(
            ["gh", "api", f"repos/{owner_repo}/contents/{repo_path}"],
            text=True,
        )
    )
    remote = base64.b64decode(meta["content"])
    if remote == local:
        print(f"{owner_repo}/{repo_path} already matches {pathlib.Path(local_file).name}")
        return
    payload = {
        "message": message,
        "content": base64.b64encode(local).decode("ascii"),
        "sha": meta["sha"],
        "branch": "main",
    }
    subprocess.run(
        ["gh", "api", "--method", "PUT", f"repos/{owner_repo}/contents/{repo_path}", "--input", "-"],
        input=json.dumps(payload),
        text=True,
        check=True,
        stdout=subprocess.DEVNULL,
    )
    print(f"Updated {owner_repo}/{repo_path}")


json.loads(pathlib.Path(manifest_path).read_text(encoding="utf-8"))
update_file(tap_repo, "Formula/gas-optimizer.rb", formula_path, f"Update gas-optimizer Formula to {tag}")
update_file(bucket_repo, "gas-optimizer.json", manifest_path, f"Update gas-optimizer manifest to {tag}")
PY
