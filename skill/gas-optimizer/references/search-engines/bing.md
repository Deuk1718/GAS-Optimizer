# Bing Webmaster Tools Playbook

Bing Webmaster Tools operations are optional, off by default, and governed by `references/external-search-operations.md`. Passing `quality-gate` is required before any external mutation, and any selected Bing action remains tracked by `external-operations-gate` until provider-specific evidence is validated.

Do not ask for or store credentials, API keys, IndexNow keys, cookies, recovery codes, 2FA secrets, CAPTCHA contents, or consent artifacts. The user performs login, 2FA, CAPTCHA, consent, account recovery, and any separate Search Console import authorization. Preserve existing ownership verification files, DNS records, meta tags, XML files, CNAME records, and related verification artifacts unless the user explicitly approves a change. Do not guarantee indexing, crawl timing, ranking, rich results, or traffic.

## Scope/actions

Covered actions: site-registration, ownership-verification, search-console-import, sitemap-submission, indexnow-notification

- Provider: Bing Webmaster Tools.
- Approved action categories: site registration, native ownership verification, Search Console import, sitemap submission for an owned site, and optional IndexNow notification.
- Site registration, native ownership verification, Search Console import, sitemap submission, and IndexNow are separate actions with separate approvals, authorizations, and evidence.
- IndexNow can run without Bing Webmaster Tools registration when the user or CMS controls the host through the official key-file protocol.
- Search Console import may be used only when observed. It requires separate user Google authorization and must never be bundled with site registration or native ownership verification.
- Out of scope: adding new users, changing roles, deleting sites, removing verification artifacts, changing account settings, and bulk URL submission.
- Each action starts as `not-selected`; it may move only through the statuses and transitions defined in `external-search-operations.md`.

## Prerequisites

- Site registration, native ownership verification, and Search Console import each require separate exact action-specific approval. Import additionally requires the user to complete Google authorization.
- Bing Webmaster Tools site ownership or an authorized role is required before Bing Webmaster Tools sitemap submission and other ownership-dependent actions.
- IndexNow does not require Bing Webmaster Tools registration; it proves host control through a same-host key file retained by the user or CMS.
IndexNow path scope: root-key-file=host-wide; non-root-keyLocation=urlList-under-key-directory
- A root key file authorizes URLs across the submitted host. When optional `keyLocation` points below the root, every submitted `urlList` URL must be under the key file's directory path as well as on the same host.
- Observed verification options can include native Bing verification or Search Console import, but import requires separate Google authorization and user consent.
- The sitemap URL must match the verified site scope and must be publicly accessible.
- IndexNow key material is secret-like. The user or CMS retains the key, and the agent/report never receives or persists it in reports, manifests, logs, screenshots, URLs, or evidence.
- The site must already satisfy the core GAS-Optimizer `quality-gate`; Bing operations never compensate for failed core gates.
- Evidence storage must use `<confirmed-evidence-root>/final/external-search/bing/` with redacted artifacts and manifest entries.

## Read-only preflight

IndexNow path scope: root-key-file=host-wide; non-root-keyLocation=urlList-under-key-directory

Record the required preflight fields from the external search operations contract before approval or mutation:

- `provider`: Bing Webmaster Tools.
- `selected action`: for example, submit sitemap or notify IndexNow.
- `network/tool capability`: current official supported API/MCP/integration, authenticated browser, or manual evidence path.
- `auth/session state without account identifiers`: signed out, user-authenticated, session unavailable, or unknown.
- `ownership role`: verified owner, delegated owner, editor, viewer, unknown, or not applicable.
- `execution level`: Level 1, Level 2, Level 3, or Level 4 using deterministic downgrade order.
- `approval`, `evidence location`, `blocker`, and `retry`.

Read-only checks may identify observed sites, roles, native verification methods, whether Search Console import is offered, public sitemap reachability, IndexNow key-file presence without exposing key material, key-file root/directory scope, and current official integration availability. They must not trigger login, consent, import authorization, sitemap submission, IndexNow notification, verification mutation, or any external state change.

## Level 1

Level actions: site-registration, ownership-verification, search-console-import, sitemap-submission, indexnow-notification

Use Level 1 only when a current official supported API, approved MCP tool, official CLI, or equivalent first-party integration is actually available for the exact selected action and can return provider confirmation. If no current official supported integration is available, downgrade rather than inventing an API path.

