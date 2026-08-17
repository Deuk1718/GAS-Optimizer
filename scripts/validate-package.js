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
  'skill/gas-optimizer/SKILL.md',
  'skill/gas-optimizer/references/quality-rubric.md',
  'skill/gas-optimizer/references/capability-matrix.md',
  'skill/gas-optimizer/assets/analysis-plan-template.html'
];
for (const file of required) {
  if (!fs.existsSync(path.join(root, file))) throw new Error(`Missing required file: ${file}`);
}

const skill = fs.readFileSync(path.join(skillRoot, 'SKILL.md'), 'utf8');
const frontmatter = skill.match(/^---\n([\s\S]*?)\n---/);
if (!frontmatter) throw new Error('SKILL.md frontmatter is missing');
const frontmatterKeys = [...frontmatter[1].matchAll(/^([a-z][a-z0-9-]*):/gm)].map(match => match[1]);
if (frontmatterKeys.join(',') !== 'name,description') throw new Error(`Canonical frontmatter must contain only name and description, found: ${frontmatterKeys.join(', ')}`);
if (!frontmatter[1].includes('name: "gas-optimizer"')) throw new Error('Invalid skill name');

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

const report = fs.readFileSync(path.join(skillRoot, 'assets', 'analysis-plan-template.html'), 'utf8');
for (const marker of ['{{SEO_SCORE}}', '{{GEO_SCORE}}', '{{AEO_SCORE}}', '{{ANALYSIS_APPROVAL}}', '{{EXTERNAL_APPROVALS}}']) {
  if (!report.includes(marker)) throw new Error(`Missing report marker: ${marker}`);
}
for (const section of ['summary', 'final-results', 'scores', 'evidence', 'rubric', 'issues', 'priorities', 'guardrails', 'quality-gate', 'plan', 'validation', 'approval', 'extensions', 'sources']) {
  if (!report.includes(`id="${section}"`)) throw new Error(`Missing report section: ${section}`);
}
for (const feature of ['prefers-reduced-motion', 'focus-visible', 'aria-live="polite"', '@media print', 'data-sev', 'data-cat', 'data-status']) {
  if (!report.includes(feature)) throw new Error(`Missing report feature: ${feature}`);
}
for (const match of report.matchAll(/<script>([\s\S]*?)<\/script>/g)) new Function(match[1]);

console.log(JSON.stringify({
  version: fs.readFileSync(path.join(root, 'VERSION'), 'utf8').trim(),
  requiredFiles: required.length,
  rubricDomains: 6,
  canonicalFrontmatter: frontmatterKeys,
  status: 'PASS'
}, null, 2));
