# UX.md — Left Editor User-Facing Behaviour Specification

This document specifies every user-visible behaviour of Left, a minimalist
plaintext editor by Hundredrabbits. It is the sole reference for reimplementation.

---

## 1. Window and Shell

### 1.1 Window appearance

Left is **frameless by default** — no OS title bar, no window controls drawn
by the operating system. The window is a plain rectangle filled with the
current theme's background colour.

The top 30 pixels of the window are a **drag region**. The user can click and
drag anywhere in this strip to move the window. This region is transparent and
shows the editor content underneath.

Default window size: 800×540 pixels. Minimum size: 380×360 pixels. The window
is resizable.

Background colour at launch: `#000` (black), immediately overridden by the theme.

### 1.2 Platform differences

**On macOS:**
- The app is hidden when the window closes (not quit). `CmdOrCtrl+H` hides the
  window; pressing it again shows it.
- The window does NOT appear in the taskbar (`skipTaskbar: true`). It does stay
  in the Dock.
- The menubar auto-hides at the top of the screen.

**On Windows and Linux:**
- `CmdOrCtrl+H` minimises the window. Pressing it again restores it.

**All platforms:** the menu bar can be toggled visible/hidden with `F11`.

### 1.3 Fullscreen

`CmdOrCtrl+Enter` toggles fullscreen. This is a standard OS fullscreen, not a
custom "distraction-free" mode — the OS menubar and dock may still be reachable
per platform conventions.

### 1.4 Quit behaviour

When the user attempts to close the window (via `CmdOrCtrl+Q`, the close
button, or a compositor shortcut like Super+Q), Left checks all open files for
unsaved changes. If ANY file has unsaved changes:

1. A system dialog appears:
   > Unsaved data will be lost. Are you sure you want to quit?
   > [Yes] [No]
2. If the user clicks Yes, the application exits.
3. If the user clicks No, nothing happens — the app stays open.

If no file has unsaved changes, the app exits immediately without a prompt.

### 1.5 DevTools

Chromium DevTools are available via the View menu ("Toggle Developer Tools").
They are NOT a user-facing feature but are accessible.

---

## 2. Modes

Left has four modes. Each mode changes the menu bar, available keyboard
shortcuts, and some aspects of the UI. The mode concept is **not visually
indicated** anywhere except indirectly via menu changes and the stats bar.

### 2.1 Default Mode

**Purpose:** Standard text editing.

**Entry:** This is the mode Left starts in. Also entered by exiting any other mode.

**Exit:** N/A — this is the base mode.

**Menu bar (default mode):**

```
Left (macOS only / '*'):
  About                   CmdOrCtrl+,
  Fullscreen              CmdOrCtrl+Enter
  Hide                    CmdOrCtrl+H
  Reload                  —      (dev: reloads page)
  Force Reload            —      (dev: reloads page ignoring cache)
  Toggle Developer Tools  —      (dev: opens Chromium DevTools)
  Reset                   CmdOrCtrl+Backspace
  Quit                    CmdOrCtrl+Q

File:
  New                     CmdOrCtrl+N
  Open                    CmdOrCtrl+O
  Save                    CmdOrCtrl+S
  Save As                 CmdOrCtrl+Shift+S
  Discard Changes         CmdOrCtrl+D
  Close File              CmdOrCtrl+W
  Force Close             CmdOrCtrl+Shift+W

Edit:
  Undo                    CmdOrCtrl+Z
  Redo                    CmdOrCtrl+Shift+Z
  Cut                     CmdOrCtrl+X
  Copy                    CmdOrCtrl+C
  Paste                   CmdOrCtrl+V
  Delete                  —
  Select All              CmdOrCtrl+A
  Add Linebreak           CmdOrCtrl+Shift+Enter
  Toggle Autoindent       CmdOrCtrl+Shift+T

Select:
  Select Autocomplete      Tab
  Select Synonym           Shift+Tab
  Find                    CmdOrCtrl+F
  Replace                 CmdOrCtrl+Shift+F
  Goto                    CmdOrCtrl+G
  Open Url                CmdOrCtrl+B

Navigation:
  Next File               CmdOrCtrl+Shift+]
  Prev File               CmdOrCtrl+Shift+[
  Next Marker             CmdOrCtrl+]
  Prev Marker             CmdOrCtrl+[

View:
  Toggle Navigation       CmdOrCtrl+\
  Toggle Menubar          F11
  Previous Font           CmdOrCtrl+Shift+,
  Next Font               CmdOrCtrl+Shift+.
  Decrease Font Size      CmdOrCtrl+-
  Increase Font Size      CmdOrCtrl+=
  Reset Font Size         CmdOrCtrl+0

Mode:
  Reader                  CmdOrCtrl+K
  Insert                  CmdOrCtrl+I

Theme:
  Open Theme              CmdOrCtrl+Shift+O
  Reset Theme             CmdOrCtrl+Shift+Backspace
  — separator —
  Download Themes...      —      (opens browser URL)
```

### 2.2 Reader Mode (Speed Reader)

**Purpose:** RSVP (Rapid Serial Visual Presentation) reading of selected text.

**Entry:** Select at least 5 words of text, then press `CmdOrCtrl+K` or use
menu `Mode > Reader`.

If fewer than 5 words are selected:
- The reader does NOT start.
- The stats bar briefly shows the message:
  > **Reader** Select some text before starting the reader.
- The mode is exited immediately.

**Exit:** Press `Esc`, or use menu `Reader > Stop`, or the reader reaches the
end of the selected text. Also exits if you click anywhere in the window.

**UI changes:**
- The menu bar changes to a minimal set (see below).
- The textarea remains visible and the selection advances word by word.
- The stats bar is repurposed as a reader display showing the current word and
  progress information.

**Menu bar (reader mode):**

```
*:
  About                   CmdOrCtrl+,
  Fullscreen              CmdOrCtrl+Enter
  Hide                    CmdOrCtrl+H
  Reset                   CmdOrCtrl+Backspace
  Quit                    CmdOrCtrl+Q

Reader:
  Stop                    Esc
```

