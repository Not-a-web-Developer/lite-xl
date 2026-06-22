# AGENTS.md — Left XL

## What this is

Left XL is a hard fork of [lite-xl](https://github.com/lite-xl/lite-xl) that
reimplements [Left](https://github.com/hundredrabbits/left) — Hundredrabbits'
minimalist writing editor — on lite-xl's SDL + Lua architecture.

Left XL is a **writing editor**, not a code editor. It prioritises prose
workflow features over IDE features.

**Repository:** `https://github.com/Not-a-web-Developer/lite-xl`
(local clone: `~/Documents/github/left/left-xl/`)
**Branch:** `letta/left-xl-mvp-planning-d1bda888`

**Reference material (this repo):**
- `UX.md` — Complete Left user workflow spec. The *what* we're building.
- `IMPLEMENTATION.md` — Detailed implementation plan. The *how* we're building it.
- `WORKLOG.md` — Session-by-session log of what was done and why.

**Original Left repo (for reference):**
`~/Documents/github/Left/` — Contains the Electron-based Left editor and its
`desktop/sources/scripts/` directory.

---

## Current state (2026-06-22, 5:30 AM)

**Completed phases:** 2 (Synonyms), 3 (Insert mode), 5 (Font system)
**Remaining:** 1 (Navi), 4 (Stats bar), 6 (Splash), 7 (File mgmt)

**What works:**
- Font cycling (JetBrains Mono / Fira Sans / Zilla Slab) via Ctrl+Shift+, / .
- Insert mode (Ctrl+I) with 8 shortcuts (date, time, path, header, subheader,
  comment, line separator, list item)
- Autocomplete via Tab (accepts suggestion or inserts two nbsp)
- Synonym cycling via Shift+Tab (cycles, applies on Shift release, caps preserved)
- Synonym DB loaded and functional (4,023 entries)

**What's been disabled:**
- `config.plugins.treeview = false` (prep for navi)
- `config.plugins.autocomplete = false` (using our synonyms plugin instead)
- `config.plugins.scale = false` (ctrl+- conflicts with insert list shortcut)

**Important gotchas discovered during implementation:**
- lite-xl's `config.plugins` metatable auto-creates truthy entries on `__index` —
  must use `= false` (direct assignment) not `= x or false` to disable plugins
- `strict.lua` catches undeclared globals — every variable must be `local`
- Function ordering matters: Lua hoists local declarations but they're nil until
  the assignment line executes; a function that references a local defined below
  it will see nil at runtime
- SDL3 on Wayland/niri: `shift+tab` keymap binding doesn't fire — must manually
  detect "tab while shift held" in `keymap.on_key_pressed` hook
- Shift key repeat floods cycle events — must track `shift_tab_handled` flag
- The 150ms polling thread in synonyms.lua must NOT reset `synonym_index` in
  `update_synonym_state()` — only `reset_synonym_state()` resets it, and only
  when the cursor word changes
- Left's bundled .ttf fonts (Input Mono, Inter UI, Zilla Slab) render terribly
  with freetype/SDL — use lite-xl's own fonts instead
- Grayscale AA + slight hinting matches Ash's daily lite-xl settings
- `ctrl+/` for comment insert doesn't conflict because predicates ensure it only
  fires in insert mode (falls through to `doc:toggle-line-comments` otherwise)

---

## Architecture

**Tech stack:** C (SDL3) + Lua 5.4

```
src/          C sources — window, renderer (rencache), event loop, C API
data/core/    lite-xl core — doc model, views, commands, keymap, config, style
data/plugins/ All plugins including ours (synonyms, fonts, insert)
data/fonts/   Bundled fonts (Fira Sans, JetBrains Mono, icons, + Left's .ttfs)
```

**Key architectural facts:**
- lite-xl is a tabbed editor — files open as tabs
- Views managed by split-node tree (`Node` in `data/core/node.lua`)
- Command palette (`CommandView`) is the primary interaction pattern
- Plugins are Lua files in `data/plugins/` loaded on startup
- Plugin loading checks `config.plugins.<name> ~= false` to skip disabled plugins
- `StatusView:add_item()` API for extensible status bar items
- `command.add(predicate, map)` for registering commands with optional predicates
- `keymap.add(map, overwrite)` — use `overwrite=true` to replace existing bindings
- `keymap.on_key_pressed` hook chain can be extended (non-destructively)
- Session persistence at `~/.config/left-xl/session.lua`
- `@PROJECT_VERSION@` is a meson placeholder (not expanded yet — cosmetic)

---

## Config isolation

Left XL uses `~/.config/left-xl/` — does NOT share config with
Ash's daily lite-xl (`~/.config/lite-xl/`). Changed in `data/core/start.lua`.

On first launch, lite-xl creates `~/.config/left-xl/init.lua` automatically.
If the config dir gets corrupted, delete it and relaunch.

---

## Building & running

```bash
cd ~/Documents/github/left/left-xl
git checkout letta/left-xl-mvp-planning-d1bda888

# Full build (first time or after C changes):
rm -rf build && meson setup build && ninja -C build

# Lua-only changes (no rebuild needed):
ninja -C build

# Run:
./build/src/lite-xl

# Run with test config:
LITE_USERDIR=/tmp/test-left-xl ./build/src/lite-xl
```

- C changes require `ninja -C build`
- Lua changes only need a restart of the editor
- `start.lua` is embedded in the binary at build time — changes require meson reconfigure

---

## Plugin file map

| File | Purpose | Status |
|------|---------|--------|
| `data/plugins/synonyms.lua` | Autocomplete + synonym cycling | Working |
| `data/plugins/synonyms_db.lua` | 4,023-entry synonym dictionary | Loaded |
| `data/plugins/insert.lua` | Insert mode (8 shortcuts) | Working |
| `data/plugins/fonts.lua` | Font cycling (3 fonts) | Working |
| `data/core/style.lua` | Font defaults (grayscale+slight, 15px) | Modified |
| `data/core/init.lua` | Plugin disables, config | Modified |
| `data/core/start.lua` | USERDIR = left-xl | Modified |
| `meson.build` | Project renamed to left-xl | Modified |
| `scripts/convert-synonyms.js` | Conversion script for synonyms.js | Done |
| `IMPLEMENTATION.md` | Seven-phase plan | Reference |
| `AGENTS.md` | This file | Always up to date |
| `WORKLOG.md` | Session activity log | Appended to |

---

## UX reference

The full spec is in `UX.md`. Key behaviors to remember:

- **Markers:** lines starting with `# ` (header), `## ` (subheader), `-- ` (comment)
- **Synonyms:** Shift+Tab cycles, applied on Shift release, caps preserved
- **Autocomplete:** Tab accepts suggestion (or inserts two `\u00a0` if none)
- **Insert mode:** Ctrl+I enters, Esc/any insert exits. Smart prefix insertion
- **Font cycling:** Ctrl+Shift+, / Ctrl+Shift+. Three fonts. Uses lite-xl defaults.
- **Stats bar:** Shows L/W/V/C stats, cursor %, autoindent, selection, time
- **Save flash:** "Saved /path" shows for 200ms after save
- **Splash:** Left's welcome guide shown when no files are open

---

## What not to do

- Don't read the full `synonyms.js` or `synonyms_db.lua` into context — use scripts
- Don't delete `~/.config/left-xl` unless you need a clean slate
- Don't change config.plugins disable lines to use `or false` — use direct `= false`
- Don't declare locals after functions that reference them
- Don't bind Tab without `overwrite=true` — `doc:indent` eats it
- Don't rely on `shift+tab` keymap binding working on Wayland — use manual detection
- Don't reset `synonym_index` in `update_synonym_state()` — only in `reset_synonym_state()`
- Keep `WORKLOG.md` updated after each discrete unit of work
- Don't run `meson install` — just build for now
