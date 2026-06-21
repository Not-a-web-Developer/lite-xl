# Left XL — Implementation Plan

## Overview

Left XL is a hard fork of [lite-xl](https://github.com/lite-xl/lite-xl) that
reimplements the writing-focused features of [Left](https://github.com/hundredrabbits/left)
(Hundredrabbits' minimalist text editor) on top of lite-xl's SDL + Lua architecture.

**Goal:** A lightweight, native text editor optimized for prose writing, with
Left's workflow (navi sidebar with document markers, synonyms, insert mode,
stats bar) on lite-xl's performant C+SDL+Lua foundation.

**Base:** lite-xl 2.1.7+ (Lua 5.4) — `https://github.com/Not-a-web-Developer/lite-xl`

**Reference spec:** `UX.md` in the Left repository.
`~/Documents/github/Left/UX.md`

---

## Architecture Notes

### What we inherit from lite-xl (no work needed)

- SDL2 window management, renderer, event loop (`src/`, ~10k C lines)
- Lua module system, plugin loading with version checks
- Doc model with undo/redo, syntax highlighting, search
- Split-node view system (RootView, Node tree)
- Command palette / CommandView (replaces Left's operator)
- Status bar with extensible item API (`StatusView:add_item()`)
- Session persistence (`~/.config/left-xl/session.lua`)
- Config system with per-plugin settings (`config.plugins.*`)
- File dialogs (native system picker)
- Quit-with-unsaved via NagView
- Borderless window support (`config.borderless`)
- Autocomplete plugin (needs adaptation for Left-style behaviour)
- TreeView plugin (will be disabled by default)
- Tabbed document interface (lite-xl uses tabs; Left used navi file list)

### What we build

All new features are implemented as lite-xl plugins in `data/plugins/`,
with extensions to core where necessary. The approach is to keep changes
minimally invasive to core — plugin-first, extend core only when unavoidable.

### Config directory

`~/.config/left-xl/` — does not collide with daily lite-xl (`~/.config/lite-xl/`).

---

## MVP Scope

### Phase 1: Navi Plugin (`data/plugins/navi.lua`)

**Priority: HIGH** — This is the defining Left feature for writers.

**What it does:**
- Replaces lite-xl's TreeView with a Left-style navigation sidebar
- Shows open files (tabs) at the top level, each with filename + dirty marker (`*`)
- Shows `#`, `##`, `--` markers indented under the active file
- Active marker tracking: the marker closest to but not past the cursor line
- Active marker styled with `•` prefix
- Click file entry → switch to that tab
- Click marker entry → jump to that line
- Scroll sync with the active docview
- Toggle visibility with `Ctrl+\` (matches Left)
- Navigation shortcuts: `Ctrl+Shift+]`/`[` for next/prev file, `Ctrl+]`/`[` for next/prev marker

**Implementation notes:**
- lite-xl has a `treeview.lua` plugin — study it for view lifecycle patterns
- Creates a new View subclass (`NaviView:extend(View)`)
- Registers itself into the root node via `root_node:split("left", navi_view)`
- Marker detection: parse current doc lines, find `# `, `## `, `-- ` prefixes
- Uses `core.add_thread()` with coroutine for scroll sync (don't block the event loop)
- Dirty status: `doc:is_dirty()` → appends `*` to filename in navi display
- File list: iterates `core.docs` — same as lite-xl's tab bar but in sidebar form
- TreeView is disabled via `config.plugins.treeview = false` in default config

**Complexity:** Medium — new View subclass, marker parsing, scroll sync logic.
~300-400 lines of Lua.

---

### Phase 2: Synonym & Autocomplete (`data/plugins/synonyms.lua`)

**Priority: HIGH** — Core writing productivity feature.

**What it does:**
- Embeds Left's 48k-line synonym database as a Lua table
- Builds vocabulary from: synonym DB words + words in current document (≥4 chars, letters only)
- **Autocomplete** (Tab): when cursor is at end of a word and a vocab match exists,
  shows suggestion in stats bar. Tab inserts the remainder + space.
  No suggestion → inserts two non-breaking spaces (`\u00a0\u00a0`).
- **Synonym cycling** (Shift+Tab): when cursor is on a word in the synonym DB,
  shows synonym list in stats bar. Shift+Tab cycles through. Applied on Shift release.
  Preserves capitalisation. Index resets on Space/Enter.
- **Plural handling:** if word not found, try stripping trailing 's'.

**Implementation notes:**
- Ship as `data/plugins/synonyms.lua` + `data/plugins/synonyms_db.lua` (the 48k-line table)
- The DB is a Lua file at module level; loaded once on plugin init
- Vocabulary building: run on doc change (debounced), merge synonym keys + doc words
- Stats bar integration: uses `StatusView:add_item()` to register autocomplete/synonym items
- Keymap: `tab` → autocomplete, `shift+tab` → cycle synonym
- Must hook into `keyreleased` for shift-key detection (synonym application on shift release)
- Non-breaking spaces: Lua string `\u{00a0}` in Lua 5.4 (or use the raw UTF-8 bytes `\194\160`)

**Complexity:** Medium-High — data volume, key event handling, stats bar integration.
~400-500 lines + 48k-line data file.

**Memory note:** The synonyms DB is ~3MB on disk, maybe 15-20MB in memory as a Lua table.
Acceptable for MVP. Can optimize later with lazy-loading or binary serialization.

---

### Phase 3: Insert Mode (`data/plugins/insert.lua`)

**Priority: HIGH** — Writing workflow quality-of-life.

**What it does:**
- `Ctrl+I` enters insert mode. Esc exits. Any insert shortcut also exits.
- Stats bar shows insert mode help text while active.
- Eight insert shortcuts:

| Shortcut             | Action          | Inserted text                          |
|----------------------|-----------------|----------------------------------------|
| `Ctrl+D`             | Date            | `22-Jun-2026` + space                  |
| `Ctrl+T`             | Time            | Platform-dependent locale time         |
| `Ctrl+P`             | Path            | Current file path (if a file is open)  |
| `Ctrl+H`             | Header          | `# `                                   |
| `Ctrl+Shift+H`       | Subheader       | `## `                                  |
| `Ctrl+/`             | Comment         | `-- `                                  |
| `Ctrl+L`             | Line separator  | `\n===================== \n`           |
| `Ctrl+-`             | List item       | `- `                                   |

- Smart prefix insertion for `# `, `## `, `-- `, `- `:
  - If cursor is at start of a new line: insert at cursor
  - If text selected across multiple lines: prefix each line
  - If cursor is mid-line: insert at start of current line

**Implementation notes:**
- Registers commands via `command.add()` for each insert action
- Insert mode is a state flag in the plugin module, not a full mode system
- Stats bar: registers a temporary `StatusView:add_item()` that shows help text;
  removed on exit. Or uses `StatusView:show_tooltip()` for the help text.
- Keymap: all insert shortcuts active only when in insert mode
- Uses `doc:text_input()` and `doc:insert()` for text insertion
- Multi-line prefixing: iterate `doc.selections[]`, apply to each selected range

**Complexity:** Medium — command registration, cursor-aware insertion logic.
~250-350 lines.

---

### Phase 4: Stats Bar Rewrite (`data/plugins/stats.lua`)

**Priority: MEDIUM** — Depends on navi + synonyms + insert mode being in place.

**What it does:**
- Extends lite-xl's `StatusView` with Left-style mode-dependent items
- Replaces/augments lite-xl's default docview items with Left-style ones:

| State               | Left display                                    |
|---------------------|-------------------------------------------------|
| Default (docview)   | `42L 512W 387V 3104C 67.23% AI 14:32`         |
| Text selected       | `[189,245] 42L 512W ...`                        |
| Autocomplete active | `aband`**`on`**                                 |
| Synonyms active     | Horizontal scrollable synonym list              |
| URL detected        | `Open https://... with <c-b> 14:32`            |
| Scrolling           | `\|\|\|\|\|\|`**`\|\|\|\|`**` 62.50%`          |
| After save          | **Saved** /path/to/file (200ms flash)           |
| Insert mode         | `**Insert Mode** c-D *Date* c-T *Time* ...`    |
| Reader mode         | RSVP display (deferred)                         |

- L, W, V, C stats: computed from `doc.lines`
- Vocabulary count: unique case-insensitive alphanumeric words
- Autoindent indicator: `AI` from `config` / doc indent info
- Time: `os.date("%H:%M")`

**Implementation notes:**
- Uses lite-xl's `StatusView:add_item()` API — registers multiple items with
  predicates that check the current state
- Scroll indicator: hook into docview scroll events, show transient item
- Save flash: hook into doc `on_save`, use `core.status_view:show_message()`
- Autocomplete/synonym display: items registered by the synonyms plugin
- URL detection: scan current line for `://` or `www.` prefix
- Selection display: check if `doc:has_selection()`, format `[start,end]`

**Complexity:** Medium — mostly about wiring existing APIs together.
~300-400 lines.

---

### Phase 5: Font System (`data/plugins/fonts.lua`)

**Priority: MEDIUM** — Standalone, doesn't depend on other phases.

**What it does:**
- Three bundled fonts: mono (default), serif, sans-serif
- Font cycling: `Ctrl+Shift+,` (prev), `Ctrl+Shift+.` (next)
- Font size: `Ctrl+=` (+1px), `Ctrl+-` (-1px), `Ctrl+0` (reset to 12px)
- Line height: `fontSize + 8px`
- Persists font choice and size to `config.plugins.fonts`

**Implementation notes:**
- lite-xl already has font loading: `renderer.font.load(path, size)`
- Font files ship in `data/fonts/` alongside existing Open Sans and Fira Mono
- lite-xl's style table has `style.font` (UI), `style.code_font` (editor),
  `style.big_font`, `style.icon_font` — we modify `style.code_font`
- Default font size is `14 * SCALE` in lite-xl; Left's default is 12px.
  We set 12px as our default.
- Line height: modify `config.line_height` dynamically

**Complexity:** Low — mostly config + keymap + three font file additions.
~100-150 lines.

---

### Phase 6: Splash Page (`data/core/emptyview.lua` modification)

**Priority: LOW** — Polish item.

**What it does:**
- When launching with no open files, show Left's welcome guide instead of
  lite-xl's "lite" logo
- Splash is a read-only doc named "Splash"
- Silently removed when first real file is opened

**Implementation notes:**
- Modify `EmptyView:draw()` to show Left's welcome text
- Or create a "Splash" doc on startup when `core.docs` is empty
- lite-xl's `EmptyView` already handles the no-files state — just change the text

**Complexity:** Low — text swap in existing view.
~30-50 lines.

---

### Phase 7: Session & File Management Polish

**Priority: LOW** — Mostly inherited from lite-xl, needs Left-specific tweaks.

**What it does:**
- Open file paths persisted to session (lite-xl already does this via `core.recent_projects`)
- Unsaved changes dialog on quit (lite-xl already has `core.confirm_close_docs()`)
- Discard changes: `Ctrl+D` reloads file from disk
- New file: `Ctrl+N` creates untitled doc
- Force close: `Ctrl+Shift+W` closes without confirmation

**Implementation notes:**
- Port Left's keybindings: map `Ctrl+N`, `Ctrl+O`, `Ctrl+S`, `Ctrl+Shift+S`,
  `Ctrl+W`, `Ctrl+Shift+W`, `Ctrl+D` to existing lite-xl commands
- `Ctrl+Shift+W` for force close: add new command that skips dirty check
- `Ctrl+D` discard: add command that reloads doc from disk

**Complexity:** Low — mostly keymap + minor command additions.
~50-100 lines.

---

## Deferred (Post-MVP)

These are intentionally out of scope for the initial MVP:

- **Reader mode (RSVP speed reader):** Complex view manipulation, word-by-word display
  timing, stats bar repurposing. ~400-600 lines. Deferred.
- **Theme system (SVG/JSON loading):** Left's theme format is incompatible with
  lite-xl's Lua table colors. Would need a converter or format bridge. Deferred.
- **Frameless window:** lite-xl already supports it via `config.borderless` +
  `TitleView`. Can be enabled later.
- **Left's exact operator mode:** lite-xl's CommandView is a superset. No need to
  replicate Left's `find:` / `replace:` / `goto:` operator.
- **Drag-and-drop file opening:** lite-xl already handles `filedropped`. Left's
  `.thm`/`.svg` filtering is only relevant when theme support is added.
- **File watching / autoreload:** lite-xl has `autoreload.lua` plugin. Evaluate
  later.
- **Open URL in browser:** `Ctrl+B` to open URL under cursor. Platform-specific
  (`system.exec()` or SDL function). Low priority for a writing editor.
- **Add linebreak shortcut:** `Ctrl+Shift+Enter` to move to end of line and
  insert newline. Minor.
- **Autoindent toggle:** lite-xl has autoindent; needs a toggle command and
  stats bar indicator.

---

## Keymap Reference (Left's bindings → lite-xl commands)

| Left shortcut             | Action                | lite-xl command / implementation           |
|---------------------------|-----------------------|--------------------------------------------|
| `Ctrl+N`                  | New file              | `core:new-doc`                             |
| `Ctrl+O`                  | Open file             | `core:open-file`                           |
| `Ctrl+S`                  | Save                  | `doc:save`                                 |
| `Ctrl+Shift+S`            | Save As               | `doc:save-as`                              |
| `Ctrl+W`                  | Close file            | `root:close` (with dirty check)            |
| `Ctrl+Shift+W`            | Force close           | new: `doc:force-close`                     |
| `Ctrl+D`                  | Discard changes       | new: `doc:discard-changes`                 |
| `Ctrl+Z` / `Ctrl+Shift+Z` | Undo/Redo             | `doc:undo` / `doc:redo`                    |
| `Ctrl+F`                  | Find                  | `core:find-command` (CommandView)          |
| `Ctrl+G`                  | Goto line             | `doc:go-to-line`                           |
| `Ctrl+I`                  | Insert mode           | new: `insert:enter`                        |
| `Ctrl+\`                  | Toggle navi           | new: `navi:toggle`                         |
| `Ctrl+]` / `Ctrl+[`       | Next/Prev marker      | new: `navi:next-marker` / `navi:prev-marker`|
| `Ctrl+Shift+]` / `[`      | Next/Prev file        | `root:switch-to-next-tab` / `...-prev-tab` |
| `Ctrl+K`                  | Reader mode           | deferred                                   |
| `Tab`                     | Autocomplete          | new: `autocomplete:accept`                 |
| `Shift+Tab`               | Cycle synonym         | new: `synonym:cycle`                       |
| `Ctrl+B`                  | Open URL              | deferred                                   |
| `Ctrl+=` / `Ctrl+-`       | Font size +/-         | new: `font:increase-size` / `decrease`     |
| `Ctrl+0`                  | Reset font size       | new: `font:reset-size`                     |
| `Ctrl+Shift+,` / `.`      | Prev/Next font        | new: `font:prev` / `font:next`             |
| `Ctrl+Backspace`          | Reset font + theme    | new: `font:reset`                          |
| `Ctrl+H`                  | Hide window           | `system:hide-window` or platform-specific  |
| `Ctrl+Enter`              | Fullscreen            | `system:toggle-fullscreen`                 |
| `Ctrl+Q`                  | Quit                  | `core:quit`                                |

---

## Build & Distribution

### Building

```bash
meson setup build
ninja -C build
```

The binary outputs to `build/src/lite-xl` (or `left-xl` after renaming).

### Development workflow

1. C changes require `ninja -C build`
2. Lua changes are picked up on restart — no rebuild needed
3. Use `LITE_USERDIR` env var to override config path for testing

### Renaming the binary

Consider renaming the output binary from `lite-xl` to `left-xl` in `meson.build`
to avoid confusion with installed lite-xl. This affects the build system,
desktop file, and AppStream metadata.

---

## Risks & Open Questions

1. **Tab bar vs Navi coexistence:** lite-xl has a tab bar (TitleView tabs).
   We keep it — Left's navi + lite-xl tabs complement each other. Navi shows
   files in the sidebar; tabs let you switch quickly.

2. **Synonym DB memory impact:** 48k entries as a Lua table = ~15-20MB RAM.
   Might matter on low-end machines. Measure after implementation.

3. **Key conflicts:** lite-xl has its own keybindings. Need to check for
   conflicts with Left's shortcuts before registering.

4. **Command palette vs Left's operator:** lite-xl's CommandView is
   suggestion-based, not typed-command-based. Users would type "Find" and pick
   from suggestions rather than typing `find: <query>`. This is fine — it's
   arguably better UX — but it's different from Left.

5. **Multi-document (tabs):** lite-xl is tab-based. Left is single-window with
   a file list. We keep tabs AND add the navi — they serve different purposes.

6. **Lua 5.4 vs 5.1:** lite-xl uses Lua 5.4. This is fine — we're writing
   new code. Features like `goto`, integer `//`, `__close`, UTF-8 escapes
   (`\u{00a0}`) are available.

---

## Phase Ordering (Implementation Sequence)

```
Phase 5: Font System      ← Independent, quick wins
Phase 3: Insert Mode      ← Independent
Phase 2: Synonym DB       ← Independent (data-heavy, start early)
Phase 1: Navi Sidebar     ← Core visual feature
Phase 4: Stats Bar        ← Depends on navi + synonyms + insert for mode switching
Phase 7: File Mgmt Polish ← Depends on stats bar for save flash
Phase 6: Splash Page      ← Final polish
```

Phases 5, 3, and 2 can be worked on in parallel since they don't depend on each other.
Phase 1 (navi) is the biggest architectural piece.
Phase 4 (stats bar) ties everything together.
