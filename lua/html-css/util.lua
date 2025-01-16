local util = {}

---@type fun(file: string):string
util.get_file_name = function(file)
    return vim.fn.fnamemodify(file, ":t:r")
end

---@type fun(url: string, opts: table, cb: fun(ctx: any)):any
util.fetcher = function(url, opts, cb)
    opts = opts or {
        text = true,
    }
    local function on_exit(ctx)
        if cb then
            cb(ctx)
        end
    end
    -- this runs asynchronously
    vim.system({ "curl", url }, opts, on_exit)
end

---@type fun(t: table, v:any): boolean
util.contains = function(t, v)
    for _, k in ipairs(t) do
        if k == v then
            return true
        end
    end
    return false
end

---@type fun():boolean
util.is_special_buffer = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
    if buftype ~= "" then
        return true
    end
    return false
end

---@type fun(langs: table<string>):boolean
util.is_lang_enabled = function(langs)
    langs = langs or {}
    local lang = vim.fn.expand("%:t:e")

    for _, v in ipairs(langs) do
        if v == lang then
            return true
        end
    end
    return false
end

return util