**Keyboard shortcuts available in reader mode:**
- `Esc` — stop reader and return to default mode.
- `CmdOrCtrl+,` — open About page in browser.
- `CmdOrCtrl+Enter` — toggle fullscreen.
- `CmdOrCtrl+H` — hide/minimise window.
- `CmdOrCtrl+Backspace` — reset theme to default.
- `CmdOrCtrl+Q` — quit (with unsaved-changes check).

### 2.3 Operator Mode (Command Bar)

**Purpose:** Execute find, replace, and goto commands via a bottom command input.

**Entry:**
- `CmdOrCtrl+F` → opens operator with `find: ` pre-filled.
- `CmdOrCtrl+Shift+F` → opens operator with `replace: a -> b` pre-filled.
- `CmdOrCtrl+G` → opens operator with `goto: ` pre-filled.
- Also entered programmatically via menu shortcuts.

**Exit:** Press `Esc`, or use menu `Operator > Stop`, or after a successful
`Enter`-triggered command execution. Also exits on click anywhere.

**UI changes:**
- The menu bar changes (see below).
- A command input slides up from the bottom of the window (see §3).
- The textarea loses focus.

**Menu bar (operator mode):**

```
*:
  About                   CmdOrCtrl+,
  Fullscreen              CmdOrCtrl+Enter
  Hide                    CmdOrCtrl+H
  Reset                   CmdOrCtrl+Backspace
  Quit                    CmdOrCtrl+Q

Edit:
  Undo                    CmdOrCtrl+Z
  Redo                    CmdOrCtrl+Shift+Z
  Cut                     CmdOrCtrl+X
  Copy                    CmdOrCtrl+C
  Paste                   CmdOrCtrl+V
  Delete                  —
  Select All              CmdOrCtrl+A

Find:
  Find                    CmdOrCtrl+F    (re-opens operator with 'find: ')
  Find Next               CmdOrCtrl+N    (finds next occurrence of last find)

Operator:
  Stop                    Esc
```

### 2.4 Insert Mode

**Purpose:** Quick insertion / transformation of text (dates, headers, markup).

**Entry:** `CmdOrCtrl+I` or menu `Mode > Insert`.

**Exit:** Press `Esc`, or menu `Mode > Stop`, or after executing any insert
shortcut. Also exits on click anywhere in the window.

**UI changes:**
- The menu bar changes (see below).
- The stats bar is repurposed to show the Insert Mode help text.
- The textarea remains focused for editing.

**Menu bar (insert mode):**

```
*:
  About                   CmdOrCtrl+,
  Fullscreen              CmdOrCtrl+Enter
  Hide                    CmdOrCtrl+H
  Reset                   CmdOrCtrl+Backspace
  Quit                    CmdOrCtrl+Q

Insert:
  Date                    CmdOrCtrl+D
  Time                    CmdOrCtrl+T
  Path                    CmdOrCtrl+P
  Header                  CmdOrCtrl+H
  SubHeader               CmdOrCtrl+Shift+H
  Comment                 CmdOrCtrl+/
  Line                    CmdOrCtrl+L
  List                    CmdOrCtrl+-

Mode:
  Stop                    Esc
```

**Stats bar display** (overrides normal stats while in insert mode):

> **Insert Mode** c-D *Date* c-T *Time* c-P *Path* c-H *Header* c-/ *Comment* Esc *Exit*.

The `c-P` portion only appears if at least one file is open.

---

## 3. The Operator Command Bar

### 3.1 Appearance

The operator is a single-line text input field that slides up from the bottom
of the window. It occupies the same horizontal position as the stats bar:
aligned with the textarea (not under the navi). It is 40px tall.

When inactive, it sits below the visible viewport (`bottom: -40px`). When
active, it animates to `bottom: 0px` over 150ms (CSS transition).

It uses the full editor width when the navi is hidden.

### 3.2 Commands

#### `find: <query>`

- **Passive** (typing): Nothing happens until the user types at least 3
  characters after `find: `. Before that, no results are shown.
- **Active** (Enter): Finds the first occurrence of `<query>` after the current
  cursor position. If the cursor is already at or past the last occurrence, it
  wraps to the top. The match is selected, and after 250ms the operator
  automatically closes, returning focus to the textarea with the match
  highlighted.
- **Find Next** (`CmdOrCtrl+N` in operator mode): Re-uses the last `find:`
  query and advances to the next match, wrapping if needed. The operator does
  NOT close on Find Next — each press advances.
- **Case:** The search is case-insensitive (query and text are both
  lowercased).
- **No match:** Nothing happens. The operator stays open.

#### `replace: <a> -> <b>`

- **Passive** (typing): Nothing happens until both `<a>` and `<b>` are at least
  3 characters and the `->` separator is present. Before that, no results.
- **Active** (Enter): Finds the next occurrence of `<a>` (same wrapping logic
  as find), selects it, waits 500ms, then replaces the selection with `<b>`.
  The operator closes.
- **No match / too short:** Nothing happens. The operator stays open.
- **Exact syntax:** There must be a space before and after `->`. The format is
  literally `replace: needle -> replacement`. No regex, no flags.

#### `goto: <line-number>`

- **Passive** (typing): Nothing happens.
- **Active** (Enter): Jumps to the specified line number (1-indexed).
  The operator closes. The line is selected.
- **Invalid input** (empty, not a number, < 1, > total lines): Nothing happens.
  The operator stays open.

### 3.3 History

- Pressing Arrow Up in the operator restores the previous executed command
  (the `prev` value, stored after last Enter).
- Only the most recent command is remembered — there is no multi-level history.

### 3.4 Cancellation

- Press `Esc` → operator closes, input cleared, focus returns to textarea.
- Click anywhere in the window → operator closes.

### 3.5 Edge cases

- Typing a command name that doesn't match `find`, `replace`, or `goto`:
  silently ignored (logged to console, not shown to user).
- Typing just `find:` with no space and no query: nothing happens.
- The colon after the command word is required — the code strips it, but the
  passive/active methods parse `this.el.value.split(' ')[0].replace(':', '')`,
  so the colon must be present.

---

## 4. The Navigation Sidebar (Navi)

### 4.1 Position and visibility

The navi is a vertical panel on the left side of the window, occupying roughly
the left quarter of the window (calculated as `calc(25vw - 40px)`).

