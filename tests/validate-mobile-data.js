const crypto = require("node:crypto");
const fs = require("node:fs");
const path = require("node:path");
const { getGlossary } = require("../backend/glossary-service");

const root = path.resolve(__dirname, "..");
const canonicalPath = path.join(root, "backend", "data", "glossary.json");
const mobilePath = path.join(root, "mobile", "assets", "data", "glossary.json");
const canonical = fs.readFileSync(canonicalPath);
const mobile = fs.readFileSync(mobilePath);

if (!canonical.equals(mobile)) {
  throw new Error("The Android glossary asset does not match backend/data/glossary.json.");
}

const glossary = getGlossary();
const hash = crypto.createHash("sha256").update(mobile).digest("hex");

console.log(
  `Validated Android data: ${glossary.totalEntries} entries across ${glossary.chapters.length} chapters (${hash}).`,
);
