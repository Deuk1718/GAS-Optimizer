# GAS-Optimizer Common Quality Rubric

Use this rubric as the fixed 100-point core for each domain. Record earned and possible points for every component. Project-specific checks may add blocking conditions or clarify a component, but must not add bonus points or lower the common standard.

## Scoring rules

- Passing requires at least 95/100 in every domain.
- Scores never compensate across domains.
- An unresolved Critical or High issue blocks the overall result even if the arithmetic score is 95 or higher.
- A required check without evidence is `[blocked]`, not passed.
- Mark an item N/A only when it is genuinely inapplicable to the site's function. Explain why and normalize within that component; never use N/A to hide missing implementation.
- Award partial points only when the evidence shows a real partial implementation. Record the missing behavior.
- Use fresh build output and current production evidence when production is in approved scope. Do not reuse stale screenshots or prior scores as current proof.

## SEO: 100 points

| Component | Points | Minimum evidence |
|---|---:|---|
| Crawlability and indexability | 25 | Initial HTML, status codes, robots directives, canonical behavior, no accidental blocking |
| Semantic source content | 20 | Correct language, title hierarchy, landmarks, meaningful content and links without client execution |
| Metadata and URL signals | 20 | Unique titles and descriptions, canonical host, social metadata, stable and consolidated URLs |
| Internal discovery controls | 15 | Navigable internal links, robots.txt, sitemap coverage, redirect hygiene, orphan-page checks |
| Structured data and validation | 10 | Truthful visible-content-aligned schema, valid syntax, appropriate types |
| Mobile, security, and search errors | 10 | Responsive behavior, HTTPS assumptions, no severe console or search-facing errors |

## GEO: 100 points

| Component | Points | Minimum evidence |
|---|---:|---|
| Accessible people-first source content | 25 | Substantive initial HTML, unique editorial value, no hidden AI-only content |
| Provenance and editorial context | 20 | Authors or responsible entity when factual, source selection method, update context, ownership clarity |
| Entity and topic clarity | 20 | Unambiguous names, definitions, relationships, descriptive headings, consistent terminology |
| Structured semantic representation | 15 | Appropriate schema and HTML semantics aligned with visible facts |
| Citations, claims, and link quality | 10 | Important claims supported, outbound sources relevant and functional, dates or freshness noted where needed |
| Honest AI/search controls | 10 | No citation bait, prompt injection, deceptive markup, scaled unreviewed content, or unsupported GEO claims |

## AEO: 100 points

| Component | Points | Minimum evidence |
|---|---:|---|
| Direct-answer extractability | 25 | Concise answers or summaries near relevant headings, clear subject and predicate |
| Information hierarchy and intent coverage | 20 | Logical sections, user questions or tasks covered without keyword stuffing |
| Completeness and contextual precision | 20 | Answers include necessary qualifiers, scope, limitations, and next actions |
| Extractable structures | 15 | Accurate lists, steps, tables, definitions, or comparisons when useful |
| Answer-supporting semantics | 10 | Visible-content-aligned schema and machine-readable relationships without false FAQ claims |
| Language and accessible comprehension | 10 | Correct language declaration, readable wording, labels and structure usable by assistive technology |

## Accessibility: 100 points

| Component | Points | Minimum evidence |
|---|---:|---|
| Semantics, landmarks, and headings | 20 | Valid hierarchy, meaningful elements, skip path where needed |
| Keyboard, focus, and dialogs | 20 | Complete keyboard operation, visible focus, focus trap and restoration for modal UI |
| Forms, names, and live status | 15 | Labels, instructions, errors, accessible names, appropriate live regions |
| Contrast, scaling, and responsive access | 15 | Readable contrast, zoom and text resizing, no clipped essential content |
| Images, media, and motion | 15 | Useful alt text, captions or alternatives where applicable, reduced-motion support |
| Validation and regression evidence | 15 | HTML validation plus available accessibility tooling and manual critical-flow checks |

## Performance: 100 points

| Component | Points | Minimum evidence |
|---|---:|---|
| Largest-content and critical rendering path | 25 | Measured lab or field evidence, optimized blocking resources and primary media |
| Layout stability | 20 | Dimensions or reserved space, no meaningful unexpected shifts in tested flows |
| Interaction responsiveness and JS restraint | 20 | Progressive enhancement, deferred noncritical work, responsive tested interactions |
| Asset loading and optimization | 15 | Appropriate image formats and sizes, lazy loading where suitable, font and media discipline |
| Caching, compression, and network behavior | 10 | Appropriate cache policy, compression or platform equivalent, controlled request volume |
| Reproducible measurement and regressions | 10 | Documented environment, repeated measurement where practical, no critical functional regressions |

Do not label lab measurements as field Core Web Vitals. If INP or field data is unavailable, state the limitation and use an approved, clearly labeled interaction or lab proxy rather than inventing a value.

## Deployment readiness: 100 points

| Component | Points | Minimum evidence |
|---|---:|---|
| Reproducible build and output | 20 | Documented command, deterministic output, no missing runtime dependency |
| Routes, redirects, and error handling | 20 | Root and assets, legacy routes, redirects, trailing-slash policy, useful 404 behavior |
| Headers, cache, and security policy | 15 | Content types, caching, basic security headers, embedding and script policy where applicable |
| Secrets and repository hygiene | 15 | Ignore rules, no exposed secrets, environment separation, generated-output policy |
| Preview, rollback, and configuration | 15 | Platform configuration validated, backup and rollback instructions, preview path when deployed |
| Operational verification readiness | 15 | Health-check URLs, canonical host, robots and sitemap endpoints, ownership-file preservation where applicable |

## Severity guidance

- **Critical**: security exposure, destructive data risk, inaccessible primary content, production outage, accidental deindexing, or irrecoverable deployment defect.
- **High**: broken primary workflow, primary content absent from initial HTML, false structured data, invalid canonical consolidation, severe accessibility barrier, or build/deploy failure.
- **Medium**: material quality or discoverability weakness with a workable fallback.
- **Low**: polish, consistency, or marginal optimization issue.

## Project-specific additions

Add project-specific checks as explicit pass/fail gates or as detail beneath the closest common component. Examples include multilingual alternates, pagination, product inventory truth, course ownership claims, authenticated content, or embedded-media privacy. These checks can make the gate stricter, never easier.
