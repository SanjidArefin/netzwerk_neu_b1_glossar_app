const fs = require("node:fs");
const path = require("node:path");

const root = path.resolve(__dirname, "..");
const source = path.join(root, "backend", "data", "glossary.json");
const destination = path.join(root, "mobile", "assets", "data", "glossary.json");

fs.mkdirSync(path.dirname(destination), { recursive: true });
fs.copyFileSync(source, destination);

console.log("Synced the canonical glossary data to the Android asset bundle.");
