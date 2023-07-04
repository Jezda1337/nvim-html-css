local M = {}
local a = require("plenary.async")
local c = require("plenary.curl")
local u = require("html-css.utils.init")
local cmp = require("cmp")
local ts = vim.treesitter

---@alias item {label:string, kind: string, menu: string}

---@type item[]
local classes = {}

---@type string
local qs = [[
	(class_selector (class_name) @class-name)
]]

-- (selectors . (class_selector . (class_name) @class-name))
-- (id_name) @id_name

---@param url string
---@param cb function
---@async
local get_remote_styles = a.wrap(function(url, cb)
	c.get(url, {
		callback = function(res)
			cb(res.status, res.body)
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
		if not status == 200 then
			return {}
		end
		classes = {} -- clean prev classes

		local parser = ts.get_string_parser(body, "css", nil)
		local tree = parser:parse()[1]
		local root = tree:root()
		local query = ts.query.parse("css", qs)
		local unique_class = {}
		for _, matches, _ in query:iter_matches(root, body) do
			local class = matches[1]
			local class_name = ts.get_node_text(class, body)
			table.insert(unique_class, class_name)
		end

		local test = u.unique_list(unique_class)
		for _, class in ipairs(test) do
			table.insert(classes, {
				label = class,
				kind = cmp.lsp.CompletionItemKind.Enum,
				menu = u.get_file_name(url, "[^/]+$"),
			})
		end

		cb(classes)
	end)
end, 2)

return M
