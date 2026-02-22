#!/usr/bin/env node
// Downloads the gh CLI binary for Linux amd64 to /tmp/gh.tar.gz
// Verifies SHA256 checksum after download.
// Usage: node user-config/download-gh.js
// Then: tar -xzf /tmp/gh.tar.gz -C /tmp
//       cp /tmp/gh_*_linux_amd64/bin/gh ~/.local/bin/gh

const https = require("https");
const fs = require("fs");
const crypto = require("crypto");

const VERSION = "2.87.2";
const URL = `https://github.com/cli/cli/releases/download/v${VERSION}/gh_${VERSION}_linux_amd64.tar.gz`;
const CHECKSUMS_URL = `https://github.com/cli/cli/releases/download/v${VERSION}/gh_${VERSION}_checksums.txt`;
const DEST = "/tmp/gh.tar.gz";
const MAX_REDIRECTS = 5;

function download(url, dest, cb, redirects) {
  if (redirects === undefined) redirects = 0;
  if (redirects > MAX_REDIRECTS) {
    console.error("Too many redirects");
    process.exit(1);
  }
  https
    .get(url, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        download(res.headers.location, dest, cb, redirects + 1);
      } else if (res.statusCode !== 200) {
        console.error(`HTTP ${res.statusCode} for ${url}`);
        process.exit(1);
      } else {
        const file = fs.createWriteStream(dest);
        res.pipe(file).on("finish", cb);
      }
    })
    .on("error", (err) => {
      console.error(err.message);
      process.exit(1);
    });
}

function fetchText(url, cb, redirects) {
  if (redirects === undefined) redirects = 0;
  if (redirects > MAX_REDIRECTS) {
    console.error("Too many redirects");
    process.exit(1);
  }
  https
    .get(url, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        fetchText(res.headers.location, cb, redirects + 1);
      } else {
        let data = "";
        res.on("data", (chunk) => (data += chunk));
        res.on("end", () => cb(data));
      }
    })
    .on("error", (err) => {
      console.error(err.message);
      process.exit(1);
    });
}

function verifySha256(filePath, expectedHash) {
  const hash = crypto.createHash("sha256");
  const stream = fs.createReadStream(filePath);
  stream.on("data", (chunk) => hash.update(chunk));
  stream.on("end", () => {
    const actual = hash.digest("hex");
    if (actual !== expectedHash) {
      console.error(
        `Checksum mismatch!\n  Expected: ${expectedHash}\n  Actual:   ${actual}`,
      );
      fs.unlinkSync(filePath);
      process.exit(1);
    }
    console.log(`Checksum verified: ${actual.slice(0, 16)}...`);
  });
}

console.log(`Downloading gh v${VERSION}...`);
download(URL, DEST, () => {
  console.log(`Downloaded → ${DEST}`);
  console.log("Verifying checksum...");
  const tarballName = `gh_${VERSION}_linux_amd64.tar.gz`;
  fetchText(CHECKSUMS_URL, (checksums) => {
    const line = checksums.split("\n").find((l) => l.includes(tarballName));
    if (!line) {
      console.error(`Checksum not found for ${tarballName}`);
      process.exit(1);
    }
    const expectedHash = line.split(/\s+/)[0];
    verifySha256(DEST, expectedHash);
  });
});
