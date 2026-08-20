#!/usr/bin/env node
"use strict";

const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const version = fs.readFileSync(path.join(root, "VERSION"), "utf8").trim();
const dist = path.join(root, "dist");
const checksumFile = path.join(dist, "SHA256SUMS.txt");
const macosArchive = `gas-optimizer-v${version}-macos.tar.gz`;
const windowsArchive = `gas-optimizer-v${version}-windows.zip`;
const repo = "Deuk1718/GAS-Optimizer";
const releaseBase = `https://github.com/${repo}/releases/download/v${version}`;

if (!fs.existsSync(checksumFile)) {
  throw new Error(`Missing checksum file: ${checksumFile}`);
}

const checksums = {};
for (const line of fs.readFileSync(checksumFile, "utf8").split(/\r?\n/)) {
  const match = line.match(/^([a-fA-F0-9]{64})\s+(\S+)$/);
  if (!match) continue;
  checksums[path.basename(match[2])] = match[1].toLowerCase();
}

function requiredChecksum(name) {
  const value = checksums[name];
  if (!value) throw new Error(`SHA256SUMS.txt is missing ${name}`);
  return value;
}

const replacements = {
  VERSION: version,
  MACOS_URL: `${releaseBase}/${macosArchive}`,
  MACOS_SHA256: requiredChecksum(macosArchive),
  WINDOWS_URL: `${releaseBase}/${windowsArchive}`,
  WINDOWS_SHA256: requiredChecksum(windowsArchive),
  WINDOWS_SHA256_UPPER: requiredChecksum(windowsArchive).toUpperCase()
};

function render(templatePath, keys) {
  let contents = fs.readFileSync(templatePath, "utf8");
  for (const key of keys) {
    const token = `{{${key}}}`;
    if (!contents.includes(token)) {
      throw new Error(`${path.relative(root, templatePath)} is missing ${token}`);
    }
    contents = contents.split(token).join(replacements[key]);
  }
  if (contents.includes("{{")) {
    const leftover = contents.match(/\{\{[A-Z0-9_]+\}\}/g) || [];
    throw new Error(`${path.relative(root, templatePath)} still contains placeholders: ${leftover.join(", ")}`);
  }
  return contents;
}

const outputs = [
  {
    template: path.join(root, "packaging", "homebrew", "gas-optimizer.rb.in"),
    dest: path.join(dist, "packaging", "homebrew", "gas-optimizer.rb"),
    keys: ["VERSION", "MACOS_URL", "MACOS_SHA256"]
  },
  {
    template: path.join(root, "packaging", "scoop", "gas-optimizer.json.in"),
    dest: path.join(dist, "packaging", "scoop", "gas-optimizer.json"),
    keys: ["VERSION", "WINDOWS_URL", "WINDOWS_SHA256"]
  },
  {
    template: path.join(root, "packaging", "winget", "Deuk1718.GASOptimizer.yaml.in"),
    dest: path.join(dist, "packaging", "winget", "Deuk1718.GASOptimizer.yaml"),
    keys: ["VERSION"]
  },
  {
    template: path.join(root, "packaging", "winget", "Deuk1718.GASOptimizer.installer.yaml.in"),
    dest: path.join(dist, "packaging", "winget", "Deuk1718.GASOptimizer.installer.yaml"),
    keys: ["VERSION", "WINDOWS_URL", "WINDOWS_SHA256_UPPER"]
  },
  {
    template: path.join(root, "packaging", "winget", "Deuk1718.GASOptimizer.locale.en-US.yaml.in"),
    dest: path.join(dist, "packaging", "winget", "Deuk1718.GASOptimizer.locale.en-US.yaml"),
    keys: ["VERSION"]
  }
];

for (const output of outputs) {
  fs.mkdirSync(path.dirname(output.dest), { recursive: true });
  fs.writeFileSync(output.dest, render(output.template, output.keys));
}

console.log(JSON.stringify({
  version,
  macosUrl: replacements.MACOS_URL,
  windowsUrl: replacements.WINDOWS_URL,
  written: outputs.map(item => path.relative(root, item.dest))
}, null, 2));
