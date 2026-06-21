-- mod-version:4 -- lite-xl 2.1
-- Font cycling plugin for Left XL
-- Bundles three fonts: mono (default), serif, sans-serif
-- Shortcuts: Ctrl+Shift+, (prev), Ctrl+Shift+. (next)
--            Ctrl+= (+1px), Ctrl+- (-1px), Ctrl+0 (reset to 12px)

local core = require "core"
local command = require "core.command"
local config = require "core.config"
local keymap = require "core.keymap"
local style = require "core.style"

---@type renderer.font[]
local fonts = {}

local font_names = { "mono", "serif", "sans_serif" }

---@type { font_index: integer, font_size: integer }
local plugin_config = {}

---Default font size in pixels (Left's default)
local default_font_size = 12

---Line height = font_size + line_height_offset
local line_height_offset = 8

local function load_fonts()
  for _, name in ipairs(font_names) do
    local path = DATADIR .. "/fonts/" .. name .. ".ttf"
    fonts[name] = renderer.font.load(path, default_font_size * SCALE)
  end
end

local function save_config()
  config.plugins.fonts = {
    font_index = plugin_config.font_index,
    font_size = plugin_config.font_size,
  }
end

local function apply_font()
  local name = font_names[plugin_config.font_index]
  local size = plugin_config.font_size
  -- Reload the font at the current size
  local path = DATADIR .. "/fonts/" .. name .. ".ttf"
  style.code_font = renderer.font.load(path, size * SCALE)
  -- Update line height: font_size + 8px (Left's formula)
  config.line_height = (size + line_height_offset) / size
  core.redraw = true
  save_config()
end

local function next_font()
  plugin_config.font_index = plugin_config.font_index % #font_names + 1
  apply_font()
end

local function prev_font()
  plugin_config.font_index = (plugin_config.font_index - 2) % #font_names + 1
  apply_font()
end

local function increase_size()
  plugin_config.font_size = plugin_config.font_size + 1
  apply_font()
end

local function decrease_size()
  if plugin_config.font_size > 1 then
    plugin_config.font_size = plugin_config.font_size - 1
    apply_font()
  end
end

local function reset_size()
  plugin_config.font_size = default_font_size
  apply_font()
end

-- Load saved config, or use defaults
do
  load_fonts()

  local saved = config.plugins.fonts or {}
  plugin_config.font_index = saved.font_index or 1      -- mono
  plugin_config.font_size = saved.font_size or default_font_size
  -- Apply saved/default font
  local name = font_names[plugin_config.font_index]
  local size = plugin_config.font_size
  local path = DATADIR .. "/fonts/" .. name .. ".ttf"
  style.code_font = renderer.font.load(path, size * SCALE)
  config.line_height = (size + line_height_offset) / size
end

keymap.add {
  ["ctrl+shift+,"] = "fonts:previous",
  ["ctrl+shift+."] = "fonts:next",
  ["ctrl+="] = "fonts:increase-size",
  ["ctrl+-"] = "fonts:decrease-size",
  ["ctrl+0"] = "fonts:reset-size",
}

command.add(nil, {
  ["fonts:next"] = next_font,
  ["fonts:previous"] = prev_font,
  ["fonts:increase-size"] = increase_size,
  ["fonts:decrease-size"] = decrease_size,
  ["fonts:reset-size"] = reset_size,
})