It is visible by default. Toggle with `CmdOrCtrl+\` or menu
`View > Toggle Navigation`.

When toggled off:
- The navi fades to transparent (opacity 0, transition: 10ms — near-instant).
- The textarea and stats bar expand to fill the full window width.
- The textarea shifts left (from 25vw to 5% left).

The toggle adds/removes the CSS class `mobile` on the `<body>` element. The
class name "mobile" is a historical artefact — it simply means "navi hidden."

### 4.2 Content

The navi shows:

1. **Each open file** as a top-level list item. The active file's entry is
   highlighted. Each file shows:
   - Its **filename** (last path segment). For untitled files: "Untitled".
   - An **asterisk `*`** appended to the right if the file has unsaved changes.

2. **Markers** from the active file, indented under the file entry. Only the
   currently active file's markers are shown; other files' markers are hidden
   (CSS: `li.marker { display: none }` on inactive uls).

### 4.3 Marker types and syntax

Markers are lines whose trimmed content begins with specific prefixes:

| Prefix    | Type        | Navi display  | Visual cue                           |
|-----------|-------------|---------------|--------------------------------------|
| `# `      | header      | Indented 15px | `#` before text (or `•` when active) |
| `## `     | subheader   | Indented 15px | No prefix (or `•` when active)       |
| `-- `     | comment     | Indented 30px | No prefix (or `•` when active)       |

A "marker" is any line starting with `#`, `##`, or `--` at column 0 (after
trimming whitespace). The marker text in the navi is the line content minus the
prefix characters, trimmed.

### 4.4 Active marker

The "active" marker is the marker whose line is closest to but not past the
current cursor line. Specifically: the last marker whose line number is ≤ the
cursor's line number.

The active marker is styled with `•` as its prefix (instead of `#` or nothing).

### 4.5 Navigation shortcuts

| Shortcut            | Action                                                             |
|---------------------|--------------------------------------------------------------------|
| `CmdOrCtrl+Shift+]` | Switch to next file (wraps around). Cursor goes to line 0.         |
| `CmdOrCtrl+Shift+[` | Switch to previous file (wraps around). Cursor goes to line 0.     |
| `CmdOrCtrl+]`       | Jump to next marker in the current file (wraps to first if at last).|
| `CmdOrCtrl+[`       | Jump to previous marker in the current file (wraps to last if at first).|

### 4.6 Click behaviour

- Clicking a **file entry**: switches to that file (cursor at line 0).
- Clicking a **marker entry**: switches to that file's page and jumps to the
  marker's line.

### 4.7 Scroll sync

The navi vertically scrolls in sync with the textarea. As the user scrolls
through the document, the navi content translates upward proportionally so that
the relevant markers remain visible. The sync uses the same scroll ratio as the
textarea (scrollTop / maxScroll), converted to a `translateY` percentage on the
navi element.

---

## 5. File and Project Model

### 5.1 What a "project" is

Left's "project" is simply the collection of currently open files. There is no
formal project file, no saved project metadata, and no concept of a project
directory. It is an ephemeral workspace managed by open-file persistence.

### 5.2 Splash screen

When Left launches with no previously open files:

- A built-in "Splash" page is displayed. It is a read-only document containing
  the welcome guide (see §12).
- The Splash page is not saved to disk and has a fixed name: "Splash".
- It report `has_changes()` as always `false`.

When the first real file is opened, the Splash page is silently removed from
the page list.

### 5.3 Opening files

Files can be opened in several ways:

1. **Menu:** `File > Open` (`CmdOrCtrl+O`) → system file dialog. Multiple
   files can be selected. Each selected file is added.

2. **Drag and drop:** Drop one or more text files onto the editor window. Files
   with non-text MIME types are skipped. Files ending in `.thm` are skipped
   (those are theme files — see §9). Each accepted file is opened.

3. **CLI argument (Windows only):** If a file path is passed as the first
   command-line argument (`remote.process.argv[1]`), that file is opened on
   launch.

4. **New file:** `CmdOrCtrl+N` creates a new blank file ("Untitled", no path).

When a file is opened:
- If the file is already open (path matches an existing page), it is NOT
  re-added. A warning is logged to console (not shown to user).
- The new file becomes the active page.
- The cursor moves to the start of the file.
- The Splash is removed if it was present.

### 5.4 Session persistence

Open file paths are saved to `localStorage` under the key `paths` as a JSON
array. On next launch, if `paths` exists and is valid JSON, all listed files
are re-opened automatically.

If a previously-open file no longer exists on disk, opening silently fails
(a warning is logged, and the page has null path).

### 5.5 Saving files

**Save** (`CmdOrCtrl+S`):
- If the file has a path: writes the current text to disk. The stats bar
  briefly flashes (200ms): **Saved** /path/to/file.
- If the file has no path ("Untitled"): acts as Save As.

**Save As** (`CmdOrCtrl+Shift+S`):
- Opens a system save dialog.
- If the file was previously untitled: the path is set to the chosen location.
- If the save path differs from the current path: a NEW page is added for the
  new path (effectively a "save a copy" — the original file remains open and
  unchanged).

### 5.6 Unsaved state detection

A file is considered "modified" (`has_changes()` returning true) if:

1. The file has no path AND its text is non-empty, OR
2. The file has a path AND the text in memory differs from the text on disk
   (re-read from the filesystem each time `has_changes()` is called).

The unsaved state is surfaced in two ways:
- An asterisk `*` appears after the filename in the navi.
- The quit dialog triggers if any file has unsaved changes.

### 5.7 External file modification

When `has_changes()` is called (triggered by any `update()` cycle, which fires on
every keystroke, click, or mode change), the method reads the file from disk
and compares it to the in-memory text. If they differ AND the file size has
changed, it checks the `watchdog` flag. If `watchdog` is true (default):

1. A system dialog appears:
   > File was modified outside Left. Do you want to reload it?
   > [Yes] [No] [Ignore future occurrences]
   > New size of file is: N bytes.

2. **Yes:** The in-memory text is replaced with the disk contents. The editor
   reloads. No unsaved-changes dialog for this specific change.

