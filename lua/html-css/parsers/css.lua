local utils = require "html-css.parsers.utils"
local css = {}
local ts = vim.treesitter

css.lang = "css"
css.query = [[(class_selector
  (class_name) @class_name)
(#not-has-ancestor? @class_name "media_statement")

; 2. Extract all IDs anywhere
(id_selector
  (id_name) @id_name)
(#not-has-ancestor? @id_name "media_statement")

; 3. Extract imports (kept as is)
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

---@param node TSNode
---@return string
local function get_rule_block_text(node, source)
    local current = node
    while current do
        if current:type() == "rule_set" then
            for child in current:iter_children() do
                if child:type() == "block" then
                    return ts.get_node_text(child, source)
                end
            end
        end
        current = current:parent()
    end
    return ""
end

css.setup = function(stdout, withLocation)
    local root, query = utils.string_parse(css.lang, css.query, stdout)
    ---@type CSS_Data
    local css_data = {
        imports = {},
        class = {},
        id = {},
    }

    local seen_classes = {}
    local seen_ids = {}

    for id, node, _ in query:iter_captures(root, stdout, 0, -1) do
        local name = query.captures[id]
        local start_row, start_col, end_row, end_col = node:range()
        local text = ts.get_node_text(node, stdout)

        if name == "class_name" and not seen_classes[text] then
            seen_classes[text] = true
            table.insert(css_data.class, {
                type = "class",
                label = text,
                block = get_rule_block_text(node, stdout),
                kind = 13,
                range = withLocation and {
                    start = { line = start_row, character = start_col },
                    ["end"] = { line = end_row, character = end_col }
                } or nil
            })
        end

        if name == "id_name" and not seen_ids[text] then
            seen_ids[text] = true
            table.insert(css_data.id, {
                type = "id",
                label = text,
                block = get_rule_block_text(node, stdout),
                kind = 13,
                range = withLocation and {
                    start = { line = start_row, character = start_col },
                    ["end"] = { line = end_row, character = end_col }
                } or nil
            })
        end

        if name == "value" then
            table.insert(css_data.imports, text)
        end
    end

    return css_data
end

return css
