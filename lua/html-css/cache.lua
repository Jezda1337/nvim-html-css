local utils = require "html-css.utils"

local cache = {
    _sources = {},
    _buffers = {},
    _watchers = {}
}

---@param bufnr integer
---@return Selector[]
function cache:get_classes(bufnr)
    -- exit early if buffer doesn't exist
    if not self._buffers[bufnr] then return {} end

    local buffer_sources = self._buffers[bufnr]._sources or {}
    local classes = {}

    for src in pairs(buffer_sources) do
        vim.list_extend(classes, self._sources[src].classes)
    end

    return classes
end

---@param bufnr integer
---@return Selector[]
function cache:get_ids(bufnr)
    local buffer_sources = self._buffers[bufnr]._sources or {}
    local ids = {}

    for src in pairs(buffer_sources) do
        vim.list_extend(ids, self._sources[src].ids)
    end

    return ids
end

---@param source string
---@param data CSS_Data
function cache:update(source, data)
    local resolved = utils.resolve_path(source)
    local now = os.time()

    local source_type = utils.is_remote(source) and "remote" or "local"

    self._sources[resolved] = {
        classes = {},
        ids = {},
        imports = {},
        meta = {
            path = resolved,
            mtime = now,
            type = source_type
        }
    }

    local function insert_items(items, target)
        for _, item in ipairs(items) do
            item.source_name = self._sources[resolved].meta.path
            item.source_type = source_type
            table.insert(target, item)
        end
    end

    insert_items(data.class, self._sources[resolved].classes)
    insert_items(data.id, self._sources[resolved].ids)

    for _, imp in pairs(data.imports) do
        local resolved_imp = utils.resolve_path(imp)
        table.insert(self._sources[resolved].imports, resolved_imp)
    end
end

---@param bufnr integer
---@param sources table<string>
function cache:link_sources(bufnr, sources)
    local resolved_sources = {}
    for _, src in pairs(sources) do
        local resolved = utils.resolve_path(src)
        resolved_sources[resolved] = true

        if self._sources[resolved] and self._sources[resolved].imports then
            for _, imp in pairs(self._sources[resolved].imports or {}) do
                resolved_sources[imp] = true
            end
        end

        if utils.is_local(resolved) and not self._watchers[resolved] and not resolved:match("buffer://") then
            vim.schedule(function()
                self:_setup_watchers(resolved)
            end)
        end
    end

    self._buffers[bufnr] = {
        _sources = resolved_sources
    }
end

---@param path string
function cache:_setup_watchers(path)
    if self._watchers[path] then return end
    local handler = vim.uv.new_fs_event()
    if not handler then return end --INFO attention needed
    self._watchers[path] = handler
    vim.uv.fs_event_start(handler, path, {}, function(err, fname, stats)
        vim.schedule(function()
            self:_handle_file_change(handler, path, err, fname, stats)
        end)
    end)
end

---@param handler uv.uv_fs_event_t
---@param path string
---@param err string | nil
---@param fname string
---@param stats table<string, boolean|nil>
function cache:_handle_file_change(handler, path, err, fname, stats)
    utils.read_file(path, function(out)
        local css_data = require "html-css.parsers.css".setup(out)
        self:update(path, css_data)
        for _, src in pairs(css_data.imports) do
            require "html-css.fetcher":fetch(src, 0, false)
        end
    end)

    -- Debounce: stop and restart the watcher
    handler:stop()
    handler:start(path, {}, vim.schedule_wrap(function()
        self:_handle_file_change(handler, path, err, fname, stats)
    end))
end

---@param source string
---@return boolean
function cache:has_source(source)
    return cache._sources[source] ~= nil
end

---@param bufnr integer
function cache:cleanup(bufnr)
    self._buffers[bufnr] = nil
end

return cache