3. **No:** The in-memory text is kept. The file is now marked as having
   unsaved changes.

4. **Ignore future occurrences:** The `watchdog` flag is toggled to `false`
   for this file. Future external changes will NOT trigger the dialog for this
   file until Left is restarted.

If the file size has NOT changed but the content differs (unlikely in practice
— this path exists in the code for edge cases), the dialog is NOT shown but
`has_changes()` still returns true.

### 5.8 Closing files

**Close File** (`CmdOrCtrl+W`):
- If only one file is open: does nothing (cannot close the last file).
- If the file has unsaved changes: a dialog appears:
  > Are you sure you want to discard changes?
  > [Yes] [No]
  - Yes: closes the file (discarding changes). The previous file becomes active.
  - No: nothing happens.
- If no unsaved changes: closes immediately. The previous file becomes active.

**Force Close** (`CmdOrCtrl+Shift+W`):
- No confirmation dialog. Changes are silently discarded.
- If only one file is open: triggers quit (same as `CmdOrCtrl+Q`).

### 5.9 Discard Changes

`File > Discard Changes` (`CmdOrCtrl+D`) reloads the current file from disk,
discarding all in-memory edits. A confirmation dialog appears:
> Are you sure you want to discard changes?
> [Yes] [No]

---

## 6. Autocomplete

### 6.1 When suggestions appear

A suggestion is displayed in the stats bar when ALL of the following are true:

1. The cursor is at the end of a word (the character immediately after the
   cursor is a space, newline, or end-of-file).
2. The word at the cursor (the contiguous sequence of `[a-zA-Z]` characters
   extending backwards from the cursor) is non-empty after trimming.
3. A matching word exists in the vocabulary that starts with the cursor word,
   and that matching word is different from the cursor word (case-insensitive
   comparison).

The vocabulary is built from:
- All words in the current document (at least 4 characters, containing only
  letters).
- All root words and synonym words from the built-in synonym dictionary.

Words containing non-letter characters (numbers, punctuation) are excluded
from the vocabulary.

### 6.2 How the suggestion is displayed

The stats bar shows: `<cursor-word><suggested-suffix>` where the cursor-word
portion is plain and the suffix is bold. For example, if the user types "aband"
and the suggestion is "abandon", the stats bar shows: `aband`**`on`**.

### 6.3 Accepting a suggestion

Press `Tab` (or use menu `Select > Select Autocomplete`):
- If a suggestion is available AND is different from the current word:
  the remainder of the word is inserted (e.g. `on` for "abandon" from "aband"),
  followed by a space. The cursor advances past the inserted text and space.
- If no suggestion is available OR the suggestion is identical to the current
  word: two non-breaking spaces (`\u00a0\u00a0`) are inserted at the cursor.

`Tab` behaviour is handled in the keydown event, with `preventDefault()` to
stop the browser's default tab behaviour.

---

## 7. Synonyms

### 7.1 When synonyms appear

When the cursor is on a word (any position within the word, not just at the
end), and that word exists in the synonym dictionary, the stats bar shows a
horizontal scrollable list of synonyms.

The word must be at least 4 characters long after trimming.

The synonym dictionary is a built-in static dataset (several thousand words,
each with a list of up to ~30 synonyms). See `scripts/synonyms.js` for the
complete database — it is NOT user-editable.

### 7.2 Plural handling

If the word is not found directly, Left checks if the word ends in "s" and
tries the singular form (word minus trailing "s") in the dictionary.

### 7.3 Cycling through synonyms

Press `Shift+Tab` (or menu `Select > Select Synonym`) repeatedly to cycle
through the synonym list. The currently selected synonym is highlighted
(underlined and bold).

Shift+Tab increments the synonym index (wrapping around), scrolls the list to
bring the new active item into view, and highlights it.

### 7.4 Applying a synonym

The synonym is NOT applied on Shift+Tab. It is applied when the user releases
the **Shift key** (keyup event with keyCode 16).

When applied:
- The word at the cursor is replaced with the selected synonym.
- Capitalisation is preserved: if the original word started with an uppercase
  letter, the replacement word is capitalised to match.
- The stats bar updates to reflect the replacement.
- The synonym index resets to 0 on the next space or Enter.

### 7.5 Visual behaviour

- The synonym list is rendered as an inline `<ul>` with `<li>` items inside the
  stats bar. It scrolls horizontally.
- The active synonym has CSS class `active` (underlined, bold).
- When `Shift+Tab` navigates to a new synonym, the stats bar scrolls to show
  it with smooth behaviour.

---

## 8. URL Handling

### 8.1 URL detection

When the cursor is on a line that contains a word matching `://` or `www.`,
that word is detected as a URL. The detection happens on every `update()` cycle
(via `active_url()`).

### 8.2 URL display

The stats bar shows: `Open <url> with <c-b>` with the current time on the
right.

### 8.3 Opening a URL

Press `CmdOrCtrl+B` (menu `Select > Open Url`):
- If a URL is detected, Left selects the entire URL word, waits 500ms, then
  opens it in the system's default browser (`shell.openExternal`).
- If no URL is detected, nothing happens.

---

## 9. Theme System

### 9.1 Theme format

Left supports two theme file formats:

**SVG themes:** An SVG file where each colour is specified as the `fill`
attribute of an element with a specific `id`:

```xml
<svg>
  <rect id="background" fill="#222222"/>
  <rect id="f_high"     fill="#eeeeee"/>
  <rect id="f_med"      fill="#888888"/>
  <rect id="f_low"      fill="#666666"/>
  <rect id="f_inv"      fill="#0000ff"/>
  <rect id="b_high"     fill="#ff99aa"/>
  <rect id="b_med"      fill="#aa99ff"/>
  <rect id="b_low"      fill="#000000"/>
  <rect id="b_inv"      fill="#aaff99"/>
</svg>
```

**JSON / .thm themes:** A JSON object with the same nine keys:
```json
{
  "background": "#222",
  "f_high": "#eee",
  "f_med": "#888",
  "f_low": "#666",
  "f_inv": "#00f",
  "b_high": "#f9a",
  "b_med": "#a9f",
  "b_low": "#000",
  "b_inv": "#af9"
}
```

