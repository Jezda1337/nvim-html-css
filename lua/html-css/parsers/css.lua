local utils = require("html-css.parsers.utils")
local css = {}
local ts = vim.treesitter

css.lang = "css"
css.query = [[
((rule_set
	 (selectors
		 (class_selector
			 (class_name) @class_name)
		 ) @class_decl
	 (#lua-match? @class_decl "^[.][a-zA-Z0-9_-]+$")
	 (#not-has-ancestor? @class_decl "media_statement")
	 (block) @class_block
	 ))

 ((rule_set
	 (selectors
		 (id_selector
			 (id_name) @id_name)
		 ) @id_decl
	 (#lua-match? @id_decl "^#[a-zA-Z0-9_-]+")
	 (#not-has-ancestor? @id_decl "media_statement")
	 (block) @id_block
	 ))

((stylesheet
   (import_statement
	 (string_value) @value)))
((stylesheet
   (import_statement
	 (call_expression
	   (function_name)
	   (arguments
		 (string_value)@value)))))
]]

---@type fun(stdout: string): { class: table<any>, id: table<any> }
css.setup = function(stdout)
	local root, query = utils.string_parse(css.lang, css.query, stdout)

	local selectors = {
		class = {},
		id = {},
		imports = {}
	}

	for _, match, _ in query:iter_matches(root, stdout, 0, -1, { all = true }) do
		for id, nodes in pairs(match) do
			local name = query.captures[id]
			for _, node in ipairs(nodes) do
				if name == "class_name" then
					table.insert(selectors.class, {
						label = ts.get_node_text(node, stdout),
						block = ts.get_node_text(match[3][1], stdout),
						kind = 13,
					})
				end
				if name == "id_name" then
					table.insert(selectors.id, {
						label = ts.get_node_text(node, stdout),
						block = ts.get_node_text(match[6][1], stdout),
						kind = 13,
					})
				end
				if name == "value" then
					table.insert(selectors.imports, {
						source
					})
				end
			end
		end
	end

	return selectors
end

return css
