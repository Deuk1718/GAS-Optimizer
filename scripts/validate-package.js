const fs = require('node:fs');
const path = require('node:path');

const root = path.resolve(__dirname, '..');
const skillRoot = path.join(root, 'skill', 'gas-optimizer');
const required = [
  'README.md',
  'LICENSE',
  'VERSION',
  'install.sh',
  'install.ps1',
  'uninstall.sh',
  'uninstall.ps1',
  'installers/install.sh',
  'installers/install.ps1',
  'installers/uninstall.sh',
  'installers/uninstall.ps1',
  'bin/gas-optimizer',
  'bin/gas-optimizer.ps1',
  'bin/gas-optimizer.cmd',
  'scripts/test-cli.sh',
  'scripts/test-cli.ps1',
  'scripts/test-scoop-channel.ps1',
  'scripts/generate-package-manifests.js',
  'scripts/publish-package-channels.sh',
  'packaging/homebrew/gas-optimizer.rb.in',
  'packaging/scoop/gas-optimizer.json.in',
  'packaging/winget/Deuk1718.GASOptimizer.yaml.in',
  'packaging/winget/Deuk1718.GASOptimizer.installer.yaml.in',
  'packaging/winget/Deuk1718.GASOptimizer.locale.en-US.yaml.in',
  'skill/gas-optimizer/SKILL.md',
  'skill/gas-optimizer/references/quality-rubric.md',
  'skill/gas-optimizer/references/capability-matrix.md',
  'skill/gas-optimizer/references/external-search-operations.md',
  'skill/gas-optimizer/references/search-engines/google.md',
  'skill/gas-optimizer/references/search-engines/bing.md',
  'skill/gas-optimizer/references/search-engines/naver.md',
  'skill/gas-optimizer/assets/analysis-plan-template.html'
];
for (const file of required) {
  if (!fs.existsSync(path.join(root, file))) throw new Error(`Missing required file: ${file}`);
}

for (const file of ['scripts/test-cli.sh', 'scripts/test-cli.ps1', 'scripts/publish-package-channels.sh', 'bin/gas-optimizer']) {
  const stats = fs.statSync(path.join(root, file));
  if (!stats.isFile()) throw new Error(`CLI smoke test must be a readable file: ${file}`);
  if ((file.endsWith('.sh') || file === 'bin/gas-optimizer') && (stats.mode & 0o111) === 0) {
    throw new Error(`POSIX executable bit is missing: ${file}`);
  }
}

const formulaTemplate = fs.readFileSync(path.join(root, 'packaging', 'homebrew', 'gas-optimizer.rb.in'), 'utf8');
for (const marker of ['{{VERSION}}', '{{MACOS_URL}}', '{{MACOS_SHA256}}', 'depends_on "jq"', 'bin.write_exec_script', 'gas-optimizer install', 'gas-optimizer sync']) {
  if (!formulaTemplate.includes(marker)) {
    throw new Error(`Homebrew Formula template is missing ${marker}`);
  }
}
const scoopTemplate = fs.readFileSync(path.join(root, 'packaging', 'scoop', 'gas-optimizer.json.in'), 'utf8');
for (const marker of ['{{VERSION}}', '{{WINDOWS_URL}}', '{{WINDOWS_SHA256}}', 'extract_dir', 'gas-optimizer.cmd', 'gas-optimizer install']) {
  if (!scoopTemplate.includes(marker)) {
    throw new Error(`Scoop manifest template is missing ${marker}`);
  }
}
const wingetInstaller = fs.readFileSync(path.join(root, 'packaging', 'winget', 'Deuk1718.GASOptimizer.installer.yaml.in'), 'utf8');
for (const marker of ['{{VERSION}}', '{{WINDOWS_URL}}', '{{WINDOWS_SHA256_UPPER}}', 'NestedInstallerType: portable', 'PortableCommandAlias: gas-optimizer']) {
  if (!wingetInstaller.includes(marker)) {
    throw new Error(`WinGet installer template is missing ${marker}`);
  }
}

const readme = fs.readFileSync(path.join(root, 'README.md'), 'utf8');
for (const command of ['install', 'status', 'sync', 'uninstall', 'version']) {
  const marker = `gas-optimizer ${command}`;
  if (!readme.includes(marker)) throw new Error(`README is missing stable CLI command marker: ${marker}`);
}
for (const marker of [
  '`$GAS_OPTIMIZER_HOME/installations.json`',
  '`schemaVersion` 1',
  '`installedVersion`',
  'Package managers install only launcher files and package metadata; they must not create, update, back up, or remove user or project skill directories.'
]) {
  if (!readme.includes(marker)) throw new Error(`README is missing stable CLI contract marker: ${marker}`);
}