All nine keys are required. Files missing any key are silently rejected.

### 9.2 Theme colour roles

| Variable     | Role                                                                    |
|--------------|-------------------------------------------------------------------------|
| `background` | Editor background colour.                                               |
| `f_high`     | Primary text colour (high contrast). Used for main text, active items.  |
| `f_med`      | Medium text colour. Used for secondary text, inactive file entries.     |
| `f_low`      | Low text colour. Used for navi markers, stats bar default, dim text.    |
| `f_inv`      | Inverted foreground. (Present in theme but not heavily used in UI.)     |
| `b_high`     | High-contrast background / accent.                                      |
| `b_med`      | Medium-contrast background / accent.                                    |
| `b_low`      | Low-contrast background. Used for selection background.                 |
| `b_inv`      | Inverted background.                                                    |

### 9.3 Loading a theme

**By file dialog:** `Theme > Open Theme` (`CmdOrCtrl+Shift+O`) → system file
dialog, filtered to `.svg` files. The selected file is read and loaded.

**By drag and drop:** Drop a `.svg` or `.thm` file onto the editor window. The
drop handler in `events.js` skips `.thm` files for file-opening purposes, but
the theme drop handler in `theme.js` accepts both `.svg` and `.thm`. However,
note that the general drop handler in `events.js` runs FIRST and skips `.thm`
files entirely (they are not added as pages). The theme handler in `theme.js`
has its own `window.addEventListener('drop', ...)` so both handlers fire —
`.thm` files are caught by the theme handler but skipped by the file handler.

### 9.4 Theme persistence

The active theme is saved to `localStorage` under the key `theme` as a JSON
string. On next launch, the saved theme is loaded. If no theme is saved, the
default theme is used.

### 9.5 Default theme

```
background: #222
f_high:     #eee
f_med:      #888
f_low:      #666
f_inv:      #00f
b_high:     #f9a
b_med:      #a9f
b_low:      #000
b_inv:      #af9
```

### 9.6 Resetting the theme

`CmdOrCtrl+Backspace` (menu `* > Reset`) resets the font AND theme to defaults.

`CmdOrCtrl+Shift+Backspace` (menu `Theme > Reset Theme`) resets only the theme.

### 9.7 Theme transition

When a theme changes, CSS variables on `:root` are updated. The `body` has a
`transition: background-color 500ms` — the background colour smoothly
transitions over half a second. Text colours change immediately (no transition).

---

## 10. Stats Bar

### 10.1 Position

The stats bar is a fixed-position bar at the bottom of the textarea region. It
is aligned with the textarea (right of the navi), 40px tall. When the navi is
hidden, it expands to fill the full width.

It has a drag region, meaning the user can drag the window from the stats bar.

### 10.2 Default display

When nothing special is happening (no selection, no suggestion, no synonyms, no
URL, not in insert/reader mode):

> `42L 512W 387V 3104C 67.23% AI 14:32`

| Element | Meaning                                                            |
|---------|--------------------------------------------------------------------|
| `L`     | Number of lines (split by `\n`).                                   |
| `W`     | Number of words (split by space).                                  |
| `V`     | Vocabulary — number of unique words (case-insensitive, alphanumeric only). |
| `C`     | Character count (total string length).                             |
| `%`     | Cursor position as percentage of total characters (2 decimal places). |
| `AI`    | Autoindent status. Styled with `fh` colour class when enabled.     |
| `14:32` | Current time (24-hour, hours:minutes, minutes zero-padded).        |

### 10.3 Selection display

When text is selected (selectionStart ≠ selectionEnd):

> **[189,245]** 42L 512W 387V 3104C 67.23% AI 14:32

The selection range is shown in bold at the start.

### 10.4 Suggestion display

When an autocomplete suggestion is available (see §6):

> abandon**on**

The existing portion of the word is plain; the suggested suffix is bold.

### 10.5 Synonym display

When synonyms are available (see §7):

The stats bar shows an inline horizontal list of synonym words. The currently
selected one is underlined and bold. The list is scrollable.

On each Shift+Tab, the list scrolls to the active item (smooth behaviour).

### 10.6 URL display

When a URL is detected on the current line (see §8):

> Open **https://example.com** with <c-b> 14:32

### 10.7 Scroll display

When the user scrolls the textarea (NOT during reader mode), the stats bar
temporarily shows a scroll indicator:

> `||||||`**`||||`** 62.50%

This is an ASCII-style progress bar: 10 pipe characters, with the filled
portion bold. The percentage follows. This replaces the normal stats display
during scroll.

### 10.8 Post-save flash

After a successful save, the stats bar briefly shows (for 200ms):

> **Saved** /path/to/file

### 10.9 Reader display

In reader mode, the stats bar shows the RSVP display (see §11.2).

### 10.10 Insert mode display

In insert mode, the stats bar shows the insert help text (see §2.4).

---

## 11. Reader Mode (RSVP Speed Reader)

### 11.1 Activation requirements

- The user must select at least 5 words of text.
- Fewer than 5: reader refuses to start, shows error in stats bar.
- The selected text may span multiple lines; newlines are converted to spaces.

### 11.2 Display

The reader uses the stats bar as its display surface. The content shown is:

```
: <pad><before><KEY><after>                              12W 2S 45% 343W/M
```

- **`:`** — a literal colon prefix.
- **`pad`** — invisible padding characters (rendered with `opacity: 0`) used to
  keep the ORP letter in a fixed horizontal position across words.
- **`before`** — the part of the current word before the ORP letter,
  styled with `fm` colour class (medium contrast).
- **`KEY`** — the ORP letter (the middle character of the word),
  styled with `fh` colour class (high contrast, bold).
- **`after`** — the part of the word after the ORP letter,
  styled with `fm` (but omitted for single-character words).
- Right side info:
  - `12W` — words remaining in the queue.
  - `2S` — estimated seconds remaining (queue length × 175ms / 1000, integer).
  - `45%` — progress (words read / total words × 100).
  - `343W/M` — speed: `(1000 / 175) × 60 = ~343` words per minute.

### 11.3 ORP (Optimal Recognition Point)

