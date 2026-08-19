# Changelog

## 1.2.0

- Add adaptive Google, Bing, and Naver external-search operations with four execution levels and a separate external-operations gate.
- Add a `gas-optimizer` CLI for explicit `install`, `status`, `sync`, `uninstall`, and `version`.
- Distribute a launcher and versioned skill bundle through Homebrew and Scoop without mutating host skill directories during package install.
- Keep `install.sh` and `install.ps1` as fallback installers.

## 1.1.0

- Adopt the Agent Skills open standard as the public distribution model.
- Add user and project installation for Claude Code.
- Add shared `.agents/skills` installation for Codex, Cursor, and GitHub Copilot.
- Add Linux as an officially tested operating system.
- Add host capability and invocation guidance.
- Add interactive and explicit target/scope selection to macOS, Linux, and Windows installers.
- Add upload-ready skill ZIP and SHA-256 checksum release assets.
- Preserve Aside installation and automatic backup behavior.

## 1.0.0

- Initial public release for Aside on macOS and Windows.
- Add the six-domain non-compensating 95-point quality gate.
- Add two-stage approval, backup, rollback, regression, and truthfulness checks.
