local utils = require("html-css.parsers.utils")
local ts = vim.treesitter
local html = {}

html.lang = "html"
html.query = [[
((tag_name) @tag (#eq? @tag "link")
	  (attribute
		(attribute_name) @attr_name (#eq? @attr_name "href")
		(quoted_attribute_value
		  ((attribute_value) @href_value (#match? @href_value "\\.css$|\\.less$|\\.scss$|\\.sass$")))))

((raw_text)@rw)
]]

---@type fun(bufnr: integer): { cdn: table, raw_text: string }
html.setup = function(bufnr)
	local root, query = utils.parse(html.lang, html.query, bufnr)

	local data = { cdn = {}, raw_text = "" }

	for _, match, _ in query:iter_matches(root, bufnr, 0, -1, { all = true }) do
		for id, nodes in pairs(match) do
			local name = query.captures[id]
			for _, node in ipairs(nodes) do
				if name == "href_value" then
					-- data.cdn = data.cdn .. ts.get_node_text(node, bufnr)
					table.insert(data.cdn, ts.get_node_text(node, bufnr))
				elseif name == "rw" then
					data.raw_text = data.raw_text .. ts.get_node_text(node, bufnr)
				end
			end
		end
	end

	return data
end

return html
