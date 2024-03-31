local M = {}

local a = require("plenary.async")
local c = require("plenary.curl")
local u = require("html-css.utils.init")
local cmp = require("cmp")
local ts = vim.treesitter

---@type table<item>[]
local classes = {}

---@type string[]
local unique_class = {}

---@type string
local qs = [[
	(class_selector (class_name) @class-name)
]]

---@param url string
---@param cb function
---@async
local get_remote_styles = a.wrap(function(url, cb)
  c.get(url, {
    callback = function(res)
      cb(res.status, res.body)
    end,
    on_error = function(err)
      print("[html-css] Unable to connect to the URL:", url)
    end,
  })
end, 2)

---@param url string
---@param cb function
M.init = a.wrap(function(url, cb)
  if not url then
    return {}
  end

  get_remote_styles(url, function(status, body)
    ---@ type string
    local file_name = u.get_file_name(url, "[^/]+$")

    if not status == 200 then
      return {}
    end

    -- clean tables to avoid duplications
    classes = {}
    unique_class = {}

    local parser = ts.get_string_parser(body, "css", nil)
    local tree = parser:parse()[1]
    local root = tree:root()
    local query = ts.query.parse("css", qs)

    for _, matches, _ in query:iter_matches(root, body, 0, 0, {}) do
      local class = matches[1]
      local class_name = ts.get_node_text(class, body)
      table.insert(unique_class, class_name)
    end

    local unique_list = u.unique_list(unique_class)
    for _, class in ipairs(unique_list) do
      table.insert(classes, {
        label = class,
        kind = cmp.lsp.CompletionItemKind.Enum,
        menu = file_name,
      })
    end

    cb(classes)
  end)
end, 2)

return M
