# Output Locations and Evidence Storage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every GAS-Optimizer run explicit, user-confirmed report and raw-evidence locations, with reproducible baseline/final evidence packages linked from the HTML report.

**Architecture:** Keep GAS-Optimizer declarative: the host agent resolves and confirms paths from `SKILL.md`, writes a run-scoped evidence package, and fills new evidence placeholders in the existing self-contained report template. Package validation enforces the instruction and template contract, while README documents the user-visible defaults and override flow.

**Tech Stack:** Agent Skills Markdown, self-contained HTML/CSS/JavaScript, Node.js package validation.

## Global Constraints

- The report default is `<documentation-directory>/gas-optimizer/analysis-plan.html`, falling back to `<project-root>/docs/gas-optimizer/analysis-plan.html`.
- Raw evidence defaults to `<project-root>/.gas-optimizer/evidence/<run-id>/`.
- Both resolved absolute paths are shown and confirmed before any measurement or directory creation.
- Overrides apply only to the current run; no persistent configuration file is introduced.
- Baseline evidence is never overwritten by final evidence.
- Secrets, tokens, cookies, passwords, and personal data are redacted before persistence and the redaction is recorded.
- Existing reports and evidence directories are never silently overwritten or merged.
- Do not create a git commit unless the user explicitly requests one.

---

### Task 1: Add package-contract checks

**Files:**
- Modify: `scripts/validate-package.js`

**Interfaces:**
- Consumes: canonical `SKILL.md`, report template, and README text.
- Produces: validation failures when output-path instructions or evidence placeholders are removed.

- [ ] **Step 1: Add assertions that initially fail**

Add checks for these skill markers:

```js
for (const marker of [
  'docs/gas-optimizer/analysis-plan.html',
  '.gas-optimizer/evidence/',
  'manifest.json',
  'baseline/',
  'final/'
]) {
  if (!skill.includes(marker)) throw new Error(`Missing output-storage instruction: ${marker}`);
}
```

Extend the report marker list with:

```js
'{{EVIDENCE_RUN_ID}}',
'{{EVIDENCE_ROOT}}',
'{{EVIDENCE_MANIFEST}}',
'{{FINDING_EVIDENCE_SOURCE}}'
```

Read `README.md` and require both default-path markers:

```js
const readme = fs.readFileSync(path.join(root, 'README.md'), 'utf8');
for (const marker of ['docs/gas-optimizer/analysis-plan.html', '.gas-optimizer/evidence/']) {
  if (!readme.includes(marker)) throw new Error(`README is missing output-location guidance: ${marker}`);
}
```

- [ ] **Step 2: Verify the new contract fails before implementation**

Run: `node scripts/validate-package.js`

Expected: FAIL with `Missing output-storage instruction` or `Missing report marker`.

### Task 2: Define runtime output selection and evidence lifecycle

**Files:**
- Modify: `skill/gas-optimizer/SKILL.md`

**Interfaces:**
- Consumes: target project root, detected documentation directories, optional paths from the user, host write capability.
- Produces: confirmed report file path, evidence run directory, immutable `manifest.json`, baseline/final raw artifacts.

- [ ] **Step 1: Add “Choose output locations” after scope establishment**

The section must define deterministic documentation-directory detection, the two defaults, absolute-path display, four override choices, run-only persistence, ambiguous-directory handling, external-path warning, and no writes before confirmation.

- [ ] **Step 2: Add evidence-package requirements to Phase 1**

Require:

```text
.gas-optimizer/evidence/<run-id>/
├── manifest.json
├── baseline/<category>/
└── final/<category>/
```

The manifest records run ID, project, report path, timestamps, phase, tool versions, redacted reproduction commands, environment, artifact-relative paths, status, checksum, and redaction notes.

- [ ] **Step 3: Integrate evidence updates into later phases**

Phase 4 stores fresh tool output under `final/`; Phase 5 updates artifact status/checksums and links report findings to raw sources. Missing raw output remains a documented limitation or `[blocked]`.

- [ ] **Step 4: Define collision and write-error behavior**

Existing GAS reports require an explicit continue/new/custom/cancel choice. Evidence run-ID collisions create a new ID; invalid or unwritable paths request another location without silent fallback.

### Task 3: Surface evidence provenance in the HTML report

**Files:**
- Modify: `skill/gas-optimizer/assets/analysis-plan-template.html`

**Interfaces:**
- Consumes: `EVIDENCE_RUN_ID`, `EVIDENCE_ROOT`, `EVIDENCE_MANIFEST`, and `FINDING_EVIDENCE_SOURCE`.
- Produces: visible evidence-package metadata and a raw-source reference for each finding.

- [ ] **Step 1: Add evidence package cards**

In the baseline evidence section, add three cards showing:

```html
<div class="testGrid">
  <div class="testCard"><b>실행 ID</b><span><code>{{EVIDENCE_RUN_ID}}</code></span></div>
  <div class="testCard"><b>측정 원본</b><span><code>{{EVIDENCE_ROOT}}</code></span></div>
  <div class="testCard"><b>Manifest</b><span><code>{{EVIDENCE_MANIFEST}}</code></span></div>
</div>
```

- [ ] **Step 2: Add per-finding provenance**

Add an “원본 참조” column to the findings table populated by `{{FINDING_EVIDENCE_SOURCE}}`.

- [ ] **Step 3: Preserve responsiveness and print behavior**

Use existing `testGrid`, `testCard`, and table overflow styles; do not add external assets or scripts.

### Task 4: Document defaults and override behavior

**Files:**
- Modify: `README.md`

**Interfaces:**
- Consumes: runtime behavior defined in `SKILL.md`.
- Produces: user-facing Korean guidance for default paths, confirmation choices, package structure, local-generated status, and sensitive-data redaction.

- [ ] **Step 1: Add an “산출물 저장 위치” section**

Document the report and evidence defaults, existing docs-directory preference, execution-only overrides, pre-measurement confirmation, baseline/final layout, and no automatic Git inclusion/exclusion.

- [ ] **Step 2: Correct the report dependency wording**

Describe the template as operating without external stylesheets or scripts; it contains inline JavaScript.

### Task 5: Verify the complete package

**Files:**
- Test: `scripts/validate-package.js`
- Test: `scripts/build-release.sh`

**Interfaces:**
- Consumes: all modified package files.
- Produces: passing structural validation and a buildable release archive.

- [ ] **Step 1: Run structural validation**

Run: `node scripts/validate-package.js`

Expected: JSON with `"status": "PASS"`.

- [ ] **Step 2: Build the release package**

Run: `bash scripts/build-release.sh`

Expected: ZIP and `SHA256SUMS.txt` generated under ignored `dist/`.

- [ ] **Step 3: Review the final diff**

Run: `git status --short && git diff --check && git diff --stat && git diff`

Expected: only the plan, skill instructions, report template, README, and validation contract are changed; `git diff --check` has no output.
