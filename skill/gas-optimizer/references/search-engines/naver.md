# Naver Search Advisor Playbook

Naver Search Advisor operations are optional, off by default, and governed by `references/external-search-operations.md`. Passing `quality-gate` is required before any external mutation, and any selected Naver action remains tracked by `external-operations-gate` until provider-specific evidence is validated.

Do not ask for or store credentials, cookies, recovery codes, 2FA secrets, CAPTCHA contents, API keys, IndexNow keys, or consent artifacts. The user performs login, 2FA, CAPTCHA, consent, and account recovery. Preserve existing ownership verification files, DNS records, meta tags, HTML files, and related verification artifacts unless the user explicitly approves a change. Do not guarantee indexing, crawl timing, ranking, rich results, or traffic.

## Scope/actions

Covered actions: site-registration, ownership-verification, sitemap-submission, rss-submission, indexnow-notification, manual-crawl-request

- Provider: Naver Search Advisor.
- Approved action categories: host-level site registration, host-level ownership verification, sitemap submission, optional RSS feed submission, optional IndexNow notification, and selective manual crawl request.
- Site registration, ownership verification, sitemap, RSS feed, IndexNow, and manual crawl request are separate actions with separate approvals and evidence.
- IndexNow is optional and does not replace sitemap, RSS, or manual crawl request flows.
- IndexNow can operate without Naver Search Advisor registration because it proves host control through the same-host key-file protocol.
- Manual crawl requests are selective and should not be repeated daily or used as a bulk indexing substitute.
- Out of scope unless separately approved: account settings, user permissions, removal of verification artifacts, repeated crawl-request automation, and any action outside the verified domain.
- Each action starts as `not-selected`; it may move only through the statuses and transitions defined in `external-search-operations.md`.

## Prerequisites

- Host-level site registration and host-level ownership verification require separate exact action-specific approvals. Observe the exact host before either action; registration approval does not authorize ownership verification.
- Naver Search Advisor site registration and ownership are required before sitemap/RSS submission, manual crawl requests, or other Search Advisor ownership-dependent actions.
- IndexNow does not require Naver Search Advisor registration or ownership; it proves host control through a root or same-host key file retained by the user or CMS.
IndexNow path scope: root-key-file=host-wide; non-root-keyLocation=urlList-under-key-directory
- A root key file authorizes URLs across the submitted host. When optional `keyLocation` is below the root, every submitted `urlList` URL must be under that key file's directory path as well as on the same host.
- The sitemap and RSS URLs must match the verified domain exactly as accepted by Naver Search Advisor.
- Yeti crawl access must be verified before submission or crawl request: robots rules, server availability, redirects, and blocking controls must allow Naver's crawler to access the approved URLs.
Feed constraints: sitemap-size=<10-MB; sitemap-url-count=<=50,000; rss-size=<10-MB; rss-item-count=>=1; rss-full-current-content=recommendation-unless-observed-provider-rejection
- Sitemap submissions must be `<10 MB` and contain `<=50,000 URLs`.
- RSS submissions must be `<10 MB` and contain `>=1 item`; these are hard submission constraints.
- Full, current RSS item content is a recommendation, not a hard submission constraint, unless an observed provider validation explicitly rejects the feed for that reason. Favor sitemap for broad URL coverage.
- IndexNow is optional, does not replace Naver sitemap/RSS/manual crawl request workflows, and does not guarantee indexing. The user or CMS retains the IndexNow key, and the agent/report never receives or persists it.
- The site must already satisfy the core GAS-Optimizer `quality-gate`; Naver operations never compensate for failed core gates.
- Evidence storage must use `<confirmed-evidence-root>/final/external-search/naver/` with redacted artifacts and manifest entries.

## Read-only preflight

IndexNow path scope: root-key-file=host-wide; non-root-keyLocation=urlList-under-key-directory

Record the required preflight fields from the external search operations contract before approval or mutation:

