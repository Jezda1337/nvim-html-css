local html = {}
local u = require("html-css.parsers.util")
local q = require("html-css.querys")
local ts = vim.treesitter
local s = require("html-css.store")

html.lang = "html"

---@type fun(bufnr: integer, style_sheets: table<string>)
html.parse = function(bufnr, style_sheets)
    local root, query = u.parse(html.lang, q.href, bufnr)

    local externals = {
        cdn = {},
        locals = {},
    }

    for _, source in ipairs(style_sheets) do
        table.insert(externals.cdn, {
            url = source,
            fetched = true,
            available = true,
            provider = u.provider_name(source),
        })
    end

    -- https://neovim.io/doc/user/treesitter.html#Query%3Aiter_matches()
    -- Query:iter_matches() correctly returns all matching nodes in a match instead of only the last node.
    -- This means that the returned table maps capture IDs to a list of nodes that need to be iterated over.
    -- For backwards compatibility, an option all=false (only return the last matching node) is provided that will be removed in a future release.
    for _, match, _ in query:iter_matches(root, 0, 0, -1, { all = true }) do
        for _, nodes in pairs(match) do
            for _, node in ipairs(nodes) do
                if node:type() == "attribute_value" then
                    local href_value = ts.get_node_text(node, 0)
                    if u.is_link(href_value) then
                        table.insert(externals.cdn, {
                            url = href_value,
                            fetched = false,
                            available = false,
                            provider = u.provider_name(href_value),
                        })
                    elseif u.is_local(href_value) then
                        table.insert(externals.locals, {
                            path = href_value,
                            fetched = false,
                            available = false,
                            file_name = u.get_file_name(href_value),
                            full_path = "",
                        })
                    end
                end
            end
        end
    end

    s.set(bufnr, "externals", externals)
end

return html
