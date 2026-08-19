# External Search Operations Contract

This contract governs optional external search-engine operations for Google, Bing, Naver, and any future provider-specific playbook. These operations are off by default, require explicit selection and approval, and are reported through `external-operations-gate` separately from the six-domain `quality-gate`.

External outcomes never change the fixed six-domain scores. Selected extensions also cannot be falsely marked complete: each selected provider/action must carry its own status, execution level, evidence, and blocker state until it is either verified, failed, or intentionally left blocked.

Allowed statuses: `not-selected`, `ready`, `assisted`, `manual-required`, `blocked`, `completed`, `verified`, `failed`
Allowed transitions: not-selected->ready, not-selected->blocked, ready->assisted, ready->manual-required, ready->blocked, ready->completed, ready->verified, ready->failed, assisted->manual-required, assisted->blocked, assisted->completed, assisted->verified, assisted->failed, manual-required->blocked, manual-required->completed, manual-required->verified, manual-required->failed, blocked->ready, completed->blocked, completed->verified, completed->failed, verified->blocked, verified->failed, failed->ready
Execution levels: Level-1, Level-2, Level-3, Level-4
Gate names: quality-gate, external-operations-gate
Initial selection outcomes: preflight-success=not-selected->ready; concrete-preflight-blocker-after-selection=not-selected->blocked; blocked-without-selection=forbidden
Blocked retry requirements: selected-action=required; blocker-removal=required; read-only-preflight=repeated-successfully; existing-approval=must-remain-valid; missing-approval=record-pending-and-obtain-before-mutation; prior-approval-for-preflight-blocked=not-required
Evidence gates: completed=provider-acceptance; verified=independently-validated-provider-or-public-evidence
Level 1 direct outcomes: completed=ready->completed; verified=ready->verified; assisted=forbidden
Manual handoff outcomes: default=manual-required; completed=requires-provider-acceptance; verified=requires-independent-validation

## Gates

- `quality-gate` covers only SEO, GEO, AEO, accessibility, performance, and deployment readiness scoring plus the non-compensating hard blockers in the core GAS-Optimizer workflow.
- `external-operations-gate` covers optional provider mutations such as property verification, sitemap submission, indexing requests, and webmaster-tool registration.
- Passing `quality-gate` never implies an external operation was selected, completed, or verified.
- Failing, blocked, or unselected external operations never lower the six fixed domain scores, but a selected external operation remains incomplete until its own status truthfully reflects the evidence.

## Execution Levels

- **Level 1 official API/MCP**: The agent uses a documented provider API, official CLI, approved MCP tool, or equivalent first-party integration that can perform the selected action and return provider confirmation.
- **Level 2 authenticated-browser assistance**: The user handles authentication and sensitive prompts, then the agent assists in an authenticated browser session only after approval and only within the selected provider/action.
- **Level 3 verifiable manual handoff**: The agent gives a precise handoff for the user to perform in the official provider destination and can verify the result from safe evidence or public/provider confirmation afterward.
- **Level 4 blocked**: No safe, authorized, or verifiable path is available for the selected action.

Use deterministic downgrade order `1 -> 2 -> 3 -> 4`. Do not skip to a lower level until the higher level is unavailable, unauthorized, or unsafe for the current host, provider, account state, or action.

## Preflight Record

Before any external mutation, record these fields for each selected provider/action:

- `provider`: the search engine or webmaster platform.
- `selected action`: the exact requested operation.
- `network/tool capability`: available API, MCP, browser, network, or manual evidence capability.
- `auth/session state without account identifiers`: signed out, user-authenticated, session unavailable, or unknown, with no email, phone, tenant, property owner, or account ID.
- `ownership role`: verified owner, delegated owner, editor, viewer, unknown, or not applicable.
- `execution level`: Level 1, Level 2, Level 3, or Level 4.
- `approval`: provider/action-specific approval state and timestamp. Record `pending` when read-only preflight occurs before approval; a selected action may become preflight-blocked without prior approval.
- `evidence location`: planned or actual artifact path under the confirmed evidence root.
- `blocker`: missing capability, missing ownership, provider unavailable, unsafe request, user declined, or other concrete blocker.
- `retry`: next safe retry, rollback, or verification attempt.

Read-only capability checks may precede approval, but they must not trigger login, consent, property mutation, submission, verification, or any external state change.

## Approval And Safety

