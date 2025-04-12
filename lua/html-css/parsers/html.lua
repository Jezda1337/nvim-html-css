local utils = require "html-css.parsers.utils"
local ts    = vim.treesitter

local html  = {}

-- -------------------------------------------------------------------------------------
-- FIXME part with the queries needs cleanup and better handling more languages (currently test with jsx/tsx/html/vue/astro)
-- only for tsx and jsx cannot be used html parser :/
-- FIXME the parser needs major refactoring
-- -------------------------------------------------------------------------------------

html.lang   = "html" -- this is no longer need since it must look for current language form the buffer

html.query  = html.html
html.html   = [[
((tag_name) @tag (#eq? @tag "link")
	  (attribute
		(attribute_name) @attr_name (#eq? @attr_name "href")
		(quoted_attribute_value
		  ((attribute_value) @href_value (#match? @href_value "\\.css$|\\.less$|\\.scss$|\\.sass$")))))

((raw_text)@rw)
]]

html.tsx    = [[
(import_statement
  (string (string_fragment) @import_value (#match? @import_value "\\.css$|\\.less$|\\.scss$|\\.sass$")))
]]

---@param bufnr integer
---@return HTML_Data
html.setup  = function(bufnr)
    -- -------------------------------------------------------------------------------------
    -- TODO this needs deep cleaning, from 0.11 we cannot use HTML parser for jsx/tsx files
    local lang = vim.treesitter.language.get_lang(vim.bo.filetype)
    html.lang = lang

    if lang == "tsx" or lang == "javascript" then
        html.query = html.tsx -- Use TSX-specific query for TSX and JavaScript
    else
        html.query = html.html -- Default to HTML query (this is used by astro/vue/html/svelte) and others
        html.lang = "html" -- Default to HTML language to be able to use query
    end
    -- -------------------------------------------------------------------------------------

    local root, query = utils.parse(html.lang, html.query, bufnr)

    local data = { cdn = {}, raw_text = "" }

    for _, match, _ in query:iter_matches(root, bufnr, 0, -1, { all = true }) do
        for id, nodes in pairs(match) do
            local name = query.captures[id]
            for _, node in ipairs(nodes) do
                if name == "href_value" then
                    table.insert(data.cdn, ts.get_node_text(node, bufnr))
                elseif name == "rw" then
                    data.raw_text = data.raw_text .. ts.get_node_text(node, bufnr)
                elseif name == "import_value" then
                    table.insert(data.cdn, ts.get_node_text(node, bufnr))
                end
            end
        end
    end

    return data
end

return html
