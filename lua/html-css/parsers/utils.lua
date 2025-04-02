local utils = {}

-- TODO string_parser should not be changed no 0.11 changes to the string parser
-- rest need some cleanup

---@type fun(lang: string, qs: string, bufnr: integer): TSNode, vim.treesitter.Query
utils.parse = function(lang, qs, bufnr)
    local ts = vim.treesitter

    local p = ts.get_parser(bufnr, lang)
    p:parse() -- this is needed since 0.11

    local root = p:trees()[1]:root()
    local query = ts.query.parse(lang, qs)

    return root, query
end

---@type fun(lang: string, qs: string, s: string): TSNode, vim.treesitter.Query
utils.string_parse = function(lang, qs, s)
    local ts = vim.treesitter

    local root = ts.get_string_parser(s, lang):parse()[1]:root()
    local query = ts.query.parse(lang, qs)

    return root, query
end

return utils