For site registration, native ownership verification, or Search Console import, observe the exact provider state, obtain separate approval for only that action, and execute only when the current official integration explicitly supports that exact action. Search Console import requires the user to complete its separate Google authorization; it cannot inherit registration or ownership approval.

For sitemap submission:

1. Confirm `quality-gate` has passed.
2. Confirm the selected Bing site is observed and owned or the role can submit sitemaps.
3. Confirm the sitemap URL matches the verified site scope.
4. Obtain Bing/action-specific approval.
5. Submit with the official supported integration.
6. Persist only redacted confirmation evidence and a manifest entry.

For optional IndexNow:

1. Confirm IndexNow was separately selected and approved.
2. Confirm the user or CMS can keep the IndexNow key out of agent/report visibility.
3. Confirm key-file verification and path scope are valid: a root key file permits host-wide URLs, while non-root optional `keyLocation` permits only URLs under that key file directory.
4. POST only the approved URL set to `https://api.indexnow.org/indexnow` using JSON fields `host`, `key`, optional `keyLocation`, and `urlList`.
5. Persist redacted provider response evidence. Mask key material and any secret-like query parameters.

If a sitemap capability, ownership, role, approval, or confirmation requirement is missing, downgrade to Level 2, then Level 3, then Level 4. If no safe supported Level 1 IndexNow integration exists, downgrade directly to Level 3; browser-assisted Bing Webmaster Tools is not required for IndexNow.

## Level 2

Level actions: site-registration, ownership-verification, search-console-import, sitemap-submission, indexnow-notification

Use Level 2 only after explicit approval and only within an authenticated Bing Webmaster Tools browser session where the user performs login, 2FA, CAPTCHA, consent, and any external authorization. The agent may assist with navigation and form completion for the selected action after the user is authenticated.

For site registration, enter only the exact observed site scope named in its approval, then stop before ownership verification unless that separate action is approved. For native ownership verification, use only the method/artifact observed in the current Bing state and preserve it. For Search Console import, pause for the user to complete the separate Google login, authorization, consent, and property selection; never bundle or infer that authorization. For sitemap submission, operate only on the observed owned site selected by the user.

Do not use browser-assisted Bing Webmaster Tools as a prerequisite for IndexNow; use Level 3 protocol instructions when no safe supported Level 1 integration exists. Do not change roles, remove verification artifacts, or alter account settings.

If the browser session is unavailable, the user cannot authenticate, the observed role cannot perform the sitemap action, or provider confirmation cannot be safely captured, downgrade to Level 3 or Level 4.

## Level 3 manual handoff

Level actions: site-registration, ownership-verification, search-console-import, sitemap-submission, indexnow-notification
IndexNow path scope: root-key-file=host-wide; non-root-keyLocation=urlList-under-key-directory

Level 3 is `manual-required` until safe evidence is supplied and validated. Provide the user with these exact handoff fields:

- Official destination: `https://www.bing.com/webmasters` for sitemap work; `https://api.indexnow.org/indexnow` for IndexNow POST requests.
- Exact site/host: the observed Bing Webmaster Tools site URL or domain label for sitemap work, or the exact IndexNow `host` value controlled by the user/CMS for IndexNow. Redact persisted reports when it identifies the user.
- Selected action: exactly one of site registration, native ownership verification, Search Console import, sitemap submission, or IndexNow notification.
- Site registration steps: give the exact observed site scope, provider UI path, values, and expected registered state; stop before ownership unless separately approved.
- Native ownership verification steps: give only the exact method, artifact, values, and UI path observed in current Bing state. Preserve the artifact and do not substitute an unobserved method.
- Search Console import steps: identify the option only when observed, state that it is a separate action, and have the user complete Google login, authorization, consent, and property selection. Registration or native ownership approval does not authorize import.
- Verification method/artifact: the exact method and artifact observed in current provider state. Preserve the current verification artifact.
- Sitemap steps: open Bing Webmaster Tools, select the exact site, open Sitemaps, submit the exact sitemap URL, and capture the accepted, pending, or rejected state with identifiers masked.
- IndexNow exact value/URL fields: POST JSON to `https://api.indexnow.org/indexnow` with `host`, `key`, optional `keyLocation`, and `urlList`. The user or CMS supplies the `key` outside the agent and report; do not paste it into chat, evidence, manifests, logs, or screenshots.
- IndexNow steps: verify the key file is reachable at the root or declared same-host `keyLocation` for the submitted `host`. A root key file authorizes host-wide URLs. For non-root `keyLocation`, confirm every `urlList` URL is under that key file directory path. Also confirm every URL belongs to the host, submit only separately approved URLs, and keep approvals/evidence separate.
- IndexNow response interpretation: `200` means accepted, `202` means accepted pending key validation, `400` means malformed request, `403` means authentication/key failure, `422` means URL-host scope mismatch or unprocessable URL, and `429` means rate limit. None of these statuses guarantees indexing.
- Verification steps: provide redacted provider evidence for the selected registration, ownership, import, sitemap, or IndexNow action. For IndexNow, include response code/body with the key removed plus independently checked root/directory path scope.
- Expected success state: Bing accepts the exact selected action. Provider acceptance permits `completed`; only independently validated provider or public evidence permits `verified`. Acceptance is not an indexing or ranking guarantee.
- Retry/rollback: retry only after fixing the concrete rejection. For IndexNow, missing/unreachable key files, host mismatch, or a URL outside a non-root key-file directory require correcting the key location or narrowing `urlList` before retry. If removal or rollback is unsupported, record it as unavailable.

