local M = {}

local ts = vim.treesitter
local q = require("html-css.querys")
local cmp = require("cmp")

---@type fun(provider: string): string
local function provider_name(provider)
	local pattern = "[^/]+$"
	return provider:match(pattern)
end

---@param url string
---@return string
local function is_link(url)
	local is_remote = "^https?://"
	return url:match(is_remote)
end

---@return Link[]
M.href = function()
	---@type Link[]
	local links = {}

	local parser = ts.get_parser(0, "html")
	local parse = parser:parse()
	local root = parse[1]:root()
	local qp = ts.query.parse("html", q.general_link_href)
	for _, c, _ in qp:iter_matches(root, 0) do
		local url = ts.get_node_text(c[3], 0)
		if is_link(url) then
			table.insert(links, {
				url = url,
				fetched = false,
				provider = M.provider_name(url),
			})
		end
	end

	return links
end

---@param data string
M.selectors = function(data)
	local selectors = {
		ids = {},
		classes = {},
	}
	local unique_classes = {}
	local unique_ids = {}

	local parser = ts.get_string_parser(data, "css")
	local tree = parser:parse()[1]
	local root = tree:root()

	local query = ts.query.parse("css", q.selectors)

	for _, matches, _ in query:iter_matches(root, data, 0, 0, {}) do
		for id, node in pairs(matches) do
			local capture_name = query.captures[id]
			local name = ts.get_node_text(node, data)

			if capture_name == "id_name" then
				unique_ids[name] = true
			elseif capture_name == "class_name" then
				unique_classes[name] = true
			end
		end
	end

	for id_name in pairs(unique_ids) do
		table.insert(selectors.ids, {
			label = id_name,
			kind = cmp.lsp.CompletionItemKind.Enum,
		})
	end

	for class_name in pairs(unique_classes) do
		table.insert(selectors.classes, {
			label = class_name,
			kind = cmp.lsp.CompletionItemKind.Enum,
		})
	end

	return selectors
end

return M