const expectedStatuses = ['not-selected', 'ready', 'assisted', 'manual-required', 'blocked', 'completed', 'verified', 'failed'];
const expectedTransitions = [
  'not-selected->ready',
  'not-selected->blocked',
  'ready->assisted',
  'ready->manual-required',
  'ready->blocked',
  'ready->completed',
  'ready->verified',
  'ready->failed',
  'assisted->manual-required',
  'assisted->blocked',
  'assisted->completed',
  'assisted->verified',
  'assisted->failed',
  'manual-required->blocked',
  'manual-required->completed',
  'manual-required->verified',
  'manual-required->failed',
  'blocked->ready',
  'completed->blocked',
  'completed->verified',
  'completed->failed',
  'verified->blocked',
  'verified->failed',
  'failed->ready'
];
const expectedProviderActions = {
  google: ['property-registration', 'ownership-verification', 'sitemap-submission', 'post-submission-verification'],
  bing: ['site-registration', 'ownership-verification', 'search-console-import', 'sitemap-submission', 'indexnow-notification'],
  naver: ['site-registration', 'ownership-verification', 'sitemap-submission', 'rss-submission', 'indexnow-notification', 'manual-crawl-request']
};
const expectedBlockedRetryRequirements = {
  'selected-action': 'required',
  'blocker-removal': 'required',
  'read-only-preflight': 'repeated-successfully',
  'existing-approval': 'must-remain-valid',
  'missing-approval': 'record-pending-and-obtain-before-mutation',
  'prior-approval-for-preflight-blocked': 'not-required'
};

function canonicalLine(content, label, source) {
  const matches = [...content.matchAll(new RegExp(`^${label}: (.+)$`, 'gm'))];
  if (matches.length !== 1) throw new Error(`${source} must include exactly one ${label}: line`);
  return matches[0][1].trim();
}

function parseOrderedList(content, label, source) {
  const value = canonicalLine(content, label, source);
  const items = value.split(', ').filter(Boolean);
  if (items.length !== new Set(items).size) throw new Error(`${source} ${label} contains duplicates`);
  return items;
}

function assertOrderedList(actual, expected, source, label) {
  if (actual.join(',') !== expected.join(',')) {
    throw new Error(`${source} ${label} must be exactly: ${expected.join(', ')}`);
  }
}

function parseKeyValues(content, label, source) {
  const entries = canonicalLine(content, label, source).split('; ');
  const result = {};
  for (const entry of entries) {
    const separator = entry.indexOf('=');
    if (separator < 1 || separator === entry.length - 1) {
      throw new Error(`${source} ${label} has invalid entry: ${entry}`);
    }
    const key = entry.slice(0, separator);
    const value = entry.slice(separator + 1);
    if (Object.hasOwn(result, key)) throw new Error(`${source} ${label} repeats key: ${key}`);
    result[key] = value;
  }
  return result;
}

function assertKeyValues(actual, expected, source, label) {
  assertOrderedList(Object.keys(actual), Object.keys(expected), source, `${label} keys`);
  for (const [key, value] of Object.entries(expected)) {
    if (actual[key] !== value) throw new Error(`${source} ${label} ${key} must be ${value}`);
  }
}

const commonContract = fs.readFileSync(path.join(skillRoot, 'references', 'external-search-operations.md'), 'utf8');
assertOrderedList(
  parseOrderedList(commonContract, 'Execution levels', 'Common contract'),
  ['Level-1', 'Level-2', 'Level-3', 'Level-4'],
  'Common contract',
  'Execution levels'
);
assertOrderedList(
  parseOrderedList(commonContract, 'Gate names', 'Common contract'),
  ['quality-gate', 'external-operations-gate'],
  'Common contract',
  'Gate names'
);
const statuses = parseOrderedList(commonContract, 'Allowed statuses', 'Common contract').map(status => {
  const match = status.match(/^`([a-z-]+)`$/);
  if (!match) throw new Error(`Common contract has invalid status token: ${status}`);
  return match[1];
});
assertOrderedList(statuses, expectedStatuses, 'Common contract', 'Allowed statuses');