The agent may move from `manual-required` to `completed` only when evidence shows provider acceptance, and to `verified` only when provider confirmation or safe user-supplied evidence is validated.

## Level 4 blockers

Level actions: site-registration, ownership-verification, search-console-import, sitemap-submission, indexnow-notification
IndexNow path scope: root-key-file=host-wide; non-root-keyLocation=urlList-under-key-directory
Blocked retry requirements: selected-action=required; blocker-removal=required; read-only-preflight=repeated-successfully; existing-approval=must-remain-valid; missing-approval=record-pending-and-obtain-before-mutation; prior-approval-for-preflight-blocked=not-required

Use Level 4 `blocked` only after deterministic downgrade confirms no safe Level 2 path where applicable and no safe Level 3 manual handoff path are available for the selected action. Lack of a Level 1 API/MCP/integration is not a standalone blocker; for IndexNow, lack of a supported Level 1 integration downgrades directly to Level 3. Concrete blockers include:

- Missing or failed `quality-gate`.
- No observed Bing Webmaster Tools site for a selected sitemap action.
- Missing ownership, insufficient role, or unconfirmed Search Console import authorization for a Bing Webmaster Tools ownership-dependent action.
- Unknown or mismatched canonical site, protocol, host, path, sitemap URL, or IndexNow key location.
- IndexNow key material would need to be stored or displayed unredacted.
- IndexNow cannot verify the key file, approved URLs do not match the submitted host, or a non-root `keyLocation` has any submitted URL outside its key-file directory path.
- User declines Bing/action-specific approval, login, 2FA, CAPTCHA, consent, import authorization, or manual handoff.
- Provider UI/API unavailable, returns an unresolvable rejection, or confirmation cannot be safely redacted.

Retry only when the exact Bing provider/action remains selected, the concrete blocker is removed, and read-only preflight is repeated successfully. Preserve an existing approval only if it is still valid; otherwise set approval to `pending` and obtain it before any external mutation. A preflight-blocked action does not need prior approval. For IndexNow path-scope blockers, move the key file to the root for host-wide scope or narrow `urlList` to the non-root key-file directory before repeated preflight. Keep the provider/action `blocked` until the selection, blocker-removal, and repeated-preflight conditions are met.

## Evidence/verification

IndexNow path scope: root-key-file=host-wide; non-root-keyLocation=urlList-under-key-directory

- Persist evidence only under `<confirmed-evidence-root>/final/external-search/bing/`.
- Manifest entries must include provider, action, execution level, status, approval reference, artifact-relative paths, checksums, redaction notes, blocker, retry, and verification result.
- Redact account identifiers, site identifiers where identifying, IndexNow key material, secret-like URLs, screenshots with emails, and any session material.
- Verify only what the evidence supports: provider acceptance for the exact selected action, visible registration/ownership/import/sitemap status, IndexNow response, public sitemap availability, or key-file presence without exposing the key. IndexNow evidence must record whether the key file was root/host-wide or non-root/directory-scoped and confirm all submitted URLs fit that scope. Do not claim indexing, ranking, crawl timing, or traffic outcomes.

## Official sources

- https://www.bing.com/webmasters/help/getting-started-checklist-66a806de
- https://www.bing.com/webmasters/help/add-and-verify-site-12184f8b
- https://www.indexnow.org/documentation
