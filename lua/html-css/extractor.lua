local M = {}

local ts = vim.treesitter
local q = require("html-css.querys")
local cmp = require("cmp")

---@type fun(provider: string): string | nil
local function provider_name(href_value)
	local filename = href_value:match("[^/]+%.css$") or href_value:match("[^/]+%.min%.css$")
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

---@type fun(global_srouces: [string]): Externals
M.href = function(global_sources)
  global_sources = global_sources or {}

	---@type Externals
	local externals = {
		cdn = {},
		locals = {},
	}

	for i, source in ipairs(global_sources) do
		table.insert(externals.cdn, {
			url = source,
			fetched = true,
			available = true,
			provider = provider_name(source),
		})
	end

	local parser = ts.get_parser(0, "html")
	local parse = parser:parse()
	local root = parse[1]:root()
	local qp = ts.query.parse("html", q.general_link_href)

	-- https://neovim.io/doc/user/treesitter.html#Query%3Aiter_matches()
	-- Query:iter_matches() correctly returns all matching nodes in a match instead of only the last node.
	-- This means that the returned table maps capture IDs to a list of nodes that need to be iterated over.
	-- For backwards compatibility, an option all=false (only return the last matching node) is provided that will be removed in a future release.
	for _, match, _ in qp:iter_matches(root, 0, 0, -1, { all = true }) do
		for id, nodes in pairs(match) do
			-- local name = qp.captures[id]
			for _, node in ipairs(nodes) do
				if node:type() == "attribute_value" then
					local href_value = ts.get_node_text(node, 0)
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
			end
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

	local parser = ts.get_string_parser(data, "css")
	local parse = parser:parse()
	local root = parse[1]:root()
	local query = ts.query.parse("css", q.selectors)

	for _, match, _ in query:iter_matches(root, data, 0, -1, { all = true }) do
		for id, nodes in pairs(match) do
			for _, node in ipairs(nodes) do
				local capture_name = query.captures[id]
				local name = ts.get_node_text(node, data)

				if capture_name == "id_name" then
					local block_node
					for match_id, match_nodes in pairs(match) do
						if query.captures[match_id] == "id_block" then
							block_node = match_nodes[1]
							break
						end
					end

					local block_text = ""
					if block_node then
						block_text = ts.get_node_text(block_node, data)
					end

					table.insert(selectors.ids, {
						label = name,
						block = block_text,
						kind = cmp.lsp.CompletionItemKind.Enum,
						source = source,
						provider = provider_name(source),
					})
				elseif capture_name == "class_name" then
					local block_node
					for match_id, match_nodes in pairs(match) do
						if query.captures[match_id] == "class_block" then
							block_node = match_nodes[1]
							break
						end
					end

					local block_text = ""
					if block_node then
						block_text = ts.get_node_text(block_node, data)
					end

					table.insert(selectors.classes, {
						label = name,
						block = block_text,
						kind = cmp.lsp.CompletionItemKind.Enum,
						source = source,
						provider = provider_name(source),
					})
				end
			end
		end
	end

	return selectors
end

return M
