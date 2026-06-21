// convert-synonyms.js
// Reads Left's synonyms.js and writes data/plugins/synonyms_db.lua
//
// Usage: node convert-synonyms.js

const path = require('path')
const fs = require('fs')

const srcFile = process.argv[2] || path.join(
  process.env.HOME,
  'Documents/github/Left/desktop/sources/scripts/synonyms.js'
)
const dstFile = process.argv[3] || path.join(
  __dirname,
  '..', 'data', 'plugins', 'synonyms_db.lua'
)

// Patch the module.exports to be a plain assignment so require() works
let src = fs.readFileSync(srcFile, 'utf8')
src = src.replace('module.exports = SYN_DB', '')
src = src.replace("'use strict'", '')

// Evaluate the JS object
const SYN_DB = eval(src + '; SYN_DB')

// Convert to Lua table
const lines = []
lines.push('-- Auto-generated from Left synonyms.js')
lines.push('-- Do not edit manually. Run convert-synonyms.js to regenerate.')
lines.push('')
lines.push('local db = {}')
lines.push('')

const keys = Object.keys(SYN_DB).sort()

for (const word of keys) {
  const syns = SYN_DB[word]
  // Each entry: db["word"] = {"syn1", "syn2", ...}
  const quotedSyns = syns.map(s => JSON.stringify(s)).join(', ')
  lines.push(`db[${JSON.stringify(word)}] = {${quotedSyns}}`)
}

lines.push('')
lines.push('return db')

fs.writeFileSync(dstFile, lines.join('\n') + '\n')
console.log(`Wrote ${keys.length} entries to ${dstFile}`)