const transitions = parseOrderedList(commonContract, 'Allowed transitions', 'Common contract');
for (const transition of transitions) {
  const match = transition.match(/^([a-z-]+)->([a-z-]+)$/);
  if (!match) throw new Error(`Common contract has invalid transition: ${transition}`);
  for (const node of match.slice(1)) {
    if (!statuses.includes(node)) throw new Error(`Common contract transition uses unknown status: ${node}`);
  }
}
assertOrderedList(transitions, expectedTransitions, 'Common contract', 'Allowed transitions');
assertKeyValues(
  parseKeyValues(commonContract, 'Initial selection outcomes', 'Common contract'),
  {
    'preflight-success': 'not-selected->ready',
    'concrete-preflight-blocker-after-selection': 'not-selected->blocked',
    'blocked-without-selection': 'forbidden'
  },
  'Common contract',
  'Initial selection outcomes'
);
for (const disallowed of [
  /\b(?:may|can|must|should)\s+(?:move|transition)\s+(?:directly\s+)?to\s+`?blocked`?\s+(?:before|without)\s+(?:the user\s+)?select/i,
  /\bblocked without selection is (?:allowed|permitted|valid)\b/i,
  /\bunselected (?:provider\/action|action).{0,50}\bblocked\b/i
]) {
  if (disallowed.test(commonContract)) {
    throw new Error('Common contract must reject blocked status without prior provider/action selection');
  }
}
assertKeyValues(
  parseKeyValues(commonContract, 'Blocked retry requirements', 'Common contract'),
  expectedBlockedRetryRequirements,
  'Common contract',
  'Blocked retry requirements'
);
for (const disallowed of [
  /\bapproval is still valid for the provider\/action\b/i,
  /\bpreflight-blocked (?:provider\/actions?|actions?).{0,60}\b(?:requires?|must have|is required to have) (?:a )?(?:prior )?approval\b/i
]) {
  if (disallowed.test(commonContract)) {
    throw new Error('Common contract must apply approval conditionally on blocked retry');
  }
}
assertKeyValues(
  parseKeyValues(commonContract, 'Evidence gates', 'Common contract'),
  {
    completed: 'provider-acceptance',
    verified: 'independently-validated-provider-or-public-evidence'
  },
  'Common contract',
  'Evidence gates'
);
assertKeyValues(
  parseKeyValues(commonContract, 'Level 1 direct outcomes', 'Common contract'),
  {
    completed: 'ready->completed',
    verified: 'ready->verified',
    assisted: 'forbidden'
  },
  'Common contract',
  'Level 1 direct outcomes'
);
assertKeyValues(
  parseKeyValues(commonContract, 'Manual handoff outcomes', 'Common contract'),
  {
    default: 'manual-required',
    completed: 'requires-provider-acceptance',
    verified: 'requires-independent-validation'
  },
  'Common contract',
  'Manual handoff outcomes'
);

const skill = fs.readFileSync(path.join(skillRoot, 'SKILL.md'), 'utf8');
const frontmatter = skill.match(/^---\n([\s\S]*?)\n---/);
if (!frontmatter) throw new Error('SKILL.md frontmatter is missing');
const frontmatterKeys = [...frontmatter[1].matchAll(/^([a-z][a-z0-9-]*):/gm)].map(match => match[1]);
if (frontmatterKeys.join(',') !== 'name,description') throw new Error(`Canonical frontmatter must contain only name and description, found: ${frontmatterKeys.join(', ')}`);
if (!frontmatter[1].includes('name: "gas-optimizer"')) throw new Error('Invalid skill name');

for (const marker of [
  'docs/gas-optimizer/analysis-plan.html',
  '.gas-optimizer/evidence/',
  'manifest.json',
  'baseline/',
  'final/'
]) {
  if (!skill.includes(marker)) throw new Error(`Missing output-storage instruction: ${marker}`);
}
const skillRelativeOverrideMarker = 'Relative report and evidence overrides resolve against `<project-root>`, are normalized, then displayed as absolute paths and classified as project-internal or external before confirmation or warnings.';
const skillRelativeOverrideMatches = skill.match(new RegExp(skillRelativeOverrideMarker.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'g')) || [];
if (skillRelativeOverrideMatches.length !== 1) throw new Error(`SKILL.md must include unique relative override resolution marker: ${skillRelativeOverrideMarker}`);