- `provider`: Naver Search Advisor.
- `selected action`: for example, submit sitemap, submit RSS, notify IndexNow, or request crawl.
- `network/tool capability`: official supported integration, authenticated browser, or manual evidence path.
- `auth/session state without account identifiers`: signed out, user-authenticated, session unavailable, or unknown.
- `ownership role`: verified owner, delegated owner, editor, viewer, unknown, or not applicable.
- `execution level`: Level 1, Level 2, Level 3, or Level 4 using deterministic downgrade order.
- `approval`, `evidence location`, `blocker`, and `retry`.

Read-only checks may identify the exact host, observed registered sites, observed HTML file/meta verification path, sitemap/RSS URL reachability, robots rules, Yeti access indicators, IndexNow key-file root/directory scope, and provider validation messages. They must not trigger login, consent, site registration, ownership mutation, sitemap/RSS submission, IndexNow notification, crawl request, or any external state change.

## Level 1

Level actions: site-registration, ownership-verification, sitemap-submission, rss-submission, indexnow-notification, manual-crawl-request

Use Level 1 only when a current official supported API, approved MCP tool, official CLI, or equivalent first-party integration is actually available for the exact selected action and can return provider confirmation. If no current official supported integration is available, downgrade rather than inventing an API path.

For host-level site registration or ownership verification, observe the exact host and current provider state, obtain separate approval for that exact action, and execute only if a current official integration explicitly supports it. For ownership, use only the HTML file or meta verification path actually observed from Naver state and preserve the artifact.

For sitemap or RSS submission:

1. Confirm `quality-gate` has passed.
2. Confirm the selected Naver site is registered and owned.
3. Confirm the sitemap or RSS URL matches the verified domain.
4. Confirm Yeti crawl access and respect observed feed validation limits.
5. Obtain Naver/action-specific approval.
6. Submit with the official supported integration.
7. Persist only redacted confirmation evidence and a manifest entry.

For optional IndexNow or manual crawl request:

1. Confirm the action was separately selected and approved.
2. Confirm URL scope, Yeti access for sitemap/RSS/manual crawl where applicable, and user/CMS-only key handling constraints for IndexNow.
3. For IndexNow, confirm key-file scope: root permits host-wide URLs, while non-root optional `keyLocation` permits only URLs under its directory. POST only approved in-scope URLs to `https://api.indexnow.org/indexnow` using JSON fields `host`, `key`, optional `keyLocation`, and `urlList`, and do not expose the key to the agent or report.
4. For manual crawl request, submit only the approved selective URL set; manual crawl requests must not be repeated daily.
5. Persist redacted provider response evidence. Mask any secret-like key material.

If any sitemap/RSS/manual-crawl capability, ownership, URL scope, Yeti access, feed validation, approval, or confirmation requirement is missing, downgrade to Level 2, then Level 3, then Level 4. If no safe supported Level 1 IndexNow integration exists, downgrade directly to Level 3; authenticated Naver Search Advisor Level 2 is not required for IndexNow.

## Level 2

Level actions: site-registration, ownership-verification, sitemap-submission, rss-submission, indexnow-notification, manual-crawl-request

Use Level 2 only after exact action-specific approval and only within an authenticated Naver Search Advisor browser session after the user performs login, 2FA, CAPTCHA, consent, and account recovery. The agent may assist with the selected Search Advisor action only after user authentication is complete.

For host-level site registration, enter only the exact observed host named in its approval and stop before ownership. For ownership verification, require its separate approval and use only the observed HTML file or meta verification path; preserve the resulting and existing artifacts. For sitemap/RSS, operate only on the observed verified site, enforce sitemap `<10 MB` and `<=50,000 URLs`, enforce RSS `<10 MB` and `>=1 item`, and treat full/current item content as a recommendation unless observed provider validation rejects it. For manual crawl requests, submit only selectively approved URLs and do not repeat daily. Do not use authenticated Naver Search Advisor Level 2 as an IndexNow prerequisite.

Do not change an observed verification method, remove verification artifacts, alter account settings, or expand actions beyond the selected approval. If the browser session is unavailable, the user cannot authenticate, the observed role cannot perform the action, hard URL/feed constraints fail, Yeti access is blocked, or provider confirmation cannot be safely captured, downgrade to Level 3 or Level 4.

