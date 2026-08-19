# Google Search Console Playbook

Google Search Console operations are optional, off by default, and governed by `references/external-search-operations.md`. Passing `quality-gate` is required before any external mutation, and any selected Google action remains tracked by `external-operations-gate` until the provider-specific evidence is validated.

Do not ask for or store credentials, OAuth tokens, cookies, recovery codes, 2FA secrets, CAPTCHA contents, or consent artifacts. The user performs login, 2FA, CAPTCHA, OAuth consent, and account recovery. Preserve existing ownership verification files, DNS records, meta tags, and related verification artifacts unless the user explicitly approves a change. Do not guarantee indexing, crawling time, ranking, rich results, or traffic.

## Scope/actions

Covered actions: property-registration, ownership-verification, sitemap-submission, post-submission-verification

- Provider: Google Search Console.
- Approved action categories: property registration, ownership verification, sitemap submission for a verified property, and post-submission evidence verification.
- Property registration, ownership verification, sitemap submission, and post-submission verification are separate actions with separate exact approvals and evidence.
- Out of scope: removal of verification artifacts, URL inspection/indexing requests, disavow files, removals, user or permission changes, and account settings.
- Each action starts as `not-selected`; it may move only through the statuses and transitions defined in `external-search-operations.md`.

## Prerequisites

- Property registration requires an exact action-specific approval naming the observed property type and scope. Do not infer a domain property, URL-prefix property, protocol, host, or path.
- Ownership verification requires a separate exact action-specific approval naming the observed verification method and artifact. Registration approval never authorizes verification.
- Search Console property ownership is required before sitemap submission or any ownership-dependent action.
- Sitemap submission requires verified ownership.
- Choose the property and verification method only from observed state; never guess a URL-prefix property, domain property, canonical host, protocol, path, or verification method.
- The sitemap URL must belong to the verified property scope and must be accessible without authentication.
- The site must already satisfy the core GAS-Optimizer `quality-gate`; Google operations never compensate for failed core SEO, GEO, AEO, accessibility, performance, or deployment readiness gates.
- Evidence storage must use `<confirmed-evidence-root>/final/external-search/google/` with redacted artifacts and manifest entries.

## Read-only preflight

Record the required preflight fields from the external search operations contract before approval or mutation:

- `provider`: Google Search Console.
- `selected action`: exactly one of property registration, ownership verification, sitemap submission, or post-submission verification.
- `network/tool capability`: official Search Console API, supported OAuth integration, authenticated browser, or manual evidence path.
- `auth/session state without account identifiers`: signed out, user-authenticated, session unavailable, or unknown.
- `ownership role`: verified owner, delegated owner, editor, viewer, unknown, or not applicable.
- `execution level`: Level 1, Level 2, Level 3, or Level 4 using deterministic downgrade order.
- `approval`, `evidence location`, `blocker`, and `retry`.

Read-only checks may identify available properties, sitemap URLs, verification artifacts, robots availability, and public sitemap reachability. They must not trigger login, OAuth consent, property changes, sitemap submission, verification changes, or any other external mutation.

## Level 1

Level actions: property-registration, ownership-verification, sitemap-submission, post-submission-verification

Use Level 1 only when an official Search Console API, approved MCP tool, official CLI, or supported first-party integration is available for the exact selected action and can return provider confirmation. User-authorized OAuth may be used only through the supported integration flow; do not collect, display, or persist tokens.

For property registration or ownership verification:

1. Observe the exact property type/scope and, for verification, the exact provider-offered verification method/artifact.
2. Obtain approval that names only that exact action and observed scope or method.
3. Execute only if the current official integration explicitly supports that exact action; the existence of a sitemap API or another integration capability is not evidence of registration or verification support.
4. Preserve existing verification artifacts and persist provider acceptance without credentials, tokens, or account identifiers.

For sitemap submission:

1. Confirm `quality-gate` has passed.
2. Confirm the selected Search Console property is observed and verified.
3. Confirm the sitemap URL is inside the verified property scope.
4. Obtain Google/action-specific approval.
5. Submit with the official API or supported integration.
6. Persist only redacted confirmation evidence and a manifest entry.

For post-submission verification, independently validate the observed provider status or public sitemap evidence before using `verified`.

If the exact-action capability, OAuth, ownership, property, observed method, or confirmation requirement is missing, downgrade to Level 2, then Level 3, then Level 4. Do not invent API availability or a verification method.

## Level 2

Level actions: property-registration, ownership-verification, sitemap-submission, post-submission-verification

Use Level 2 only after explicit approval and only within an authenticated Search Console browser session where the user performs login, 2FA, CAPTCHA, and consent. The agent may assist with navigation and form completion for the selected action after the user is authenticated.