const rubric = fs.readFileSync(path.join(skillRoot, 'references', 'quality-rubric.md'), 'utf8');
for (const name of ['SEO', 'GEO', 'AEO', 'Accessibility', 'Performance', 'Deployment readiness']) {
  const marker = `## ${name}: 100 points`;
  const start = rubric.indexOf(marker);
  if (start < 0) throw new Error(`Missing rubric section: ${name}`);
  const rest = rubric.slice(start + marker.length);
  const next = rest.indexOf('\n## ');
  const section = next < 0 ? rest : rest.slice(0, next);
  const points = [...section.matchAll(/^\|[^\n|]+\|\s*(\d+)\s*\|/gm)].map(match => Number(match[1]));
  const sum = points.reduce((total, value) => total + value, 0);
  if (sum !== 100) throw new Error(`${name} totals ${sum}, not 100`);
}

const capability = fs.readFileSync(path.join(skillRoot, 'references', 'capability-matrix.md'), 'utf8');
for (const host of ['Aside', 'Claude Code', 'Codex', 'Cursor', 'GitHub Copilot']) {
  if (!capability.includes(host)) throw new Error(`Capability matrix is missing ${host}`);
}

const playbookSpecs = [
  {
    slug: 'google',
    name: 'Google Search Console',
    actions: expectedProviderActions.google,
    sources: [
      'https://developers.google.com/search/docs/crawling-indexing/sitemaps/build-sitemap',
      'https://developers.google.com/webmaster-tools/v1/quickstart/quickstart-python'
    ]
  },
  {
    slug: 'bing',
    name: 'Bing Webmaster Tools',
    actions: expectedProviderActions.bing,
    sources: [
      'https://www.bing.com/webmasters/help/getting-started-checklist-66a806de',
      'https://www.bing.com/webmasters/help/add-and-verify-site-12184f8b',
      'https://www.indexnow.org/documentation'
    ]
  },
  {
    slug: 'naver',
    name: 'Naver Search Advisor',
    actions: expectedProviderActions.naver,
    sources: [
      'https://searchadvisor.naver.com/guide/seo-basic-intro',
      'https://searchadvisor.naver.com/guide/request-feed',
      'https://searchadvisor.naver.com/guide/indexnow-faq',
      'https://searchadvisor.naver.com/guide/request-crawl'
    ]
  }
];
const sharedPlaybookHeadings = [
  '## Scope/actions',
  '## Prerequisites',
  '## Read-only preflight',
  '## Level 1',
  '## Level 2',
  '## Level 3 manual handoff',
  '## Level 4 blockers',
  '## Evidence/verification',
  '## Official sources'
];

function sectionsFor(content, slug) {
  const sections = {};
  const starts = [];
  for (const heading of sharedPlaybookHeadings) {
    const escapedHeading = heading.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const matches = [...content.matchAll(new RegExp(`^${escapedHeading}$`, 'gm'))];
    if (matches.length !== 1) {
      throw new Error(`${slug} playbook must include heading exactly once: ${heading}`);
    }
    starts.push({ heading, index: matches[0].index });
  }
  for (let index = 1; index < starts.length; index += 1) {
    if (starts[index].index <= starts[index - 1].index) {
      throw new Error(`${slug} playbook headings must be in canonical order: ${sharedPlaybookHeadings.join(' -> ')}`);
    }
  }
  for (let index = 0; index < starts.length; index += 1) {
    const { heading, index: start } = starts[index];
    const end = index + 1 < starts.length ? starts[index + 1].index : content.length;
    sections[heading] = content.slice(start + heading.length, end);
  }
  return sections;
}

function countOccurrences(content, marker) {
  return content.split(marker).length - 1;
}

function htmlSection(content, id) {
  const startMatch = new RegExp(`<section\\b[^>]*\\bid="${id}"[^>]*>`).exec(content);
  if (!startMatch) throw new Error(`Missing report section: ${id}`);
  const start = startMatch.index;
  const nextMatch = /\n<section\b/g;
  nextMatch.lastIndex = start + startMatch[0].length;
  const endMatch = nextMatch.exec(content);
  return content.slice(start, endMatch ? endMatch.index : content.length);
}