The ORP is one character before the middle of the word:
- For "abandon" (7 chars): ORP index = `floor(7/2) - 1` = 2.
  Display: `ab`**`a`**`ndon` (the third character 'a' is the key).
- The ORP position is calculated per word. Left finds the longest word in the
  selected text to determine the maximum ORP offset, then pads all shorter
  words with invisible characters so the ORP letter always appears at the same
  horizontal position.

### 11.4 Reading speed

The speed is fixed at **175ms per word**. There is no user control over speed.
The speed is hardcoded in `Reader.speed = 175`.

### 11.5 Progress

As the reader advances:
- The text selection in the textarea advances word by word (the textarea
  selection is set to cover the words read so far in the original text).
- The textarea auto-scrolls to keep the selection visible (200ms ease-in-out
  scroll animation).

### 11.6 Stopping

The reader stops when:
- The queue is exhausted (all words read).
- The user presses `Esc`.
- The user clicks anywhere in the window.
- The user uses menu `Reader > Stop`.

After stopping, the mode returns to default, the stats bar returns to normal,
and the textarea retains the last selection position.

---

## 12. Insert Mode

### 12.1 Available insertions

All shortcuts use `CmdOrCtrl` as the modifier. Each shortcut exits insert mode
after executing.

| Shortcut               | Action                                    | Inserted text / behaviour                 |
|------------------------|-------------------------------------------|-------------------------------------------|
| `CmdOrCtrl+D`          | Insert date                               | `DD-Mon-YYYY` (e.g. `01-Jun-2026`) + space|
| `CmdOrCtrl+T`          | Insert time                               | Current locale time string + space        |
| `CmdOrCtrl+P`          | Insert current file path                  | Full file path. Does nothing if no files open.|
| `CmdOrCtrl+H`          | Insert header                             | `# `                                      |
| `CmdOrCtrl+Shift+H`    | Insert subheader                          | `## `                                     |
| `CmdOrCtrl+/`          | Insert comment                            | `-- `                                     |
| `CmdOrCtrl+L`          | Insert horizontal line                    | Newline + `===================== ` + newline|
| `CmdOrCtrl+-`          | Insert list item                          | `- `                                      |

### 12.2 Insertion behaviour for markup prefixes

For Header (`# `), Subheader (`## `), Comment (`-- `), and List (`- `),
the behaviour depends on context:

**If the character before the cursor is a newline AND nothing is selected:**
The prefix is inserted at the cursor position (the beginning of a new line).

**If text is selected across multiple lines:**
Each selected line is prefixed. For example, selecting three lines and pressing
`CmdOrCtrl+H` adds `# ` to the start of each line.

**Otherwise (cursor mid-line, nothing selected):**
The prefix is inserted at the start of the current line. The cursor position
within the line is preserved (complex cursor adjustment is performed).

### 12.3 Line insertion

`CmdOrCtrl+L` inserts a horizontal separator. If the cursor is not already at
the start of a line, a newline is inserted first. Then:
```
===================== 
```
(with a trailing newline).

### 12.4 Date format

The date is formatted as: zero-padded day (2 digits), hyphen, three-letter
month abbreviation (English), hyphen, four-digit year. Month names are:
Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec.

Example: `01-Jun-2026`

### 12.5 Time format

`new Date().toLocaleTimeString()` — platform-dependent locale format.

### 12.6 Path

`CmdOrCtrl+P` inserts the path of the currently active file. If no files are
open (only the Splash), nothing happens.

---

## 13. Font System

### 13.1 Available fonts

Three fonts, all bundled as `.ttf` files:

| CSS family name      | File              | Description                |
|----------------------|-------------------|----------------------------|
| `custom_mono`        | `mono.ttf`        | Monospace (default)        |
| `custom_serif`       | `serif.ttf`       | Serif (bundled as Zilla Slab, but replaceable) |
| `custom_sans_serif`  | `sans_serif.ttf`  | Sans-serif (bundled as Roboto Condensed, but replaceable) |

The serif and sans-serif fonts can be replaced by swapping the `.ttf` files in
`media/fonts/` — the CSS references the same filename regardless of content.

### 13.2 Cycling fonts

| Shortcut              | Action                                    |
|-----------------------|-------------------------------------------|
| `CmdOrCtrl+Shift+,`   | Previous font (wraps: mono → sans → serif)|
| `CmdOrCtrl+Shift+.`   | Next font (wraps: mono → serif → sans)    |

### 13.3 Font size

| Shortcut          | Action                                              |
|-------------------|-----------------------------------------------------|
| `CmdOrCtrl+=`     | Increase font size by 1px.                          |
| `CmdOrCtrl+-`     | Decrease font size by 1px.                          |
| `CmdOrCtrl+0`     | Reset font size to 12px.                            |

**Default:** 12px.

**Line height** is always `font-size + 8px`. So at 12px, line-height is 20px.
This changes automatically when font size changes.

### 13.4 Persistence

Font family and font size are saved to `localStorage` under key `font` as JSON:
```json
{"fontSize": 12, "fontIndex": 0}
```
These are restored on next launch. If no saved font exists, the defaults apply.

### 13.5 Resetting

`CmdOrCtrl+Backspace` (menu `* > Reset`) resets both font and theme. Font
defaults: `mono`, 12px. The localStorage entry is removed.

---

## 14. Text Editing Behaviours

### 14.1 Textarea

All editing happens in a single `<textarea>` element. The textarea:
- Uses the current font family, size, and line height.
- Has no border, outline, or background (transparent — theme background shows
  through).
- Disables browser spellcheck, autocorrect, autocapitalize, autocomplete.
- Has `resize: none`.
- Is `position: fixed`, aligned with the navi on its left.
- Scrolls independently (the textarea scrolls, not the body).

### 14.2 Autoindent

When enabled (default: on, toggle with `CmdOrCtrl+Shift+T`):

On pressing Enter, after the newline is inserted, Left examines the previous
line for leading whitespace. It inserts the same indentation (spaces and tabs)
at the start of the new line.

The autoindent state is shown in the stats bar: when on, the `AI` indicator is
styled with the `fh` colour class (high contrast); when off, it's styled with
the default `f_low` colour.

### 14.3 Add Linebreak

