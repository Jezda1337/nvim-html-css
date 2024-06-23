local M = {}

local ts = vim.treesitter
local q = require("html-css.querys")
local cmp = require("cmp")
local store = require("html-css.store")

---@type fun(provider: string): string | nil
local function provider_name(href_value)
	local filename = href_value:match("[^/]+%.css$")
		or href_value:match("[^/]+%.min%.css$")
	if filename then
		filename = filename:gsub("%.min%.css$", "")
		filename = filename:gsub("%.css$", "")
		filename = filename:gsub("^%l", string.upper)
		return filename
	end
	return nil
end

local function file_name(href_value)
	return href_value
end

---@type fun(url: string): boolean
local function is_link(url)
	local is_remote = "^https?://"
	return url:match(is_remote) ~= nil
end

---@type fun(url: string): boolean
local function is_local(url)
	return not is_link(url)
end

---@type fun(): Externals
M.href = function()
	---@type Externals
	local externals = {
		cdn = {},
		locals = {},
	}

	local parser = ts.get_parser(0, "html")
	local parse = parser:parse()
	local root = parse[1]:root()
	local qp = ts.query.parse("html", q.general_link_href)
	for _, c, _ in qp:iter_matches(root, 0) do
		local href_value = ts.get_node_text(c[3], 0)
		if is_link(href_value) then
			table.insert(externals.cdn, {
				url = href_value,
				fetched = false,
				available = false,
				provider = provider_name(href_value),
			})
		elseif is_local(href_value) then
			table.insert(externals.locals, {
				path = href_value,
				fetched = false,
				available = false,
				file_name = file_name(href_value),
			})
		end
	end

	return externals
end

---@param data string
---@param source string
M.selectors = function(data, source)
	local selectors = {
		ids = {},
		classes = {},
	}
	local unique_selectors = {
		ids = {},
		classes = {},
	}

	local parser = ts.get_string_parser(data, "css")
	local tree = parser:parse()[1]
	local root = tree:root()

	local query = ts.query.parse("css", q.selectors)

	for _, matches, _ in query:iter_matches(root, data, 0, 0, {}) do
		for id, node in pairs(matches) do
			local capture_name = query.captures[id]
			local name = ts.get_node_text(node, data)

			if capture_name == "id_name" then
				unique_selectors.ids[name] = true
			elseif capture_name == "class_name" then
				unique_selectors.classes[name] = true
			end
		end
	end

	for id_name in pairs(unique_selectors.ids) do
		table.insert(selectors.ids, {
			label = id_name,
			kind = cmp.lsp.CompletionItemKind.Enum,
			source = source,
			provider = provider_name(source),
		})
	end

	for class_name in pairs(unique_selectors.classes) do
		table.insert(selectors.classes, {
			label = class_name,
			kind = cmp.lsp.CompletionItemKind.Enum,
			source = source,
			provider = provider_name(source),
		})
	end

	return selectors
end

return M