function htmlCommentBlock(content, startMarker, endMarker) {
  const starts = [...content.matchAll(new RegExp(`<!-- ${startMarker} -->`, 'g'))];
  const ends = [...content.matchAll(new RegExp(`<!-- ${endMarker} -->`, 'g'))];
  if (starts.length !== 1 || ends.length !== 1 || starts[0].index >= ends[0].index) {
    throw new Error(`Report must include one ordered ${startMarker}/${endMarker} comment pair`);
  }
  return content.slice(starts[0].index + starts[0][0].length, ends[0].index);
}

function markdownSectionBetween(content, startHeading, endHeading) {
  const headingPattern = heading => new RegExp(`^${heading.replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}$`, 'gm');
  const starts = [...content.matchAll(headingPattern(startHeading))];
  const ends = [...content.matchAll(headingPattern(endHeading))];
  if (starts.length !== 1) throw new Error(`README must include heading exactly once: ${startHeading}`);
  if (ends.length !== 1) throw new Error(`README must include heading exactly once: ${endHeading}`);
  if (starts[0].index >= ends[0].index) {
    throw new Error(`README heading order must be: ${startHeading} before ${endHeading}`);
  }
  return content.slice(starts[0].index, ends[0].index);
}

const coveredActionsByProvider = {};
for (const playbook of playbookSpecs) {
  const file = path.join(skillRoot, 'references', 'search-engines', `${playbook.slug}.md`);
  const content = fs.readFileSync(file, 'utf8');
  if (!content.includes(playbook.name)) throw new Error(`${playbook.slug} playbook is missing provider name: ${playbook.name}`);
  const sections = sectionsFor(content, playbook.slug);
  const coveredActions = parseOrderedList(content, 'Covered actions', `${playbook.slug} playbook`);
  for (const action of coveredActions) {
    if (!/^[a-z]+(?:-[a-z0-9]+)*$/.test(action)) {
      throw new Error(`${playbook.slug} playbook has invalid action token: ${action}`);
    }
  }
  assertOrderedList(coveredActions, playbook.actions, `${playbook.slug} playbook`, 'Covered actions');
  coveredActionsByProvider[playbook.slug] = coveredActions;
  for (const level of ['## Level 1', '## Level 2', '## Level 3 manual handoff', '## Level 4 blockers']) {
    const levelActions = parseOrderedList(sections[level], 'Level actions', `${playbook.slug} ${level}`);
    assertOrderedList(levelActions, playbook.actions, `${playbook.slug} ${level}`, 'Level actions');
  }
  const level4 = sections['## Level 4 blockers'];
  assertKeyValues(
    parseKeyValues(level4, 'Blocked retry requirements', `${playbook.slug} Level 4 blockers`),
    expectedBlockedRetryRequirements,
    `${playbook.slug} Level 4 blockers`,
    'Blocked retry requirements'
  );
  for (const disallowed of [
    /\bapproval is still valid or refreshed\b/i,
    /\bpreflight-blocked (?:provider\/actions?|actions?).{0,60}\b(?:requires?|must have|is required to have) (?:a )?(?:prior )?approval\b/i
  ]) {
    if (disallowed.test(level4)) {
      throw new Error(`${playbook.slug} Level 4 retry must apply approval conditionally`);
    }
  }
  if (['bing', 'naver'].includes(playbook.slug)) {
    const expectedIndexNowScope = {
      'root-key-file': 'host-wide',
      'non-root-keyLocation': 'urlList-under-key-directory'
    };
    for (const sectionName of [
      '## Prerequisites',
      '## Read-only preflight',
      '## Level 3 manual handoff',
      '## Level 4 blockers',
      '## Evidence/verification'
    ]) {
      assertKeyValues(
        parseKeyValues(sections[sectionName], 'IndexNow path scope', `${playbook.slug} ${sectionName}`),
        expectedIndexNowScope,
        `${playbook.slug} ${sectionName}`,
        'IndexNow path scope'
      );
    }
  }
  if (playbook.slug === 'naver') {
    assertKeyValues(
      parseKeyValues(sections['## Prerequisites'], 'Feed constraints', 'naver Prerequisites'),
      {
        'sitemap-size': '<10-MB',
        'sitemap-url-count': '<=50,000',
        'rss-size': '<10-MB',
        'rss-item-count': '>=1',
        'rss-full-current-content': 'recommendation-unless-observed-provider-rejection'
      },
      'naver Prerequisites',
      'Feed constraints'
    );
  }
  for (const source of playbook.sources) {
    if (!content.includes(source)) throw new Error(`${playbook.slug} playbook is missing official source: ${source}`);
  }
}

