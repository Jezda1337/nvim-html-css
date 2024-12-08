local M = {}

local ts = vim.treesitter
local store = require("html-css.store")
local query = require("html-css.querys").internal_selectors
local cmp = require("cmp")

---@param bufnr number
M.init = function(bufnr, file_name)
	local selectors = store.get(bufnr, "selectors") or {
		classes = {},
		ids = {},
	}

	local global_stylings = store.get(999, "selectors") or { classes = {}, ids = {} }
	selectors = vim.tbl_deep_extend("force", selectors, global_stylings)

	local seen_classes = {}
	local seen_ids = {}

	-- Populate seen selectors to avoid duplicates
	for _, class in ipairs(selectors.classes) do
		seen_classes[class.label] = true
	end
	for _, id in ipairs(selectors.ids) do
		seen_ids[id.label] = true
	end

	local parser = ts.get_parser(bufnr, "css")
	local parse = parser:parse()
	local root = parse[1]:root()
	local qp = ts.query.parse("css", query)

	for _, match, _ in qp:iter_matches(root, bufnr, 0, -1, { all = true }) do
		for _, nodes in pairs(match) do
			for _, node in ipairs(nodes) do
				if node:type() == "id_name" then
					local val = ts.get_node_text(node, bufnr)
					if not seen_ids[val] then
						seen_ids[val] = true
						table.insert(selectors.ids, {
							label = val,
							kind = cmp.lsp.CompletionItemKind.Enum,
							source = file_name,
							provider = "Internal",
						})
					end
				elseif node:type() == "class_name" then
					local val = ts.get_node_text(node, bufnr)
					if not seen_classes[val] then
						seen_classes[val] = true
						table.insert(selectors.classes, {
							label = val,
							kind = cmp.lsp.CompletionItemKind.Enum,
							source = file_name,
							provider = "Internal",
						})
					end
				end
			end
		end
	end

	store.set(bufnr, "selectors", selectors)
end

return M
