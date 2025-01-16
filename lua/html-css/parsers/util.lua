local util = {}

---@type fun(file: string): string
util.get_file_name = function(file)
    return vim.fn.fnamemodify(file, ":t:r")
end

---@type fun(lang: string, qs: string, bufnr: integer): TSNode, vim.treesitter.Query
util.parse = function(lang, qs, bufnr)
    local ts = vim.treesitter

    local root = ts.get_parser(bufnr, lang):parse()[1]:root()
    local query = ts.query.parse(lang, qs)

    return root, query
end

---@type fun(url: string): boolean
util.is_link = function(url)
    local is_remote = "^https?://"
    return url:match(is_remote) ~= nil
end

---@type fun(url: string): boolean
util.is_local = function(url)
    return not util.is_link(url)
end

---@type fun(href_value: string): string | nil
util.provider_name = function(href_value)
    local filename = href_value:match("[^/]+%.css$") or href_value:match("[^/]+%.min%.css$")
    if filename then
        filename = filename:gsub("%.min%.css$", "")
        filename = filename:gsub("%.css$", "")
        filename = filename:gsub("^%l", string.upper)
        return filename
    end
    return nil
end

return util