const advertisedActionMatches = [...skill.matchAll(/^Advertised provider actions \((google|bing|naver)\): (.+)$/gm)];
if (advertisedActionMatches.length !== Object.keys(expectedProviderActions).length) {
  throw new Error('SKILL.md must advertise exactly one canonical action line for each provider');
}
for (const [provider, expectedActions] of Object.entries(expectedProviderActions)) {
  const matches = advertisedActionMatches.filter(match => match[1] === provider);
  if (matches.length !== 1) throw new Error(`SKILL.md must advertise ${provider} actions exactly once`);
  const advertised = matches[0][2].split(', ');
  assertOrderedList(advertised, expectedActions, 'SKILL.md', `${provider} advertised actions`);
  assertOrderedList(advertised, coveredActionsByProvider[provider], 'SKILL.md', `${provider} playbook coverage`);
}

const report = fs.readFileSync(path.join(skillRoot, 'assets', 'analysis-plan-template.html'), 'utf8');
const reportGlobalMarkers = [
  '{{SEO_SCORE}}',
  '{{GEO_SCORE}}',
  '{{AEO_SCORE}}',
  '{{ANALYSIS_APPROVAL}}',
  '{{EXTERNAL_APPROVALS}}',
  '{{EVIDENCE_RUN_ID}}',
  '{{EVIDENCE_ROOT}}',
  '{{EVIDENCE_MANIFEST}}',
  '{{FINDING_EVIDENCE_SOURCE}}'
];
for (const marker of reportGlobalMarkers) {
  if (!report.includes(marker)) throw new Error(`Missing report marker: ${marker}`);
}
const extensionsSection = htmlSection(report, 'extensions');
const qualityGateSection = htmlSection(report, 'quality-gate');
const genericExtensionCard = '<article class="extension"><h3>{{EXTENSION_NAME}}</h3><p>{{EXTENSION_DESCRIPTION}}</p><dl><dt>상태</dt><dd>{{EXTENSION_STATUS}}</dd><dt>외부 영향</dt><dd>{{EXTENSION_IMPACT}}</dd><dt>되돌리기</dt><dd>{{EXTENSION_ROLLBACK}}</dd></dl></article><!-- 선택 기능마다 .extension을 복제 -->';
if (countOccurrences(extensionsSection, genericExtensionCard) !== 1) {
  throw new Error('Generic extension card must retain its original placeholders and markup unchanged');
}
const genericExtensionMarkers = [
  '{{EXTENSION_NAME}}',
  '{{EXTENSION_DESCRIPTION}}',
  '{{EXTENSION_STATUS}}',
  '{{EXTENSION_IMPACT}}',
  '{{EXTENSION_ROLLBACK}}'
];
for (const marker of genericExtensionMarkers) {
  if (countOccurrences(genericExtensionCard, marker) !== 1) {
    throw new Error(`Generic extension card marker must occur exactly once: ${marker}`);
  }
}
const externalCard = htmlCommentBlock(report, 'EXTERNAL-OPERATION-CARD:START', 'EXTERNAL-OPERATION-CARD:END');
const externalCardMarkers = [
  '{{EXTERNAL_PROVIDER}}',
  '{{EXTERNAL_ACTION}}',
  '{{EXTERNAL_DESCRIPTION}}',
  '{{EXTERNAL_EXECUTION_LEVEL}}',
  '{{EXTERNAL_PREREQUISITES}}',
  '{{EXTERNAL_STATUS}}',
  '{{EXTERNAL_BLOCKER}}',
  '{{EXTERNAL_EVIDENCE}}',
  '{{EXTERNAL_HANDOFF}}',
  '{{EXTERNAL_RETRY}}',
  '{{EXTERNAL_IMPACT}}',
  '{{EXTERNAL_ROLLBACK}}'
];
for (const marker of externalCardMarkers) {
  const cardCount = countOccurrences(externalCard, marker);
  const reportCount = countOccurrences(report, marker);
  if (cardCount !== 1 || reportCount !== 1) {
    throw new Error(`External operation marker must occur exactly once inside its card: ${marker}`);
  }
  if (qualityGateSection.includes(marker)) {
    throw new Error(`Report marker must not be mixed into #quality-gate: ${marker}`);
  }
}
for (const label of ['제공자', '작업', '실행 수준', '필수 조건', '상태', '차단 사유', '증거', '수동 인계', '재시도', '외부 영향', '되돌리기']) {
  const marker = `<dt>${label}</dt>`;
  if (countOccurrences(externalCard, marker) !== 1) {
    throw new Error(`External operation card label must occur exactly once: ${marker}`);
  }
}
for (const marker of ['{{EXTERNAL_OPERATIONS_GATE}}', '{{EXTERNAL_APPROVALS}}']) {
  if (countOccurrences(extensionsSection, marker) !== 1 || countOccurrences(report, marker) !== 1) {
    throw new Error(`External extension marker must occur exactly once inside #extensions: ${marker}`);
  }
  if (qualityGateSection.includes(marker)) throw new Error(`Report marker must not be mixed into #quality-gate: ${marker}`);
}
for (const section of ['summary', 'final-results', 'scores', 'evidence', 'rubric', 'issues', 'priorities', 'guardrails', 'quality-gate', 'plan', 'validation', 'approval', 'extensions', 'sources']) {
  if (!report.includes(`id="${section}"`)) throw new Error(`Missing report section: ${section}`);
}
for (const feature of ['prefers-reduced-motion', 'focus-visible', 'aria-live="polite"', '@media print', 'data-sev', 'data-cat', 'data-status']) {
  if (!report.includes(feature)) throw new Error(`Missing report feature: ${feature}`);
}
for (const selector of [
  '.extension dl,.externalOperation dl',
  '.extension dd,.externalOperation dd',
  '.extension dd.wrap,.externalOperation dd.wrap',
  '.extension h3,.externalOperation h3',
  '.extension,.externalOperation',
  '.externalGate{background:#fff;color:#111}',
  '.externalGate b,.externalOperation dd{color:#111}'
]) {
  if (!report.includes(selector)) throw new Error(`Missing shared report style: ${selector}`);
}
const printContrastRule = '.externalGate{background:#fff;color:#111}';
if (!report.includes(printContrastRule)) {
  throw new Error(`Missing report print contrast rule: ${printContrastRule}`);
}
for (const match of report.matchAll(/<script>([\s\S]*?)<\/script>/g)) new Function(match[1]);

