#!/usr/bin/env node
// Downloads the latest gh CLI binary for Linux amd64 to /tmp/gh.tar.gz
// Usage: node user-config/download-gh.js
// Then: tar -xzf /tmp/gh.tar.gz -C /tmp
//       cp /tmp/gh_*_linux_amd64/bin/gh ~/.local/bin/gh

const https = require("https");
const fs = require("fs");

const VERSION = "2.87.2";
const URL = `https://github.com/cli/cli/releases/download/v${VERSION}/gh_${VERSION}_linux_amd64.tar.gz`;
const DEST = "/tmp/gh.tar.gz";

function download(url, dest, cb) {
  https
    .get(url, (res) => {
      if (res.statusCode === 301 || res.statusCode === 302) {
        download(res.headers.location, dest, cb);
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

console.log(`Downloading gh v${VERSION}...`);
download(URL, DEST, () => console.log(`Done → ${DEST}`));
