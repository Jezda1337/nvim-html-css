local utils = require "html-css.parsers.utils"
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
	 (string_value
		(_) @value)
        (#not-lua-match? @value "^tailwind")
        (#not-lua-match? @value "^tw%-")
)))
((stylesheet
   (import_statement
	 (call_expression
	   (function_name)
	   (arguments
		 (string_value
			(_)@value)
        (#not-lua-match? @value "^tailwind")
        (#not-lua-match? @value "^tw%-")
)))))
]]

---@param stdout string
---@param withLocation boolean Flag for ignoring remote styles
---@return CSS_Data
css.setup = function(stdout, withLocation)
    local root, query = utils.string_parse(css.lang, css.query, stdout)
    ---@type CSS_Data
    local css_data = {
        imports = {},
        class = {},
        id = {},
    }

    for _, match, _ in query:iter_matches(root, stdout, 0, -1, { all = true }) do
        for id, nodes in pairs(match) do
            local name = query.captures[id]
            for _, node in ipairs(nodes) do
                local start_row, start_col, end_row, end_col = node:range()
                if name == "class_name" then
                    table.insert(css_data.class, {
                        type = "class",
                        label = ts.get_node_text(node, stdout),
                        block = ts.get_node_text(match[3][1], stdout),
                        kind = 13,
                        range = withLocation and {
                            start = { line = start_row, character = start_col },
                            ["end"] = { line = end_row, character = end_col }
                        } or nil
                    })
                end
                if name == "id_name" then
                    table.insert(css_data.id, {
                        type = "id",
                        label = ts.get_node_text(node, stdout),
                        block = ts.get_node_text(match[6][1], stdout),
                        kind = 13,
                        range = withLocation and {
                            start = { line = start_row, character = start_col },
                            ["end"] = { line = end_row, character = end_col }
                        } or nil
                    })
                end
                if name == "value" then
                    table.insert(css_data.imports, ts.get_node_text(node, stdout))
                end
            end
        end
    end

    return css_data
end

return css
