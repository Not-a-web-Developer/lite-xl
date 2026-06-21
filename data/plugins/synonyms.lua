-- mod-version:4 -- lite-xl 2.1
-- Synonym and autocomplete plugin for Left XL
-- Loads the synonym DB, builds a vocabulary from it + current document,
-- and provides Tab (autocomplete) and Shift+Tab (synonym cycling).
--
-- Tab: accept suggestion or insert two non-breaking spaces
-- Shift+Tab: cycle through synonyms; applied on Shift release

local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"
local config = require "core.config"

local synonyms_db = require "plugins.synonyms_db"

-- ============================================================================
-- Data
-- ============================================================================

local synonyms = synonyms_db

-- Startup diagnostic
if type(synonyms) == "table" then
  local count = 0
  for _ in pairs(synonyms) do count = count + 1 end
  core.log_quiet("synonyms: loaded %d entries, abandon=%s", count,
    type(synonyms["abandon"]) == "table" and tostring(#synonyms["abandon"]) .. " syns" or "MISSING")
else
  core.error("synonyms: DB failed to load (type=%s)", type(synonyms))
end

--- All known words (synonym DB root + synonyms + doc words)
---@type { [string]: boolean }
local vocabulary = {}

--- Plugin state (read by stats bar plugin)
local plugin_state = {
  suggestion = nil,         -- full autocomplete suggestion word
  suggestion_suffix = nil,  -- suffix to insert
  synonyms_list = nil,      -- {string} current synonym list
  synonym_index = 0,        -- current position (1-based)
  synonym_word = nil,       -- the word being replaced (original text)
}

local shift_held = false
local space_enter_seen = false

-- ============================================================================
-- Vocabulary
-- ============================================================================

local function build_base_vocabulary()
  vocabulary = {}
  for word, list in pairs(synonyms) do
    if #word >= 4 and word:match("^[a-zA-Z]+$") then
      vocabulary[word:lower()] = true
    end
    for _, syn in ipairs(list) do
      if #syn >= 4 and syn:match("^[a-zA-Z]+$") then
        vocabulary[syn:lower()] = true
      end
    end
  end
end

local function add_doc_words(doc)
  for _, line in ipairs(doc.lines) do
    for word in line:gmatch("[a-zA-Z]+") do
      if #word >= 4 then
        vocabulary[word:lower()] = true
      end
    end
  end
end

local function rebuild_vocabulary()
  build_base_vocabulary()
  for _, doc in ipairs(core.docs) do
    add_doc_words(doc)
  end
end

-- ============================================================================
-- Word detection
-- ============================================================================

--- Get the word under cursor. Returns word, start_col, end_col (1-based, inclusive)
local function get_word_at_cursor(doc)
  local line_num, col = doc:get_selection()
  local line = doc.lines[line_num]
  if not line then return nil end

  local before = line:sub(1, col - 1)
  local after = line:sub(col)

  -- Walk backwards to find word start
  local start_col = col
  for i = #before, 1, -1 do
    if before:sub(i, i):match("[a-zA-Z]") then
      start_col = i
    else
      break
    end
  end

  -- Walk forwards to find word end
  local end_col = col - 1
  for i = 1, #after do
    if after:sub(i, i):match("[a-zA-Z]") then
      end_col = col - 1 + i
    else
      break
    end
  end

  if start_col > end_col then return nil end

  local word = line:sub(start_col, end_col)
  if #word < 4 then return nil end

  return word, start_col, end_col
end

--- Check if cursor is at word end (for autocomplete)
local function is_cursor_at_word_end(doc)
  local line_num, col = doc:get_selection()
  local line = doc.lines[line_num]
  if not line then return false end
  local after = line:sub(col)
  return after:len() == 0 or not after:match("^[a-zA-Z]")
end

-- ============================================================================
-- Autocomplete
-- ============================================================================

local function find_suggestion(partial)
  partial = partial:lower()
  for word, _ in pairs(vocabulary) do
    if #word > #partial
    and word:sub(1, #partial) == partial then
      return word
    end
  end
  return nil
end

local function update_suggestion_state()
  plugin_state.suggestion = nil
  plugin_state.suggestion_suffix = nil

  local dv = core.active_view
  if not dv or not dv.doc then return end
  local doc = dv.doc
  if not is_cursor_at_word_end(doc) then return end

  local word = get_word_at_cursor(doc)
  if not word then return end

  local sug = find_suggestion(word)
  if sug and sug:lower() ~= word:lower() then
    plugin_state.suggestion = sug
    plugin_state.suggestion_suffix = sug:sub(#word + 1)
  end
end

-- ============================================================================
-- Synonyms
-- ============================================================================

local function update_synonym_state()
  plugin_state.synonyms_list = nil
  plugin_state.synonym_index = 0
  plugin_state.synonym_word = nil

  local dv = core.active_view
  if not dv or not dv.doc then return end
  local doc = dv.doc

  local word = get_word_at_cursor(doc)
  if not word then return end

  local lower = word:lower()
  local list = synonyms[lower]

  -- Try singular if plural (trailing 's')
  if not list and lower:sub(-1) == "s" then
    list = synonyms[lower:sub(1, -2)]
  end

  if list then
    plugin_state.synonyms_list = list
    plugin_state.synonym_word = word
  end
end

-- Track last cursor word to detect word changes (for Space/Enter reset)
local last_cursor_word = nil

local function reset_synonym_state()
  plugin_state.synonyms_list = nil
  plugin_state.synonym_index = 0
  plugin_state.synonym_word = nil
end

local function update_state()
  -- Detect word change: if the cursor word changed, reset synonym state
  -- (this handles Space, Enter, mouse clicks — any cursor movement that
  -- changes what word is under the cursor)
  local dv = core.active_view
  local current_word = nil
  if dv and dv.doc then
    current_word = get_word_at_cursor(dv.doc)
  end
  if current_word ~= last_cursor_word then
    last_cursor_word = current_word
    reset_synonym_state()
  end

  update_suggestion_state()
  update_synonym_state()
  core.redraw = true
end

-- ============================================================================
-- Commands
-- ============================================================================

local function autocomplete_accept()
  local dv = core.active_view
  if not dv or not dv.doc then return end
  local doc = dv.doc

  if plugin_state.suggestion and plugin_state.suggestion_suffix then
    -- Accept autocomplete suggestion: insert suffix + space
    doc:text_input(plugin_state.suggestion_suffix .. " ")
    reset_synonym_state()
    update_state()
    return
  end

  -- No suggestion: insert two non-breaking spaces
  doc:text_input("\u{00a0}\u{00a0}")
  update_state()
end

local function synonym_cycle()
  core.log_quiet("synonyms: cycle CALLED, list=%s, index=%d",
    plugin_state.synonyms_list and ("yes(%d)"):format(#plugin_state.synonyms_list) or "nil",
    plugin_state.synonym_index)
  if not plugin_state.synonyms_list then
    core.log_quiet("synonyms: cycle called but synonyms_list is nil")
    return
  end
  local n = #plugin_state.synonyms_list
  plugin_state.synonym_index = (plugin_state.synonym_index % n) + 1
  core.redraw = true
end

local function synonym_apply()
  if not plugin_state.synonyms_list or plugin_state.synonym_index == 0 then return end
  if not plugin_state.synonym_word then return end

  local dv = core.active_view
  if not dv or not dv.doc then return end
  local doc = dv.doc

  local replacement = plugin_state.synonyms_list[plugin_state.synonym_index]

  -- Preserve capitalisation of original word
  local original = plugin_state.synonym_word
  if original:sub(1, 1):match("[A-Z]") then
    replacement = replacement:sub(1, 1):upper() .. replacement:sub(2)
  end

  local word, word_start, word_end = get_word_at_cursor(doc)
  if not word then return end

  local line = doc:get_selection()
  doc:remove(line, word_start, line, word_end + 1)
  doc:insert(line, word_start, replacement)
  -- Move cursor past the replacement
  doc:set_selection(line, word_start + #replacement)

  reset_synonym_state()
  update_state()
end

-- ============================================================================
-- Event hooks (non-destructive chaining)
-- ============================================================================

-- Hook keypressed to track shift key
local orig_on_key_pressed = keymap.on_key_pressed
function keymap.on_key_pressed(k, ...)
  if k == "left shift" or k == "right shift" then
    shift_held = true
  end
  return orig_on_key_pressed(k, ...)
end

-- Hook keyreleased to detect shift release (synonym apply)
local orig_on_key_released = keymap.on_key_released
function keymap.on_key_released(k, ...)
  if (k == "left shift" or k == "right shift") and shift_held then
    shift_held = false
    if plugin_state.synonyms_list and plugin_state.synonym_index > 0 then
      synonym_apply()
    end
  end
  orig_on_key_released(k, ...)
end

-- Register commands
command.add(nil, {
  ["synonyms:accept"] = autocomplete_accept,
  ["synonyms:cycle"] = synonym_cycle,
})

-- Keybindings (appended, not overwriting)
-- Overwrite Tab and Shift+Tab (don't append — doc:indent would eat Tab)
-- Also bind "backtab" for Wayland which sends ISO_Left_Tab instead of shift+tab
keymap.add({
  ["tab"] = "synonyms:accept",
  ["shift+tab"] = "synonyms:cycle",
  ["backtab"] = "synonyms:cycle",
}, true)

-- Diagnostic: verify bindings
local ok, strokes = pcall(function()
  return {keymap.get_binding("synonyms:cycle")}
end)
core.log_quiet("synonyms: cycle bound to strokes: %s", table.concat(strokes or {"NONE"}, ", "))

-- ============================================================================
-- Initialisation
-- ============================================================================

build_base_vocabulary()

-- Periodically rebuild vocabulary from docs
core.add_thread(function()
  while true do
    coroutine.yield(3)
    rebuild_vocabulary()
  end
end)

-- Continuously update suggestion/synonym state as user types
core.add_thread(function()
  while true do
    coroutine.yield(0.15)
    update_state()
  end
end)

return {
  get_state = function() return plugin_state end,
}
