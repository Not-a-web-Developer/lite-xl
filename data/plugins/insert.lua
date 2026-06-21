-- mod-version:4 -- lite-xl 2.1
-- Insert mode plugin for Left XL
-- Ctrl+I enters insert mode. Esc or any insert shortcut exits.
-- Stats bar shows help text while active.

local core = require "core"
local command = require "core.command"
local config = require "core.config"
local keymap = require "core.keymap"

local insert_mode = false

--- Month names for date formatting (Left's format: DD-Mon-YYYY)
local months = {
  "Jan", "Feb", "Mar", "Apr", "May", "Jun",
  "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
}

local function active_doc()
  return core.active_view.doc
end

--- Get the current line and column from the active docview
local function get_cursor(dv)
  return dv.doc:get_selection()
end

--- Insert text at cursor position, handling selections
local function insert_text(dv, text)
  dv.doc:text_input(text)
end

--- Smart prefix insertion: if cursor is at start of a new line, insert at cursor;
--- if text is selected across multiple lines, prefix each line;
--- otherwise, insert at start of current line.
local function insert_prefix(dv, prefix)
  local doc = dv.doc
  local has_sel = doc:has_selection()

  if not has_sel then
    local line, col = doc:get_selection()
    -- If cursor is at the very start of a line (col 1, or previous char is newline)
    if col == 1 then
      -- Insert at cursor
      doc:text_input(prefix)
    else
      -- Insert at start of current line
      doc:insert(line, 1, prefix)
    end
    return
  end

  -- Text is selected: prefix each selected line
  local line1, _, line2, _ = doc:get_selection(true)
  -- Iterate from bottom to top to preserve line numbers
  for l = line2, line1, -1 do
    doc:insert(l, 1, prefix)
  end
end

local function insert_date(dv)
  local t = os.date("*t")
  local day = string.format("%02d", t.day)
  local mon = months[t.month]
  local year = t.year
  insert_text(dv, string.format("%s-%s-%s ", day, mon, year))
end

local function insert_time(dv)
  insert_text(dv, os.date("%X "))
end

local function insert_path(dv)
  local doc = dv.doc
  if doc.filename then
    insert_text(dv, doc.filename .. " ")
  end
end

local function insert_header(dv)
  insert_prefix(dv, "# ")
end

local function insert_subheader(dv)
  insert_prefix(dv, "## ")
end

local function insert_comment(dv)
  insert_prefix(dv, "-- ")
end

local function insert_line(dv)
  local doc = dv.doc
  _, col = doc:get_selection()
  local text = "\n===================== \n"
  if col > 1 then
    -- If not at start of line, add an extra newline before
    text = "\n" .. text
  end
  doc:text_input(text)
end

local function insert_list(dv)
  insert_prefix(dv, "- ")
end

--- Enter insert mode
local function enter()
  insert_mode = true
  core.redraw = true
end

--- Exit insert mode
local function exit_mode()
  insert_mode = false
  core.redraw = true
end

--- Wrap an insert function to auto-exit insert mode after execution
local function insert_then_exit(fn)
  return function()
    local dv = core.active_view
    -- Only work in docview
    if not dv or not dv.doc then return end
    fn(dv)
    exit_mode()
  end
end

--- Predicate: only allow insert commands when in insert mode
local function when_in_insert_mode()
  return insert_mode
end

--- Register the "enter insert mode" command (available from default mode)
command.add(nil, {
  ["insert:enter"] = enter,
})

--- Register insert action commands (only available in insert mode)
command.add(when_in_insert_mode, {
  ["insert:date"] = insert_then_exit(insert_date),
  ["insert:time"] = insert_then_exit(insert_time),
  ["insert:path"] = insert_then_exit(insert_path),
  ["insert:header"] = insert_then_exit(insert_header),
  ["insert:subheader"] = insert_then_exit(insert_subheader),
  ["insert:comment"] = insert_then_exit(insert_comment),
  ["insert:line"] = insert_then_exit(insert_line),
  ["insert:list"] = insert_then_exit(insert_list),
  ["insert:exit"] = exit_mode,
})

--- Keybindings
keymap.add {
  ["ctrl+i"] = "insert:enter",
}

keymap.add {
  ["ctrl+d"] = "insert:date",
  ["ctrl+t"] = "insert:time",
  ["ctrl+p"] = "insert:path",
  ["ctrl+h"] = "insert:header",
  ["ctrl+shift+h"] = "insert:subheader",
  ["ctrl+/"] = "insert:comment",
  ["ctrl+l"] = "insert:line",
  ["ctrl+-"] = "insert:list",
  -- Escape exits insert mode (predicate ensures only in insert mode)
  ["escape"] = "insert:exit",
}

return {
  is_active = function() return insert_mode end,
}