Obtain separate approval per provider/action before any external mutation. Read-only preflight and recording a concrete preflight blocker do not require prior approval. Approval for Google does not authorize Bing or Naver. Approval for property verification does not authorize sitemap submission, indexing requests, or import flows.

Never request or store passwords, tokens, recovery codes, cookies, or 2FA secrets. The user handles login, 2FA, CAPTCHA, consent screens, and account recovery. Mask account identifiers and provider responses before evidence persistence, including email addresses, phone numbers, account IDs, tenant IDs, property IDs, tokens embedded in URLs, and any provider response fields that could identify the user's account or session.

## Status Meanings

- `not-selected`: The provider/action was offered but not selected.
- `ready`: Preflight passed and the operation is waiting for provider/action-specific approval or execution.
- `assisted`: The agent safely assisted with a selected action but the provider has not accepted the mutation and no manual handoff is currently required.
- `manual-required`: The next step must be performed by the user in the official provider destination. A guide alone remains `manual-required`; manual handoff alone is not completed or verified.
- `blocked`: The selected action cannot safely proceed because capability, authorization, ownership, provider availability, policy, or evidence is missing.
- `completed`: The provider accepted the mutation, but the acceptance has not been independently verified.
- `verified`: Independently validated provider evidence or public evidence confirms the expected success state. User-supplied evidence qualifies only after the agent independently validates it against provider-visible or public state.
- `failed`: The provider rejected the action, verification contradicted the expected success state, or retry/rollback cannot reach a truthful non-failed state.

## Safe Transitions

- `not-selected` may move to `ready` only after the user selects that exact provider/action and read-only preflight succeeds.
- `not-selected` may move directly to `blocked` only after the user selects that exact provider/action and read-only preflight establishes a concrete blocker before `ready` could be reached. An action that was not selected must remain `not-selected`; blocked without selection is forbidden.
- `ready` may move to `completed` when approved Level 1 execution for the exact provider/action returns provider acceptance, or directly to `verified` when that result is also confirmed by independently validated provider or public evidence. Level 1 never routes through `assisted`.
- `ready` may move to `assisted` only for approved Level 2 browser assistance. It may move to `manual-required`, `blocked`, or `failed` after preflight and approval checks.
- `assisted` may move to `completed` when the provider accepts the mutation, `verified` when independent verification is already available, `manual-required` when user action is needed, `blocked` when progress is unsafe or unavailable, or `failed` when the provider rejects the action.
- `manual-required` may move to `verified` only after the user supplies safe evidence or public/provider confirmation that the agent validates. It may move to `completed` only if the evidence shows provider acceptance without independent verification. It may also move to `blocked` or `failed`.
- `completed` may move to `verified`, `blocked`, or `failed` after follow-up verification. It must not be presented as verified.
- `verified` is terminal unless later provider evidence invalidates it, in which case reopen as `failed` or `blocked` with a note.
- `blocked` may move to `ready` only when the exact provider/action remains selected, the concrete blocker is removed, and read-only preflight is repeated successfully. If provider/action approval already exists, it must still be valid. If no approval exists, record it as `pending` and obtain it before any external mutation; preflight-blocked actions do not need prior approval to reach `ready`.
- `failed` may move to `ready` only for an explicitly approved retry with a corrected action or rollback path.

## Manual Handoff Contract

When Level 3 is used, provide:

- Official destination: the first-party provider URL or documented product path.
- Exact user action and value: the precise button, field, verification method, sitemap URL, property URL, or setting value.
- Prerequisites: account access, ownership role, site URL, verified domain, generated file, DNS record, robots/sitemap availability, or other required condition.
- Expected success state: the provider-visible state that should appear after the user completes the action.
- Verification steps: public checks, provider confirmation, or safe user-supplied evidence the agent can validate.
- Safe evidence request: redacted screenshot, exported confirmation text, status page, public URL, or provider message with identifiers masked.
- Retry/rollback: how to retry safely, remove a verification file or DNS record, undo a submission where supported, or record that rollback is unavailable.

## Evidence Persistence

Persist external-operation evidence only under:

`<confirmed-evidence-root>/final/external-search/<provider>/`

Use redacted artifacts and manifest entries for each selected provider/action. Manifest entries must include provider, action, execution level, status, approval reference, artifact-relative paths, checksum of redacted artifacts, redaction notes, blocker, retry, and verification result. Do not persist unredacted account identifiers, provider secrets, session material, cookies, tokens, recovery codes, 2FA details, or CAPTCHA contents.
