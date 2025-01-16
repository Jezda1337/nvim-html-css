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

return util