`CmdOrCtrl+Shift+Enter` (menu `Edit > Add Linebreak`): moves the cursor to the
end of the current line and inserts a newline.

### 14.4 Selection and cursor

- Standard click-and-drag text selection.
- `CmdOrCtrl+A` selects all.
- Selection range is displayed in the stats bar as `[start,end]` when text is
  selected.
- The `update()` method fires on every `select` event (mouse selection change)
  and on keyup (for most keys). Arrow key navigation forces update via a
  `setTimeout(0)` to ensure it fires after the selection position updates.

### 14.5 Undo/Redo

Standard system undo/redo via menu `Edit > Undo` (`CmdOrCtrl+Z`) and
`Edit > Redo` (`CmdOrCtrl+Shift+Z`). These use Electron's built-in roles —
Left does not implement its own undo stack on top of the textarea.

---

## 15. Markers and Navigation

### 15.1 Marker syntax

Markers are defined by the first characters of a line (after trimming
whitespace):

| Prefix  | Type       | Purpose (by convention)              |
|---------|------------|--------------------------------------|
| `# `    | header     | Top-level section heading            |
| `## `   | subheader  | Sub-section heading                  |
| `-- `   | comment    | Metadata / note / annotation         |

A line starting with `##` (but not `###` — only two hashes) is a subheader
only if it has exactly two hashes at position 0 of the trimmed line.

Marker detection uses `line.substr(0, 2)` for `##` and `--`, and
`line.substr(0, 1)` for `#`. The order of checking is: `##` first, then `#`,
then `--`. This means `##` takes precedence over `#` (a line starting with
`##` is a subheader, not a header).

### 15.2 Navigating to markers

`CmdOrCtrl+]` jumps to the next marker in the current file. `CmdOrCtrl+[` jumps
to the previous marker. Both wrap: after the last marker, next goes to the
first; before the first marker, prev goes to the last.

### 15.3 Navigating between files

`CmdOrCtrl+Shift+]` next file, `CmdOrCtrl+Shift+[` previous file. Both wrap.
Switching files places the cursor at line 0.

### 15.4 Goto line

`CmdOrCtrl+G` opens the operator with `goto: ` pre-filled. Enter a line number
(1-indexed) and press Enter to jump to that line.

---

## 16. Drag and Drop

### 16.1 File drops

Any number of files can be dropped onto the window. Each file is checked:
- Must have a `.path` property (Electron-specific).
- If the file has a MIME type, it must match `text/*`. Non-text files are
  skipped.
- Files ending in `.thm` are skipped by the file handler (they are handled
  separately by the theme handler).

Accepted files are added to the project. The last file opened becomes the
active page.

### 16.2 Theme drops

Files ending in `.svg` or `.thm` are processed as themes by the theme handler
(see §9.3). The theme handler's drop listener runs independently — both the
file handler and theme handler can trigger from the same drop event.

---

## 17. Splash / Welcome Screen

### 17.1 When displayed

The splash appears when Left starts with no previously open files (no paths in
localStorage, or the paths fail to load).

### 17.2 Content

The splash page contains Left's built-in guide:

```
# Welcome

## Guide

Left is a simple, minimalist, open-source and cross-platform text editor.

- Create markers by beginning lines with #, ## or --.
- Navigate quickly between markers with <c-]> and <c-[>.
- Open a text file by dragging it, or with <c-o>.
- Highlight some text and press <c-k> to enable the speed reader.
- Press <tab> to auto-complete a previously used, or common, word.
- Press <shift tab> to scroll through the selected word's synonyms.
- Press <c-\> to toggle the navigation.

-- Details

- L : stands for Lines.
- W : stands for Words.
- V : stands for Vocabulary, or unique words.
- C : stands for Characters.

-- Quick Inserts

You can quickly insert or transform text by activating the Insert Mode with <c-i>, followed by one of these shortcuts:

- <c-d> : Date
- <c-t> : Time
- <c-p> : Path
- <c-h> : Header
- <c-H> : Sub-Header
- <c-/> : Comment
- <c-l> : Line

## Extras

View sources: https://github.com/hundredrabbits/left

-- Themes

Download additional themes: http://hundredrabbits.itch.io/Left
```

### 17.3 Behavior

- The splash is named "Splash" in the navi.
- It reports `has_changes()` as `false` — it never triggers unsaved-change
  warnings.
- It cannot be saved to disk.
- When the first real file is opened, the splash is silently removed from the
  page list.

---

## 18. About and External Links

### 18.1 About

`CmdOrCtrl+,` (menu `* > About`) opens `https://github.com/hundredrabbits/Left`
in the system's default browser.

### 18.2 Download Themes

Menu `Theme > Download Themes...` opens
`https://github.com/hundredrabbits/Themes` in the system's default browser.

---

## 19. Edge Cases and UX Quirks

### 19.1 Cannot close the last file

`CmdOrCtrl+W` does nothing when only one file is open. To remove the last file,
the user must either quit the app or use Force Close (which triggers quit when
only one file remains).

### 19.2 Tab without suggestion

Pressing Tab when there is no autocomplete suggestion inserts two non-breaking
spaces. This is an intentional choice — it provides consistent Tab behaviour
rather than silently doing nothing.

### 19.3 Synonym index reset

The synonym cycling index resets to 0 whenever the user presses Space or Enter.
This means the first Shift+Tab after typing a new word always starts from the
first synonym.

### 19.4 Autoindent at EOF

If the cursor is at the very start of the file (position 0), the autoindent
logic that scans backwards for the previous line's indentation walks off the
front of the string but is bounded at position 0 — no crash, no indent
inserted.

### 19.5 Find minimum length

`find:` requires at least 3 characters. Shorter queries produce no results and
the operator stays open. This is a hardcoded minimum (`q.length < 3`).

### 19.6 Replace minimum length

Both the search term and replacement in `replace:` must be at least 3
characters. Shorter terms are silently ignored.

### 19.7 External modification edge case

If a file is deleted externally while open, the next `has_changes()` call
encounters a read error, the page's path is set to null, and the watchdog
path skips the dialog. The file effectively becomes "Untitled" with unsaved
changes.

### 19.8 Save As creates duplicates

