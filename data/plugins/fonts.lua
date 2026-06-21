-- mod-version:4 -- lite-xl 2.1
-- Font cycling plugin for Left XL
-- Cycles between mono (JetBrains Mono), sans-serif (Fira Sans), serif (Zilla Slab)
-- Shortcuts: Ctrl+Shift+, (prev), Ctrl+Shift+. (next)
--            Ctrl+= (+1px), Ctrl+- (-1px), Ctrl+0 (reset to 12px)

local core = require "core"
local command = require "core.command"
local config = require "core.config"
local keymap = require "core.keymap"
local style = require "core.style"

local font_opts = {antialiasing="grayscale", hinting="full"}

-- Font definitions: display name, filename
local font_specs = {
  { name = "mono",       file = "JetBrainsMono-Regular.ttf" },
  { name = "serif",      file = "serif.ttf" },
  { name = "sans_serif", file = "FiraSans-Regular.ttf" },
}

---@type { font_index: integer, font_size: integer }
local plugin_config = {}

---Default font size in pixels (Left's default)
local default_font_size = 12

---Line height = font_size + line_height_offset
local line_height_offset = 8

local function apply_font()
  local spec = font_specs[plugin_config.font_index]
  local size = plugin_config.font_size
  local path = DATADIR .. "/fonts/" .. spec.file
  style.code_font = renderer.font.load(path, size * SCALE, font_opts)
  -- Update line height: font_size + 8px (Left's formula)
  config.line_height = (size + line_height_offset) / size
  core.redraw = true
  -- Persist config
  config.plugins.fonts = {
    font_index = plugin_config.font_index,
    font_size = plugin_config.font_size,
  }
end

local function next_font()
  plugin_config.font_index = plugin_config.font_index % #font_specs + 1
  apply_font()
end

local function prev_font()
  plugin_config.font_index = (plugin_config.font_index - 2) % #font_specs + 1
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
  local saved = config.plugins.fonts or {}
  plugin_config.font_index = saved.font_index or 1      -- mono
  plugin_config.font_size = saved.font_size or default_font_size
  -- Apply saved/default font
  local spec = font_specs[plugin_config.font_index]
  local size = plugin_config.font_size
  local path = DATADIR .. "/fonts/" .. spec.file
  style.code_font = renderer.font.load(path, size * SCALE, font_opts)
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
