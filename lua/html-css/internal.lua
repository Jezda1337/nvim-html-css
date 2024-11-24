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

	local global_stylings = store.get(1, "selectors")
	selectors = vim.tbl_deep_extend("force", selectors, global_stylings)

	local parser = ts.get_parser(bufnr, "css")
	local parse = parser:parse()
	local root = parse[1]:root()
	local qp = ts.query.parse("css", query)
	for _, c, _ in qp:iter_matches(root, bufnr) do
		for _, node in pairs(c) do
			if node:type() == "id_name" then
				local val = ts.get_node_text(node, bufnr)
				if not selectors.ids[val] then
					table.insert(selectors.ids, {
						label = val,
						kind = cmp.lsp.CompletionItemKind.Enum,
						source = file_name,
						provider = "mom",
					})
				end
			elseif node:type() == "class_name" then
				local val = ts.get_node_text(node, bufnr)
				if not selectors.classes[val] then
					table.insert(selectors.classes, {
						label = val,
						kind = cmp.lsp.CompletionItemKind.Enum,
						source = file_name,
						provider = "mom",
					})
				end
			end
		end
	end

	store.set(bufnr, "selectors", selectors)
end

return M
