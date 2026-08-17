---
name: "gas-optimizer"
description: "Use when auditing and optimizing a static, SSG, or SSR website for SEO, GEO, AEO, accessibility, performance, and deployment readiness with a non-compensating 95-point gate, two-stage approval, backups, and optional release extensions."
---

# GAS-Optimizer

Optimize crawlable websites without weakening evidence, truthfulness, accessibility, or existing functionality to manufacture a passing score.

## Hard gates

- Score SEO, GEO, AEO, accessibility, performance, and deployment readiness separately using `references/quality-rubric.md`.
- Every domain must score at least 95/100. Never average or compensate across domains.
- Any unresolved Critical or High issue, HTML validation error, broken primary workflow, false structured data, or exposed secret blocks completion regardless of score.
- Mark unmeasurable required checks as `[blocked]`; never assume they passed.
- Use current first-party Google, Bing, web-standard, and schema.org guidance. Treat vendor GEO claims as secondary.
- Require crawlable, meaningful initial HTML. JavaScript may progressively enhance content but must not be the only source of primary content.
- Do not begin optimization until both approval gates below are satisfied.

## Establish scope

1. Inspect the project, its existing tools, page types, build output, current deployment configuration, and user-stated constraints.
2. Confirm the project is static, SSG, or SSR. For a CSR-only application, report the crawlability limitation and agree on an SSR, SSG, or prerendering path before scoring it as ready.
3. Record the site purpose, audience, canonical host, representative page types, protected design or functionality, and content-editing boundaries.
4. Prefer the project's existing test, lint, build, and audit tools. Plan a small project-specific audit script only where repeatable coverage is missing.
5. Explain the optional extensions in this skill before offering them. Do not preselect any extension.

## Phase 1: Evidence-based analysis

1. Compare source or build-output HTML with the rendered experience. Count meaningful headings, links, page entities, and primary content available without client execution.
2. Audit all six domains using the common rubric. Add project-specific pass/fail checks when needed, but never lower, replace, or inflate the common criteria.
3. Validate representative page types, not only the homepage. If the site is too large for practical full coverage and large-site sampling was not selected, ask the user to define the page set.
4. Check visible claims, important external links, and structured data for alignment and truthfulness.
5. Create a dynamic analysis report from `assets/analysis-plan-template.html`, normally at the project's established documentation path or `Docs/analysis-plan.html` when no convention exists.
6. Include baseline scores, earned-versus-possible points, evidence, severity, affected files or URLs, remediation priorities, known limitations, and a locked implementation-plan section.
7. Stop and request explicit **analysis approval**. Do not modify production source files yet.

## Phase 2: File-level implementation plan

After analysis approval:

1. Update the same report with an ordered, file-level implementation plan.
2. Describe semantic HTML changes; crawlability; canonical, social, and indexation controls; visible direct-answer content; provenance; truthful JSON-LD; accessibility; performance; and deployment-readiness work.
3. Identify every proposed visible-content edit and how its factual accuracy will be verified.
4. Define a pre-change backup, checksums or manifest, rollback path, regression checks, audit-script changes, and expected verification evidence.
5. State which findings each change resolves. Predictions are not scores and must not be presented as measured outcomes.
6. Stop and request explicit **plan approval**. Do not create the backup or edit source files before approval unless the user explicitly asked for a read-only backup earlier.

## Phase 3: Backup and optimization

After plan approval:

1. Create the approved backup outside generated output, record checksums or a manifest, and verify that the rollback copy is readable.
2. Implement only approved changes. Preserve the user's visual language and primary workflows unless the plan explicitly changes them.
3. Prefer semantic elements and correct heading hierarchy over ARIA repair. Keep primary content, links, and direct answers in initial HTML.
4. Add or correct metadata, canonical URLs, social previews, robots controls, sitemap generation, redirects, security and cache policy, and a useful 404 response when applicable.
5. Use structured data only for facts visible or supportable on the page. Do not claim ownership, reviews, authorship, products, courses, organizations, or FAQs that the site cannot substantiate.
6. Improve GEO and AEO through clear entities, concise answers, definitions, lists, provenance, and people-first editorial value. Do not add prompt injection, artificial citation bait, hidden AI text, or unsupported AI-specific markup.
7. Add a repeatable, dependency-light audit script when the project lacks equivalent coverage. Keep it aligned with the actual project structure and build output.

## Phase 4: Regression and truth checks

- Exercise important workflows before and after optimization, including navigation, search, filtering, forms, dialogs, media, persisted state, and keyboard use where present.
- Compare representative screens at relevant viewport sizes. Treat clipped content, lost controls, major layout shifts, and broken responsive states as regressions.
- Recheck important outbound links and redirects.
- Confirm that structured data matches visible content and parses without critical errors.
- Validate HTML and run the project's tests, build, audit, and available accessibility or performance tools.
- If a preferred measurement tool is unavailable, use an honest fallback, label the evidence type, and keep unsupported checks blocked.

## Phase 5: Iterate and report

1. Rescore from fresh evidence after implementation.
2. Continue fixing approved-scope failures until all six domains pass or a real blocker prevents further progress.
3. Never remove a test, change a weight, mark a relevant item N/A, or rewrite a finding merely to reach 95.
4. Update the dynamic report with before-and-after scores, completed changes, regression results, validation output, remaining limitations, backup location, and rollback instructions.
5. Completion means quality-gate readiness only. Do not commit, push, deploy, register webmaster properties, or submit sitemaps unless the user separately selects and approves an optional extension.

## Optional extensions

Present extensions as off-by-default choices with a plain-language explanation. Before each selected action, show:

```text
Additional task:
Why it is useful:
What will change:
External impact:
Rollback or removal path:
Proceed?
```

### Offer before optimization

- **Git version control**: review ignore rules and secrets, initialize or connect a repository, and create checkpoints. Explain that this creates local or remote history. Get separate approval before creating a remote repository or pushing.
- **Dedicated evidence ledger**: attach each rubric item to commands, files, URLs, and outputs. Explain the added documentation cost.
- **Large-site sampling**: select representative URLs by page template and disclose that the result is sampled rather than exhaustive.

### Offer only after the 95-point gate passes

- **Vercel deployment**: connect or create a project, verify Preview, then request separate approval for Production. Explain public and operational changes.
- **Google Search Console**: verify ownership and optionally submit the sitemap. Explain that this supports indexing management but does not guarantee rankings or AI citations. Keep verification artifacts unless removal is approved.
- **Bing Webmaster Tools**: register or import the site and optionally submit the sitemap. Explain its effect on the user's Microsoft webmaster account.

For every external side effect, give the heads-up before acting even when the action is a sensible follow-up. Use relevant account or site skills when available. A user may select none, one, or several extensions; approval for one never authorizes another.

## Report requirements

- Keep analysis and implementation planning in the same dynamic HTML report.
- Clearly distinguish measured evidence, inferred risk, planned work, and blocked checks.
- Provide domain and severity filters, six score cards, the non-compensating gate state, approval state, findings, implementation plan, validation results, and optional-extension status.
- Keep the report usable without external scripts or styles.
- Do not present local lab observations as field Core Web Vitals.
