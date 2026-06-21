# AGENTS.md — Left XL

## What this is

Left XL is a hard fork of [lite-xl](https://github.com/lite-xl/lite-xl) that
reimplements [Left](https://github.com/hundredrabbits/left) — Hundredrabbits'
minimalist writing editor — on lite-xl's SDL + Lua architecture.

Left XL is a **writing editor**, not a code editor. It prioritises prose
workflow features over IDE features.

**Repository:** `https://github.com/Not-a-web-Developer/lite-xl`
(local clone: `~/Documents/github/left/left-xl/`)

**Reference material (this repo):**
- `UX.md` — Complete Left user workflow spec. The *what* we're building.
- `IMPLEMENTATION.md` — Detailed implementation plan. The *how* we're building it.

**Original Left repo (for reference):**
`~/Documents/github/Left/` — Contains the Electron-based Left editor and its
`desktop/sources/scripts/` directory with the synonym database, reader, insert
mode, etc.

---

## Architecture

**Tech stack:** C (SDL2) + Lua 5.4

```
src/          ≈10k lines C  — window, renderer (rencache), event loop, C API
data/core/    ≈12k lines Lua — doc model, views, commands, keymap, config
data/plugins/ ≈5k lines Lua  — autocomplete, treeview, language syntax, etc.
data/fonts/   — bundled fonts (Open Sans, Fira Mono)
```

**Key architectural facts:**
- lite-xl is a **tabbed editor** — files open as tabs (like a browser or VS Code)
- Views are managed by a **split-node tree** (`Node` in `data/core/node.lua`)
- The command palette (`CommandView`) is the primary interaction pattern
- Plugins are Lua files in `data/plugins/` loaded on startup
- `config.plugins.<name>` controls plugin enable/disable
- `StatusView:add_item()` API for extensible status bar items
- Session persistence at `~/.config/left-xl/session.lua`

---

## Config isolation

Left XL uses `~/.config/left-xl/` — it does **NOT** share config with
the user's daily lite-xl (`~/.config/lite-xl/`). This was changed in
`data/core/start.lua` (first commit).

---

## Development workflow

### Building

```bash
cd ~/Documents/github/left/left-xl
meson setup build
ninja -C build
```

- **C changes** require rebuild (`ninja -C build`)
- **Lua changes** only need a restart of the editor
- Binary outputs to `build/src/lite-xl` (rename to `left-xl` pending)

### Testing

```bash
# Override config dir for testing (optional):
LITE_USERDIR=/tmp/test-left-xl ./build/src/lite-xl
```

### Git

- Letta Code agent handles all git operations
- Worktrees managed under `.letta/worktrees/`
- Do **not** manually delete worktree directories
- `IMPLEMENTATION.md` is the planning doc — update it as decisions change

---

## MVP scope (7 phases)

| # | Phase           | File(s)                     | Dependencies |
|---|-----------------|-----------------------------|--------------|
| 1 | Navi sidebar    | `data/plugins/navi.lua`     | None |
| 2 | Synonym + auto  | `data/plugins/synonyms.lua` + `synonyms_db.lua` | None |
| 3 | Insert mode     | `data/plugins/insert.lua`   | None |
| 4 | Stats bar       | `data/plugins/stats.lua`    | Navi, synonyms, insert |
| 5 | Font system     | `data/plugins/fonts.lua`    | None |
| 6 | Splash page     | `data/core/emptyview.lua`   | None |
| 7 | File mgmt       | keymap + minor commands     | Stats bar |

Phases 5, 3, and 2 can proceed in parallel.

**Deferred:** Reader mode, theme system, frameless window, Left's operator mode,
drag-and-drop filtering, open-URL.

Detailed plan: see `IMPLEMENTATION.md`.

---

## Key differences from lite-xl

- **Navi replaces TreeView** as the default sidebar — shows open files + document markers
- **No project scanning** needed (TreeView is disabled, project file indexing stays off)
- **Font system** bundles 3 fonts (mono/serif/sans) with cycling shortcuts
- **Tab bar stays** — lite-xl's tabs complement the navi file list
- **Config directory** is `~/.config/left-xl/`, not `~/.config/lite-xl/`

---

## UX reference (quick look)

The full spec is in `UX.md`. Key behaviors to remember:

- **Markers:** lines starting with `# ` (header), `## ` (subheader), `-- ` (comment)
- **Synonyms:** Shift+Tab cycles, applied on Shift release, caps preserved
- **Autocomplete:** Tab accepts suggestion (or inserts two `\u00a0` if none)
- **Insert mode:** Ctrl+I enters, Esc/any insert exits. Smart prefix insertion
- **Font cycling:** Ctrl+Shift+, / Ctrl+Shift+.  Three bundled fonts
- **Font size:** Ctrl+= / Ctrl+- / Ctrl+0. Default 12px. Line height = font + 8px
- **Stats bar:** Shows L/W/V/C stats, cursor %, autoindent, selection, time
- **Save flash:** "Saved /path" shows for 200ms after save
- **Splash:** Left's welcome guide shown when no files are open

---

## What not to do

- Don't read the full `synonyms.js` or `synonyms_db.lua` into context — use scripts
- Keep `WORKLOG.md` updated after each discrete unit of work
- Don't change `config.plugins.treeview` in user config — disable it in code
- Don't run `meson install` — just build for now
- Don't worry about backwards compatibility with lite-xl plugins
