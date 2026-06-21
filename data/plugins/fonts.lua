-- mod-version:4 -- lite-xl 2.1
-- Font cycling plugin for Left XL
-- Cycles between mono (JetBrains Mono), sans-serif (Fira Sans), serif (Zilla Slab)
-- Shortcuts: Ctrl+Shift+, (prev), Ctrl+Shift+. (next)
-- Uses lite-xl's default font size, line height, and rendering settings.

local core = require "core"
local command = require "core.command"
local config = require "core.config"
local keymap = require "core.keymap"
local style = require "core.style"

-- Font definitions
local font_specs = {
  { name = "mono",       file = "JetBrainsMono-Regular.ttf" },
  { name = "serif",      file = "serif.ttf" },
  { name = "sans_serif", file = "FiraSans-Regular.ttf" },
}

local plugin_config = {}

local function apply_font()
  local spec = font_specs[plugin_config.font_index]
  local size = style.code_font:get_height() -- preserve current size
  local path = DATADIR .. "/fonts/" .. spec.file
  style.code_font = renderer.font.load(path, size)
  core.redraw = true
  config.plugins.fonts = {
    font_index = plugin_config.font_index,
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

-- Load saved config, or use defaults
do
  local saved = config.plugins.fonts or {}
  plugin_config.font_index = saved.font_index or 1

  -- Apply on startup if not default (lite-xl's style.lua already set the default)
  if plugin_config.font_index ~= 1 then
    local spec = font_specs[plugin_config.font_index]
    local size = style.code_font:get_height()
    local path = DATADIR .. "/fonts/" .. spec.file
    style.code_font = renderer.font.load(path, size)
  end
end

keymap.add {
  ["ctrl+shift+,"] = "fonts:previous",
  ["ctrl+shift+."] = "fonts:next",
}

command.add(nil, {
  ["fonts:next"] = next_font,
  ["fonts:previous"] = prev_font,
})