For property registration, use only the observed property type and scope named in its approval. For ownership verification, use only the method and artifact currently offered in the observed provider state and named in its separate approval. Do not bundle registration and verification, select a different method, or continue through a new consent screen without pausing for the user.

The user completes every login, 2FA, CAPTCHA, and consent prompt before assistance resumes. For sitemap submission, operate only on the observed verified property selected by the user. Preserve all existing verification artifacts. Persist redacted screenshots or confirmation text only after masking account and property identifiers where needed.

If the browser session is unavailable, the user cannot authenticate, the observed role cannot submit, or provider confirmation cannot be safely captured, downgrade to Level 3 or Level 4.

## Level 3 manual handoff

Level actions: property-registration, ownership-verification, sitemap-submission, post-submission-verification

Level 3 is `manual-required` until safe evidence is supplied and validated. Provide the user with these exact handoff fields:

- Official destination: `https://search.google.com/search-console`.
- Exact property: the observed Search Console property URL or domain property label, redacted in persisted reports when it identifies the user.
- Selected action: exactly one of property registration, ownership verification, sitemap submission, or post-submission verification.
- Property registration steps: state the exact observed property type and scope, then provide the exact UI path and values shown by the current provider state. Do not prescribe an unobserved property type or combine the subsequent ownership action.
- Ownership verification steps: state the exact observed provider-offered verification method, artifact, UI path, and user steps. Preserve that artifact and all existing verification artifacts; do not substitute an unobserved method.
- Sitemap URL: the exact sitemap URL that matches the verified property scope.
- Verification method/artifact: only the method and artifact observed in current Search Console state. Do not invent or infer available methods.
- Submission steps: open Search Console, select the exact property, open Sitemaps, enter the sitemap URL or path requested by the UI, submit, and copy or screenshot the resulting provider status with identifiers masked.
- Verification steps: for registration or ownership, capture the observed provider result and independently validate the resulting property/ownership state; for sitemap work, confirm the submitted sitemap appears in the Sitemaps report and independently validate provider status or public sitemap evidence. Provide a redacted screenshot or exported confirmation text.
- Expected success state: Google accepts the exact selected action. Provider acceptance permits `completed`; only independently validated provider or public evidence permits `verified`. Acceptance is not an indexing or ranking guarantee.
- Retry/rollback: retry only after fixing the concrete rejection reason such as inaccessible sitemap, wrong property scope, robots block, invalid XML, or missing ownership. Where Search Console allows removing a submitted sitemap entry, the user performs removal manually; otherwise record rollback as unavailable.

The agent may move from `manual-required` to `completed` only when evidence shows provider acceptance, and to `verified` only when provider confirmation or safe user-supplied evidence is validated.

## Level 4 blockers

Level actions: property-registration, ownership-verification, sitemap-submission, post-submission-verification
Blocked retry requirements: selected-action=required; blocker-removal=required; read-only-preflight=repeated-successfully; existing-approval=must-remain-valid; missing-approval=record-pending-and-obtain-before-mutation; prior-approval-for-preflight-blocked=not-required

Use Level 4 `blocked` only after deterministic downgrade confirms no safe Level 2 authenticated-browser path and no safe Level 3 manual handoff path are available for the selected action. Lack of a Level 1 API/MCP/support integration is not a standalone blocker. Concrete blockers include:

- Missing or failed `quality-gate`.
- No observed property type/scope for registration, no observed provider-offered method/artifact for ownership verification, or no observed Search Console property for an ownership-dependent action.
- Missing verified ownership or insufficient role.
- Unknown or mismatched canonical property, protocol, host, path, or sitemap URL.
- User declines Google/action-specific approval, OAuth consent, login, 2FA, CAPTCHA, or manual handoff.
- Provider UI/API unavailable, returns an unresolvable rejection, or confirmation cannot be safely redacted.
- Request requires storing credentials, tokens, cookies, or unredacted account identifiers.

Retry only when the exact Google provider/action remains selected, the concrete blocker is removed, and read-only preflight is repeated successfully. Preserve an existing approval only if it is still valid; otherwise set approval to `pending` and obtain it before any external mutation. A preflight-blocked action does not need prior approval. Keep the provider/action `blocked` until the selection, blocker-removal, and repeated-preflight conditions are met.

## Evidence/verification

- Persist evidence only under `<confirmed-evidence-root>/final/external-search/google/`.
- Manifest entries must include provider, action, execution level, status, approval reference, artifact-relative paths, checksums, redaction notes, blocker, retry, and verification result.
- Redact account identifiers, property identifiers where identifying, OAuth details, URLs containing tokens, screenshots with emails, and any session material.
- Verify only what the evidence supports: provider acceptance, visible sitemap status, public sitemap availability, or documented blocker. Do not claim indexing, ranking, discovery, recrawl timing, or traffic outcomes.

## Official sources

- https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap
- https://developers.google.com/webmaster-tools/v1/quickstart/quickstart-python
