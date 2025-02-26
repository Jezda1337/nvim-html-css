local uv = vim.uv
local utils = require "html-css.utils"

local cache = {
	_sources = {},
	_dependencies = {},
	_buffers = {},
	_watchers = {}
}

function cache:add_dependency(parent, child)
	local resolved_parent = utils.resolve_path(parent)
	local resolved_child = utils.resolve_path(child)
	self._dependencies[resolved_parent] = self._dependencies[resolved_parent] or {}
	self._dependencies[resolved_parent][resolved_child] = true
end

function cache:get_dependencies(source)
	return self._dependencies[utils.resolve_path(source)] or {}
end

function cache:cleanup_dependencies(bufnr)
	local current_sources = self._buffers[bufnr] and self._buffers[bufnr].sources or {}
	local keep_deps = {}

	-- Find dependencies still needed
	for src in pairs(current_sources) do
		for dep in pairs(self:get_dependencies(src)) do
			keep_deps[dep] = true
		end
	end

	-- Remove orphaned dependencies
	local final_sources = {}
	for src in pairs(current_sources) do
		if keep_deps[src] or self._dependencies[src] then
			final_sources[src] = true
		end
	end

	self._buffers[bufnr].sources = final_sources
end

function cache:update(source, data)
	local resolved = utils.resolve_path(source)
	local now = os.time()

	local source_type = utils.is_remote(resolved) and "remote" or "file"

	self._sources[resolved] = {
		classes = {},
		ids = {},
		meta = {
			name = utils.get_source_name(resolved),
			path = resolved,
			mtime = now,
			type = source_type
		}
	}

	local function insert_items(items, target)
		for _, item in ipairs(items) do
			item.source_name = self._sources[resolved].meta.name
			item.source_type = source_type
			table.insert(target, item)
		end
	end

	insert_items(data.class or {}, self._sources[resolved].classes)
	insert_items(data.id or {}, self._sources[resolved].ids)
end

function cache:link_buffers(bufnr, sources)
	local expanded_sources = {}

	local function expand_deps(src)
		if expanded_sources[src] then return end
		expanded_sources[src] = true

		for dep in pairs(self:get_dependencies(src)) do
			expand_deps(dep)
		end
	end

	for _, src in pairs(sources) do
		local resolved = utils.resolve_path(src)
		expand_deps(resolved)
	end

	self._buffers[bufnr] = {
		sources = expanded_sources,
		path = vim.api.nvim_buf_get_name(bufnr)
	}
end

function cache:_setup_watcher(path)
	local handle = uv.new_fs_event()
	if not handle then return end -- needs attention
	uv.fs_event_start(handle, path, {}, function()
		self:_handle_file_change(path)
	end)
end

function cache:_handle_file_change(path)
	local content = utils.read_file_sync(path)
	if content then
		local data = require "html-css.parsers.css".setup(content)
		self:update(path, data)
	end
end

---@param bufnr integer
function cache:_get_classes(bufnr)
	local buffer_sources = self._buffers[bufnr].sources or {}
	local classes = {}

	for source, _ in pairs(buffer_sources) do
		local source_data = self._sources[source]
		if source_data then
			for _, cls in pairs(source_data.classes) do
				cls.source_name = source_data.meta.name
				cls.source_path = source_data.meta.path
				table.insert(classes, cls)
			end
		end
	end

	return classes
end

return cache
