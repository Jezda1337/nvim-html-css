local utils = require "html-css.utils"
local cache = require "html-css.cache"

local fetcher = {}

---@param source string
---@param bufnr integer
---@param notify boolean
function fetcher:fetch(source, bufnr, notify)
    if utils.is_remote(source) then
        self:_fetch_remote(source, notify)
    elseif utils.is_local(source) then
        self:_fetch_local(source, bufnr, notify)
    end
end

---@param source string
---@param notify boolean
function fetcher:_fetch_remote(source, notify)
    if cache:has_source(source) then
        return
    end

    vim.system({ "curl", source }, { text = true }, function(out)
        if out.code ~= 0 then
            vim.schedule(function()
                vim.notify("Failt to fetch: " .. source, vim.log.levels.ERROR)
            end)
            return
        end

        if notify then
            vim.schedule(function()
                vim.notify("GET: " .. source, vim.log.levels.INFO)
            end)
        end

        local css_data = require "html-css.parsers.css".setup(out.stdout, false)
        cache:update(source, css_data)
    end)
end

---@param source string
---@param bufnr integer
---@param notify boolean
function fetcher:_fetch_local(source, bufnr, notify)
    if notify then
        vim.schedule(function()
            vim.notify("PARSED: " .. source, vim.log.levels.INFO)
        end)
    end

    utils.read_file(source, function(out)
        local css_data = require "html-css.parsers.css".setup(out, true)
        cache:update(source, css_data)

        if #css_data.imports > 0 then
            local base_dir = vim.fn.fnamemodify(source, ":h")
            self:_process_imports(css_data.imports, bufnr, notify, base_dir)
        end
    end)
end

---@param imports table<string>
---@param parent_path string
function fetcher:fetch_imports(imports, parent_path)
    local base_dir = vim.fn.fnamemodify(parent_path, ":h")
    for _, imp in pairs(imports) do
        local resolved = utils.resolve_path(imp, base_dir)
        if resolved then
            -- We pass nil as bufnr because this is a background update,
            -- not tied to a specific buffer opening event.
            self:fetch(resolved, nil, false)
        end
    end
end

---@param imports table<string>
---@param bufnr integer|nil
---@param notify boolean
function fetcher:_process_imports(imports, bufnr, notify, base_dir)
    local sources = {}

    for _, imp in pairs(imports) do
        local resolved = utils.resolve_path(imp, base_dir)
        if resolved then
            table.insert(sources, resolved)
            self:fetch(resolved, bufnr, notify)
        end
    end

    if bufnr then
        for src, _ in pairs(cache._buffers[bufnr]._sources or {}) do
            table.insert(sources, src)
        end

        cache:link_sources(bufnr, sources)
    end
end

return fetcher
