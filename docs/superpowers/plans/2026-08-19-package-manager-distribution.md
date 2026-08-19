# Package Manager Distribution Implementation Plan

**Goal:** Provide a consistent `gas-optimizer` CLI distributed through a Homebrew tap on macOS and a Scoop bucket on Windows while preserving the existing installers as fallbacks.

**Architecture:** Package managers install only a versioned skill bundle and launcher. The launcher delegates copy/backup behavior to the existing platform installer, records concrete installations in `~/.gas-optimizer/installations.json`, and requires explicit `install`, `sync`, or `uninstall` commands before changing user or project skill directories. Homebrew and Scoop manifests are generated from release templates after archive checksums are known.

**Global constraints:**
- Package installation and package removal must not directly add or delete host skill copies.
- `gas-optimizer install` must collect target and scope before invoking existing installers.
- `gas-optimizer sync` must update only recorded installations and retain existing backup behavior.
- `gas-optimizer uninstall` must require an explicit target/record selection and confirmation.
- Registry writes must be atomic and contain no credentials.
- POSIX state handling uses `jq`; the Homebrew Formula declares it as a dependency.
- Windows state handling uses PowerShell JSON support and a CMD shim.
- Existing `install.sh`, `install.ps1`, uninstallers, source ZIP, and upload-ready skill ZIP remain supported.
- Do not create git commits unless explicitly requested.

## Task 1: CLI contract tests
- Extend package validation to require launchers, state schema markers, archive templates, and package-manager templates.
- Add POSIX smoke tests covering `version`, install, status, sync, backup, and uninstall in an isolated HOME/project.
- Add Windows smoke tests with the equivalent lifecycle in an isolated user profile.
- Run validation first and confirm the new contract fails because the launchers are absent.

## Task 2: POSIX CLI
- Add `bin/gas-optimizer` with `install`, `status`, `sync`, `uninstall`, and `version`.
- Resolve the package root from the launcher, prompt only when flags are omitted, and pass explicit flags to existing installers.
- Maintain an atomic JSON registry at `${GAS_OPTIMIZER_HOME:-$HOME/.gas-optimizer}/installations.json`.
- Record one entry per concrete destination, including target, scope, destination, project/account root, installed version, and timestamp.
- Require `jq` with an actionable error; never download dependencies at runtime.

## Task 3: Windows CLI
- Add `bin/gas-optimizer.ps1` and `bin/gas-optimizer.cmd`.
- Match POSIX commands, flags, state schema, target decomposition, backup behavior, and explicit confirmation.
- Use PowerShell JSON APIs and atomic replacement for the registry.

## Task 4: Release packaging
- Extend `scripts/build-release.sh` to produce the existing skill ZIP plus macOS tarball and Windows ZIP.
- Add release templates for a Homebrew Formula and Scoop manifest with version, URL, and SHA-256 placeholders.
- Add a dependency-free Node generator that fills templates into `dist/packaging/` after archive checksums are known.
- Publish all archives, checksums, and generated package manifests from the existing tag workflow.

## Task 5: Documentation and CI
- Document Homebrew and Scoop two-step installation, explicit sync, status, uninstall semantics, fallback scripts, and the later WinGet channel.
- Add macOS/Ubuntu POSIX lifecycle smoke tests and a Windows PowerShell lifecycle smoke test to validation CI.
- Make clear that publishing generated manifests to the external tap/bucket repositories is a release-channel operation, not a user-home mutation.

## Task 6: Verification
- Run package validation, POSIX smoke tests, available local PowerShell tests, release build, shell syntax checks, and `git diff --check`.
- Inspect generated archives and manifests without publishing them.
- Run final plan-alignment and code-quality review.
