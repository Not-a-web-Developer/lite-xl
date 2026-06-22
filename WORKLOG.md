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
- **Action**: Wrote `scripts/convert-synonyms.js`.
- **Result**: 4,023 entries, 528KB Lua file. Validates under Lua 5.4.

### [2026-06-22 04:15] Phase 5 & 3 — Fonts + Insert mode
- **Action**: Wrote `data/plugins/fonts.lua` — 3-font cycling, size control, persistence.
- **Action**: Wrote `data/plugins/insert.lua` — 8 insert shortcuts with smart prefixing.
- **Key conflicts**: `ctrl+/` falls through to `doc:toggle-line-comments` outside insert mode.

### [2026-06-22 04:30] Phase 2 — Synonyms + Autocomplete
- **Action**: Wrote `data/plugins/synonyms.lua` — Tab autocomplete, Shift+Tab cycling,
  shift-release application, caps preservation, plural handling.
- **Action**: Disabled treeview by default.

### [2026-06-22 04:35–05:30] Debugging sprint — 20+ fix commits
**Font rendering:**
- Left's .ttf fonts (Input Mono, Inter UI, Zilla Slab) look terrible with freetype.
  Switched to lite-xl fonts (JetBrains Mono, Fira Sans). Kept Zilla Slab for serif.
- Reverted to lite-xl font defaults (subpixel, 15px), then fixed to grayscale+slight
  per Ash's daily lite-xl settings.

**Plugin config metatable trap:**
- `config.plugins.autocomplete = config.plugins.autocomplete or false` didn't work.
  The metatable `__index` auto-creates truthy `{enabled=true, config={}}` on access.
  Must use direct `= false` assignment. Also disabled `scale` plugin (ctrl+- conflict).

**Lua strict mode ordering bugs:**
- `strict.lua` catches undeclared globals. Three instances of locals declared after
  functions that referenced them: `last_cursor_word`, `reset_synonym_state`, `col`.
  All fixed by moving declarations before function definitions.

**Synonym cycling not firing:**
- `shift+tab` keymap binding doesn't work on SDL3/Wayland/niri. Solution: manually
  detect "tab while shift held" in `keymap.on_key_pressed` hook. Also bind `backtab`.
- Tab binding was appended after `doc:indent` which always returns true. Fixed with
  `keymap.add(..., true)` overwrite.
- 150ms polling thread was resetting `synonym_index` on every tick in
  `update_synonym_state()`. Removed the reset — only `reset_synonym_state()` does it,
  and only on word change.
- Shift key repeat spam: SDL auto-repeats shift+tab, flooding 48+ cycle events per
  second. Added `shift_tab_handled` flag to only cycle once per shift press.

**Insert mode bugs:**
- `insert_line()` had undeclared global `col` → strict mode error. Fixed with `local`.
- `ctrl+-` list shortcut blocked by `scale` plugin. Disabled scale.

**What's verified working:**
- Font cycling via Ctrl+Shift+, / .
- Insert mode: Ctrl+I enter, Esc exit, all 8 shortcuts functional
- Autocomplete: Tab accepts suggestion (inserts suffix+space) or two nbsp
- Synonyms: Shift+Tab cycles through list, word replaces on Shift release,
  capitalisation preserved, cycles through all synonyms for a word
- Known limitation: no visual feedback for synonym cycling (stats bar — Phase 4)

### [2026-06-22 05:33] Session wrap
- **Action**: Updated AGENTS.md with current state, gotchas, and restart instructions.
- **Action**: Updated WORKLOG.md with this entry.
- **State**: Phases 2, 3, 5 complete and functional. Phase 1 (navi) is next priority,
  then Phase 4 (stats bar). Phases 6-7 are polish.
- **Branch**: `letta/left-xl-mvp-planning-d1bda888` (31 commits, pushed to origin)
- **Next session**: Start Phase 1 (navi sidebar plugin). Read `IMPLEMENTATION.md` §Phase 1
  and `UX.md` §4 for the spec. Study lite-xl's `treeview.lua` for view lifecycle patterns.