If Save As is used with a path different from the original, a new page is added
while the original page remains open. This means the file appears TWICE in the
navi — once as the original (with a `*` for unsaved changes if modified) and
once as the new saved-as file. This is likely a bug, not intentional design.

### 19.9 `#` in navi

The splash page's content begins with `# Welcome`, which is detected as a
marker and shown in the navi. This is intentional — it demonstrates the marker
feature.

### 19.10 Reader minimum

The reader requires 5 words minimum (`words.length < 5`), not 5 characters.
Single-character words separated by spaces count.

### 19.11 Non-breaking spaces on Tab

The two non-breaking spaces inserted by Tab when no suggestion is available are
unicode `\u00a0` characters, not regular spaces. They render as spaces but are
not word boundaries — the autocomplete logic treats the next character after
the cursor as a non-space for detection purposes.

### 19.12 Repeated file opening

Opening a file that is already open (by path) is silently skipped. The user
sees no feedback. This check uses exact path string matching.

### 19.13 UNCLEAR: Theme drag-drop interaction

The `events.js` file handler drops happen on `window`, and the `theme.js`
handler is also bound to `window`. Both fire. The file handler skips `.thm`
files but processes `.svg` files if their MIME type matches `text/*` (which it
won't for `.svg` — SVG files typically have MIME type `image/svg+xml`). So SVG
drops should be caught only by the theme handler and not cause a file to be
opened. However, if an SVG file's MIME type IS reported as text (unlikely but
possible), the file handler would try to open it as a text file AND the theme
handler would try to load it as a theme. The exact behaviour in that case is
UNCLEAR from the code.

### 19.14 UNCLEAR: `last_char` initialisation

`this.last_char` is initialised to `'s'` with a comment calling it "bad code."
It must be a length-1 string. It is set to `e.key` on every keydown and is used
nowhere else in the visible codebase. Its presence suggests a removed feature
or an unused remnant.

---

## 20. Keyboard Shortcut Reference

### 20.1 Global (all modes)

| Shortcut                | Action                           |
|-------------------------|----------------------------------|
| `CmdOrCtrl+,`           | About (opens GitHub)             |
| `CmdOrCtrl+Enter`       | Toggle fullscreen                |
| `CmdOrCtrl+H`           | Hide / minimise                  |
| `CmdOrCtrl+Backspace`   | Reset font + theme               |
| `CmdOrCtrl+Q`           | Quit (with unsaved check)        |

In modes (reader/operator/insert), the same shortcuts apply except where
overridden.

### 20.2 Default mode shortcuts

| Shortcut                | Action                           |
|-------------------------|----------------------------------|
| `CmdOrCtrl+N`           | New file                         |
| `CmdOrCtrl+O`           | Open file(s)                     |
| `CmdOrCtrl+S`           | Save                             |
| `CmdOrCtrl+Shift+S`     | Save As                          |
| `CmdOrCtrl+D`           | Discard changes                  |
| `CmdOrCtrl+W`           | Close file (with check)          |
| `CmdOrCtrl+Shift+W`     | Force close (no check)           |
| `CmdOrCtrl+Z`           | Undo                             |
| `CmdOrCtrl+Shift+Z`     | Redo                             |
| `CmdOrCtrl+X`           | Cut                              |
| `CmdOrCtrl+C`           | Copy                             |
| `CmdOrCtrl+V`           | Paste                            |
| `CmdOrCtrl+A`           | Select all                       |
| `CmdOrCtrl+Shift+Enter` | Add linebreak                    |
| `CmdOrCtrl+Shift+T`     | Toggle autoindent                |
| `Tab`                   | Autocomplete / insert two `\u00a0`|
| `Shift+Tab`             | Cycle synonym                    |
| `CmdOrCtrl+F`           | Find (opens operator)            |
| `CmdOrCtrl+Shift+F`     | Replace (opens operator)         |
| `CmdOrCtrl+G`           | Goto line (opens operator)       |
| `CmdOrCtrl+B`           | Open URL in browser              |
| `CmdOrCtrl+Shift+]`     | Next file                        |
| `CmdOrCtrl+Shift+[`     | Previous file                    |
| `CmdOrCtrl+]`           | Next marker                      |
| `CmdOrCtrl+[`           | Previous marker                  |
| `CmdOrCtrl+\`           | Toggle navigation sidebar        |
| `F11`                   | Toggle menubar visibility        |
| `CmdOrCtrl+Shift+,`     | Previous font                    |
| `CmdOrCtrl+Shift+.`     | Next font                        |
| `CmdOrCtrl+-`           | Decrease font size               |
| `CmdOrCtrl+=`           | Increase font size               |
| `CmdOrCtrl+0`           | Reset font size                  |
| `CmdOrCtrl+K`           | Start reader                     |
| `CmdOrCtrl+I`           | Enter insert mode                |
| `CmdOrCtrl+Shift+O`     | Open theme                       |
| `CmdOrCtrl+Shift+Backspace` | Reset theme                  |

### 20.3 Operator mode shortcuts

| Shortcut                | Action                           |
|-------------------------|----------------------------------|
| `Esc`                   | Stop operator                    |
| `CmdOrCtrl+F`           | Find (re-open)                   |
| `CmdOrCtrl+N`           | Find next                        |
| `Enter`                 | Execute command                  |
| `ArrowUp`               | Restore previous command         |

### 20.4 Reader mode shortcuts

| Shortcut                | Action                           |
|-------------------------|----------------------------------|
| `Esc`                   | Stop reader                      |

### 20.5 Insert mode shortcuts

| Shortcut                | Action                           |
|-------------------------|----------------------------------|
| `Esc`                   | Exit insert mode                 |
| `CmdOrCtrl+D`           | Insert date                      |
| `CmdOrCtrl+T`           | Insert time                      |
| `CmdOrCtrl+P`           | Insert file path                 |
| `CmdOrCtrl+H`           | Insert header (`# `)             |
| `CmdOrCtrl+Shift+H`     | Insert subheader (`## `)         |
| `CmdOrCtrl+/`           | Insert comment (`-- `)           |
| `CmdOrCtrl+L`           | Insert line separator            |
| `CmdOrCtrl+-`           | Insert list item (`- `)          |

