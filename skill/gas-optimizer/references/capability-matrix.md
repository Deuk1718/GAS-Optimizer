# Host Capability and Invocation Matrix

GAS-Optimizer follows the Agent Skills open standard. The workflow is portable, but discovery, invocation syntax, and available tools differ by host. Never claim that an untested host supports a command merely because another host does.

## Invocation matrix

| Host | Automatic invocation | Explicit invocation | Slash invocation | Recommended personal location |
|---|---|---|---|---|
| Aside | Yes, when the description matches | Ask to use the `gas-optimizer` skill by name | Not guaranteed | `<Aside account root>/skills/user/gas-optimizer` |
| Claude Code | Yes | Name the skill or invoke it directly | `/gas-optimizer` | `~/.claude/skills/gas-optimizer` |
| Codex CLI or IDE | Yes | `$gas-optimizer`; use `/skills` to browse | Use `/skills`, not an assumed `/gas-optimizer` command | `~/.agents/skills/gas-optimizer` |
| ChatGPT with Skills | Yes when attached or installed | Select with `@gas-optimizer` | Not the documented primary syntax | Install through the Skills or plugin UI |
| Cursor | Yes | Name the skill directly | `/gas-optimizer` | `~/.agents/skills/gas-optimizer` or `~/.cursor/skills/gas-optimizer` |
| GitHub Copilot in VS Code or CLI | Yes | Name the skill directly | `/gas-optimizer` | `~/.agents/skills/gas-optimizer` or `~/.copilot/skills/gas-optimizer` |
| Claude.ai custom Skills | Host decides when relevant | Select or mention the uploaded skill in the UI | Not guaranteed | Upload the skill ZIP in the supported settings UI |
| Claude or OpenAI API | Only when the application attaches the skill | Attach the skill ID or bundle programmatically | Not applicable | Upload or mount the skill bundle through the API |

When documenting invocation, distinguish these two concepts:

1. **Implicit invocation**: the host matches the user's request to the skill description.
2. **Explicit invocation**: the user selects or names the skill. Slash, dollar, and at-sign syntax are host-specific variants of explicit invocation.

## Required capabilities

A host needs the following capabilities for the full core workflow:

- Read the target project's source and generated output.
- Write the dynamic analysis report, backup, approved source changes, and audit script.
- Run project build, validation, test, and audit commands.
- Preserve user approval boundaries across the two approval stages.

If any required capability is unavailable, record the affected checks as `[blocked]` or require a documented manual step. Do not lower the scoring gate.

## Optional capabilities

These improve evidence or enable opt-in extensions but are not universally available:

- Browser automation and rendered-page inspection.
- Network access for current official guidance and external-link checks.
- Screenshot or visual-regression capture.
- Git and GitHub access.
- Vercel access.
- Google Search Console or Bing Webmaster Tools access.
- Field performance data or a compatible lab measurement tool.

Before using an optional capability that changes external state, explain the action and obtain the required separate approval.

## External search operation levels

Optional Google, Bing, Naver, and future search-provider operations use the common contract in `external-search-operations.md`. Host support is not universal: a host may support source edits and build commands while lacking official provider APIs, authenticated browser assistance, safe evidence capture, or network access.

| Level | Name | Required host/provider capability | Typical status outcome |
|---|---|---|---|
| Level 1 | Official API/MCP | A documented provider API, official CLI, approved MCP tool, or equivalent first-party integration for the selected provider/action. | `completed` or `verified` when provider confirmation is available. |
| Level 2 | Authenticated-browser assistance | Browser automation or guided browser assistance after the user handles login, 2FA, CAPTCHA, consent, and account recovery. | `assisted`, `completed`, or `verified` depending on provider acceptance and evidence. |
| Level 3 | Verifiable manual handoff | The agent can provide the official destination, exact user action and value, and safe verification steps, but the user must perform the action. | `manual-required` until user evidence or provider/public confirmation is validated. |
| Level 4 | Blocked | No safe, authorized, or verifiable execution path is available. | `blocked` with a concrete blocker and retry condition. |

Determine execution level with deterministic downgrade order `1 -> 2 -> 3 -> 4`. Do not claim a host can perform Level 1 or Level 2 merely because another host can. If Level 1 is unavailable, try Level 2 only when browser assistance is supported and approved; if Level 2 is unavailable or unsafe, provide a Level 3 handoff only when the result can be verified; otherwise mark Level 4 blocked.

## Portability rules

- Keep the canonical `SKILL.md` on the common Agent Skills frontmatter subset: `name` and `description`.
- Do not add host-specific frontmatter to the canonical file.
- Put host-specific UI metadata in an adapter or distribution manifest, not in the common skill.
- Prefer relative references within the skill folder.
- Keep scripts dependency-light and declare unavoidable requirements.
- Treat the common skill as the source of truth; installers copy it unchanged to each host location.
