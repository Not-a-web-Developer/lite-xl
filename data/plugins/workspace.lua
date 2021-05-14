-- mod-version:1 -- lite-xl 1.16
local core = require "core"
local common = require "core.common"
local DocView = require "core.docview"


local function load_workspace_file()
  local load_f = loadfile(USERDIR .. PATHSEP .. "workspace.lua")
  return load_f and load_f()
end


local function has_no_locked_children(node)
  if node.locked then return false end
  if node.type == "leaf" then return true end
  return has_no_locked_children(node.a) and has_no_locked_children(node.b)
end


local function get_unlocked_root(node)
  if node.type == "leaf" then
    return not node.locked and node
  end
  if has_no_locked_children(node) then
    return node
  end
  return get_unlocked_root(node.a) or get_unlocked_root(node.b)
end


local function save_view(view)
  local mt = getmetatable(view)
  if mt == DocView then
    return {
      type = "doc",
      active = (core.active_view == view),
      filename = view.doc.filename,
      selection = { view.doc:get_selection() },
      scroll = { x = view.scroll.to.x, y = view.scroll.to.y },
      text = not view.doc.filename and view.doc:get_text(1, 1, math.huge, math.huge)
    }
  end
  for name, mod in pairs(package.loaded) do
    if mod == mt then
      return {
        type = "view",
        active = (core.active_view == view),
        module = name
      }
    end
  end
end


local function load_view(t)
  if t.type == "doc" then
    local ok, doc = pcall(core.open_doc, t.filename)
    if not ok then
      return DocView(core.open_doc())
    end
    local dv = DocView(doc)
    if t.text then doc:insert(1, 1, t.text) end
    doc:set_selection(table.unpack(t.selection))
    dv.last_line, dv.last_col = doc:get_selection()
    dv.scroll.x, dv.scroll.to.x = t.scroll.x, t.scroll.x
    dv.scroll.y, dv.scroll.to.y = t.scroll.y, t.scroll.y
    return dv
  end
  return require(t.module)()
end


local function save_node(node)
  local res = {}
  res.type = node.type
  if node.type == "leaf" then
    res.views = {}
    for _, view in ipairs(node.views) do
      local t = save_view(view)
      if t then
        table.insert(res.views, t)
        if node.active_view == view then
          res.active_view = #res.views
        end
      end
    end
  else
    res.divider = node.divider
    res.a = save_node(node.a)
    res.b = save_node(node.b)
  end
  return res
end


local function load_node(node, t)
  if t.type == "leaf" then
    local res
    for _, v in ipairs(t.views) do
      local view = load_view(v)
      if v.active then res = view end
      node:add_view(view)
    end
    if t.active_view then
      node:set_active_view(node.views[t.active_view])
    end
    return res
  else
    node:split(t.type == "hsplit" and "right" or "down")
    node.divider = t.divider
    local res1 = load_node(node.a, t.a)
    local res2 = load_node(node.b, t.b)
    return res1 or res2
  end
end


local function save_workspace()
  local root = get_unlocked_root(core.root_view.root_node)
  local workspace_filename = USERDIR .. PATHSEP .. "workspace.lua"
  local fp = io.open(workspace_filename, "w")
  if fp then
    local node_text = common.serialize(save_node(root))
    local topdir_entries = {}
    for i = 1, #core.project_entries do
      local entry = core.project_entries[i]
      if entry.item.topdir then
        table.insert(topdir_entries, {path = entry.name, type = entry.item.type})
      end
    end
    local project_entries_text = common.serialize(topdir_entries)
    fp:write(string.format("return { working_dir = %q, documents = %s, project_entries = %s }\n", core.working_dir, node_text, project_entries_text))
    fp:close()
  end
end


local function load_workspace()
  local workspace = load_workspace_file()
  if workspace then
    local root = get_unlocked_root(core.root_view.root_node)
    local active_view = load_node(root, workspace.documents)
    if active_view then
      core.set_active_view(active_view)
    end
    for _, entry in ipairs(workspace.project_entries) do
      if entry.type == "dir" then
        core.add_project_directory(entry.path)
      elseif entry.type == "dir" then
        core.add_project_dfile(entry.path)
      end
    end
    system.chdir(workspace.working_dir)
  end
end


local run = core.run

function core.run(...)
  if #core.docs == 0 then
    core.try(load_workspace)

    local on_quit_project = core.on_quit_project
    function core.on_quit_project()
      core.try(save_workspace)
      on_quit_project()
    end

    local on_enter_project = core.on_enter_project
    function core.on_enter_project(new_dir)
      on_enter_project(new_dir)
      core.try(load_workspace)
    end
  end

  core.run = run
  return core.run(...)
end
