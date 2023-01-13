const fs = require("fs");
const child_process = require("child_process");

let sourceFile = process.argv[2];

let packages = JSON.parse(fs.readFileSync(sourceFile, "utf8"));

let changed = false;
for ([pkgName, pkg] of Object.entries(packages)) {
  if (pkg.sha256 === "") {
    console.log(`Package ${pkgName} has no sha256. Fetching...`);

    const hash = (() => {
      // sorry not sorry. it works xD
      const base = child_process.execSync(
        `bash -c 'cs fetch ${pkg.artifact}:${pkg.version} > deps\n` +
          "rm -rf .tmp && mkdir -p .tmp/share/java\n" +
          "cp $(< deps) .tmp/share/java/\n" +
          "nix hash path ./.tmp' && rm -rf .tmp deps"
      );

      return (base.toString ? base.toString() : base).trim();
    })();

    console.log(`Package ${pkgName} now has sha256 ${hash}`);
    pkg.sha256 = hash;
    changed = true;
  }
}

if (changed)
  fs.writeFileSync(sourceFile, JSON.stringify(packages, null, 2) + "\n");
