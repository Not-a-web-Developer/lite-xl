# WORKLOG.md — Left XL

### [2026-06-22 02:55] Project initiated
- **Action**: Forked lite-xl, created `~/Documents/github/left/left-xl/`,
  set up worktree for MVP planning.
- **Action**: Changed USERDIR from `~/.config/lite-xl` to `~/.config/left-xl`
  to prevent collision with daily lite-xl.
- **Action**: Renamed project in meson.build and window title to "Left XL".
- **Action**: Wrote IMPLEMENTATION.md (7-phase MVP plan) and AGENTS.md.
- **Action**: Copied UX.md from Left repo as canonical spec.

### [2026-06-22 03:30] Planning complete
- **Decisions**: lite-xl base (Lua 5.4), plugin-first architecture, 7 MVP phases.
- **Deferred**: Reader mode, theme system, frameless, operator mode, open-URL.
- **Parallel work**: Phases 5 (fonts), 3 (insert mode), 2 (synonyms) independent.
- **Next**: Synonyms DB conversion script.

### [2026-06-22 03:45] Synonym DB conversion
- **Action**: Wrote `scripts/convert-synonyms.js` — reads Left's `synonyms.js`,
  parses the JS object via `eval()`, writes Lua table to `data/plugins/synonyms_db.lua`.
- **Result**: 4,023 entries, 528KB, ~4,030 lines. Validates correctly under Lua 5.4.
- **Note**: The original JS file is 48,677 lines because each synonym array is
  pretty-printed across multiple lines.  The Lua output is compact (one entry per line).

### [2026-06-22 04:15] Phase 5 & 3 complete — Fonts + Insert mode
- **Action**: Wrote `data/plugins/fonts.lua` — 3 fonts, cycling, size control,
  persistence to `config.plugins.fonts`. Copied Left's bundled fonts
  (Input Mono, Zilla Slab, Inter UI) to `data/fonts/`.
- **Action**: Wrote `data/plugins/insert.lua` — 8 insert shortcuts with
  smart prefix insertion (single-line start, multi-line per-line, mid-line
  at-start). Command predicates ensure shortcuts only fire in insert mode.
  Date format: DD-Mon-YYYY per Left spec.
- **Key conflict resolved**: `ctrl+/` falls through to `doc:toggle-line-comments`
  when not in insert mode. `ctrl+-` is unambiguous.