## Level 3 manual handoff

Level actions: site-registration, ownership-verification, sitemap-submission, rss-submission, indexnow-notification, manual-crawl-request
IndexNow path scope: root-key-file=host-wide; non-root-keyLocation=urlList-under-key-directory

Level 3 is `manual-required` until safe evidence is supplied and validated. Provide the user with these exact handoff fields:

- Official destination: `https://searchadvisor.naver.com` for sitemap/RSS/manual crawl work; `https://api.indexnow.org/indexnow` for IndexNow POST requests.
- Exact site/host: the observed Naver Search Advisor registered domain or URL-prefix label for sitemap/RSS/manual crawl work, or the exact IndexNow `host` value controlled by the user/CMS for IndexNow. Redact persisted reports when it identifies the user.
- Selected action: exactly one of host-level site registration, ownership verification, sitemap submission, RSS submission, IndexNow notification, or selective manual crawl request.
- Site registration steps: provide the exact observed host, current Search Advisor UI path, exact value, and expected registered state. Stop before ownership unless it has separate approval.
- Ownership verification steps: provide the exact host and only the HTML file or meta verification path observed in current Naver state, including exact placement/value and UI confirmation steps. Preserve the observed artifact and every existing verification artifact.
- Verification method/artifact: the exact observed HTML file or meta method and artifact; never invent an unavailable method.
- Yeti crawl-access check: for sitemap/RSS/manual crawl actions, confirm robots and server responses allow Naver Yeti to access the approved sitemap, RSS, or page URLs. This Search Advisor UI check is not an IndexNow prerequisite.
- Sitemap exact value/URL fields: submit the exact sitemap URL only when it matches the verified site domain, is publicly reachable by Yeti, is below Naver's documented 10 MB submission limit, and contains no more than 50,000 URLs.
- Sitemap steps: open Naver Search Advisor, select the exact verified site, open the sitemap submission area, submit the exact sitemap URL matching the verified domain, and capture the accepted, pending, or rejected state with identifiers masked.
- RSS exact value/URL fields: submit the exact RSS URL only when it matches the verified site domain, is `<10 MB`, and contains `>=1 item`. Full/current item content is recommended unless observed provider validation rejects it.
- RSS steps: enforce the two hard constraints, follow any observed provider rejection, and otherwise treat content completeness/currentness as guidance. Broad URL coverage favors sitemap.
- IndexNow exact value/URL fields: POST JSON to `https://api.indexnow.org/indexnow` with `host`, `key`, optional `keyLocation`, and `urlList`. The user or CMS supplies the `key` outside the agent and report; do not paste it into chat, evidence, manifests, logs, or screenshots.
- IndexNow steps: verify the key file is reachable at the root or declared same-host `keyLocation`. A root key file authorizes host-wide URLs. For non-root `keyLocation`, confirm every `urlList` URL is under that key file directory path. Also confirm each URL belongs to the host, submit only separately approved URLs, and keep all approvals/evidence separate.
- IndexNow response interpretation: `200` means accepted, `202` means accepted pending key validation, `400` means malformed request, `403` means authentication/key failure, `422` means URL-host scope mismatch or unprocessable URL, and `429` means rate limit. None of these statuses guarantees indexing.
- Manual crawl request steps: request crawl only for the selected URL or small approved URL set, not as repeated daily automation.
- Verification steps: provide redacted evidence for the exact selected action. For IndexNow, include response code/body with the key removed plus independently checked root/directory path scope. For registration/ownership, independently validate provider-visible host and ownership state.
- Expected success state: Naver accepts the exact selected action. Provider acceptance permits `completed`; only independently validated provider or public evidence permits `verified`. Acceptance is not an indexing or ranking guarantee.
- Retry/rollback: retry only after fixing concrete rejection reasons. RSS size `>=10 MB` or zero items must be corrected; full/current content is not itself a blocker unless an observed provider validation rejected it. For IndexNow, correct the key location or narrow `urlList` when any URL falls outside a non-root key-file directory. Preserve verification artifacts; if removal or rollback is unsupported, record it as unavailable.

