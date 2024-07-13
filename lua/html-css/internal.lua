local M = {}

local ts = vim.treesitter
local ts_query = require("nvim-treesitter.query")
local store = require("html-css.store")
local query = require("html-css.querys").internal_selectors
local cmp = require("cmp")

---@param bufnr number
M.init = function(bufnr, file_name)
	local selectors = store.get(bufnr, "selectors")
		or {
			classes = {},
			ids = {},
		}

	local unique_selectors = {
		ids = {},
		classes = {},
	}

	local parser = ts.get_parser(bufnr, "css")
	local parse = parser:parse()
	local root = parse[1]:root()
	local qp = ts.query.parse("css", query)
	for _, c, _ in qp:iter_matches(root, bufnr) do
		for _, node in pairs(c) do
			if node:type() == "id_name" then
				local val = ts.get_node_text(node, bufnr)
				unique_selectors.ids[val] = true
			elseif node:type() == "class_name" then
				local val = ts.get_node_text(node, bufnr)
				unique_selectors.classes[val] = true
			end
		end
	end

	-- Function to check for duplicates before adding
	local function add_unique(target_table, unique_values, kind)
		local existing_values = {}
		for _, item in ipairs(target_table) do
			existing_values[item.label] = true
		end

		for value in pairs(unique_values) do
			if not existing_values[value] then
				table.insert(target_table, {
					label = value,
					kind = kind,
					source = file_name,
					provider = "mom",
				})
			end
		end
	end

	add_unique(
		selectors.ids,
		unique_selectors.ids,
		cmp.lsp.CompletionItemKind.Enum
	)
	add_unique(
		selectors.classes,
		unique_selectors.classes,
		cmp.lsp.CompletionItemKind.Enum
	)

	store.set(bufnr, "selectors", selectors)
end

return M