for (const marker of ['docs/gas-optimizer/analysis-plan.html', '.gas-optimizer/evidence/']) {
  if (!readme.includes(marker)) throw new Error(`README is missing output-location guidance: ${marker}`);
}
const readmeRelativePathMarker = '상대 사용자 지정 경로는 `<project-root>`를 기준으로 해석합니다.';
if (!readme.includes(readmeRelativePathMarker)) throw new Error(`README is missing relative custom path guidance: ${readmeRelativePathMarker}`);
const readmeExtensionsSection = markdownSectionBetween(readme, '## 선택형 확장 기능', '## 공식 지원 환경');
const readmeExtensionMarkers = [
  '동일한 경험을 제공한다는 말은 자동화 가능성이 항상 같다는 뜻이 아닙니다',
  'same preflight, execution-level decision, status vocabulary, evidence standard, manual handoff',
  '**Level 1 · official API/MCP**',
  '**Level 2 · authenticated browser**',
  '**Level 3 · verifiable handoff**',
  '**Level 4 · blocked**',
  'credentials, recovery, 2FA secrets are never requested or stored',
  '`quality-gate`는 SEO, GEO, AEO, 접근성, 성능, 배포 준비도 6개 핵심 점수',
  '외부 capability 때문에 core 95 scores는 절대 오르거나 내려가지 않습니다',
  '`external-operations-gate`는 선택형 외부 작업의 별도 결과',
  '가이드만 제공한 상태는 완료가 아닙니다',
  'manual handoff alone remains `manual-required` and is not complete',
  'provider/action-specific approval',
  'Google',
  'Bing',
  'Naver'
];
for (const marker of readmeExtensionMarkers) {
  if (!readmeExtensionsSection.includes(marker)) {
    throw new Error(`README optional extensions section is missing guidance: ${marker}`);
  }
}

console.log(JSON.stringify({
  version: fs.readFileSync(path.join(root, 'VERSION'), 'utf8').trim(),
  requiredFiles: required.length,
  rubricDomains: 6,
  canonicalFrontmatter: frontmatterKeys,
  status: 'PASS'
}, null, 2));