The agent may move from `manual-required` to `completed` only when evidence shows provider acceptance, and to `verified` only when provider confirmation or safe user-supplied evidence is validated.

## Level 4 blockers

Level actions: site-registration, ownership-verification, sitemap-submission, rss-submission, indexnow-notification, manual-crawl-request
IndexNow path scope: root-key-file=host-wide; non-root-keyLocation=urlList-under-key-directory
Blocked retry requirements: selected-action=required; blocker-removal=required; read-only-preflight=repeated-successfully; existing-approval=must-remain-valid; missing-approval=record-pending-and-obtain-before-mutation; prior-approval-for-preflight-blocked=not-required

Use Level 4 `blocked` only after deterministic downgrade confirms no safe Level 2 path where applicable and no safe Level 3 manual handoff path are available for the selected action. Lack of a Level 1 API/MCP/integration is not a standalone blocker; for IndexNow, lack of a supported Level 1 integration downgrades directly to Level 3. Concrete blockers include:

- Missing or failed `quality-gate`.
- No exact observed host for registration, no observed HTML file/meta path for ownership, or no observed registered site for a selected ownership-dependent action.
- Missing ownership, insufficient role, or unavailable user login/2FA/CAPTCHA/consent for a selected sitemap, RSS, or manual crawl action.
- Sitemap or RSS URL does not match the verified domain.
- Sitemap submission exceeds Naver's documented 10 MB limit or contains more than 50,000 URLs.
- RSS submission is `>=10 MB` or contains fewer than one item.
- Observed provider validation rejects the RSS for content completeness/currentness and no safe correction or handoff is available.
- Yeti crawl access is blocked by robots rules, authentication, server errors, redirects, geoblocking, or unavailable public URLs.
- Observed feed validation or limits reject the sitemap/RSS.
- IndexNow key material would need to be stored or displayed unredacted.
- IndexNow cannot verify the key file, approved URLs do not match the submitted host, or a non-root `keyLocation` has any submitted URL outside its key-file directory path.
- Manual crawl request would be repeated daily, bulk, outside verified scope, or otherwise unsafe.
- Provider UI/API unavailable, returns an unresolvable rejection, or confirmation cannot be safely redacted.

Retry only when the exact Naver provider/action remains selected, the concrete blocker is removed, and read-only preflight is repeated successfully. Preserve an existing approval only if it is still valid; otherwise set approval to `pending` and obtain it before any external mutation. A preflight-blocked action does not need prior approval. For IndexNow path-scope blockers, move the key file to the root for host-wide scope or narrow `urlList` to the non-root key-file directory before repeated preflight. Keep the provider/action `blocked` until the selection, blocker-removal, and repeated-preflight conditions are met.

## Evidence/verification

IndexNow path scope: root-key-file=host-wide; non-root-keyLocation=urlList-under-key-directory

- Persist evidence only under `<confirmed-evidence-root>/final/external-search/naver/`.
- Manifest entries must include provider, action, execution level, status, approval reference, artifact-relative paths, checksums, redaction notes, blocker, retry, and verification result.
- Redact account identifiers, site identifiers where identifying, IndexNow key material, secret-like URLs, screenshots with emails, and any session material.
- Verify only what the evidence supports: provider acceptance for the exact selected action, visible host/ownership/sitemap/RSS status, IndexNow response, public sitemap/RSS availability, Yeti crawl access, selective crawl-request status, or documented blocker. IndexNow evidence must record whether the key was root/host-wide or non-root/directory-scoped and confirm all submitted URLs fit that scope. RSS evidence must distinguish hard size/item-count constraints from the full/current-content recommendation and any observed provider rejection. Do not claim indexing, ranking, crawl timing, or traffic outcomes.

## Official sources

- https://searchadvisor.naver.com/guide/seo-basic-intro
- https://searchadvisor.naver.com/guide/request-feed
- https://searchadvisor.naver.com/guide/indexnow-faq
- https://searchadvisor.naver.com/guide/request-crawl
