local uv = vim.uv
local utils = require "html-css.utils"

local cache = {
	_sources = {},
	_dependencies = {},
	_buffers = {},
	_watchers = {},

	_version = 0
}

function cache:add_dependency(parent, child)
	local resolved_parent = utils.resolve_path(parent)
	local resolved_child = utils.resolve_path(child)

	self._dependencies[resolved_parent] = self._dependencies[resolved_parent] or {}
	self._dependencies[resolved_parent][resolved_child] = true
end

function cache:get_dependents(source)
	local resolved = utils.resolve_path(source)
	local dependents = {}

	for parent, children in pairs(self._dependencies) do
		if children[resolved] then
			table.insert(dependents, parent)
		end
	end

	return dependents
end

function cache:_add_dependencies(source, resolved_new)
	local dependencies = self._dependencies[utils.resolve_path(source)] or {}
	for dep in pairs(dependencies) do
		if not resolved_new[dep] then
			resolved_new[dep] = true
			self:_add_dependencies(dep, resolved_new) -- Recursive for nested deps
		end
	end
end

---@param source string
---@param data table<any>
function cache:update(source, data)
	local resolved = utils.resolve_path(source)
	local now = os.time()

	self._sources[resolved] = {
		classes = {},
		ids = {},
		meta = {
			name = utils.get_source_name(source),
			path = resolved,
			mtime = utils.is_remote(source) and now or now,
			type = utils.is_remote(source) and "remote" or "local"
		}
	}

	local function insert_items(items, target)
		for _, item in ipairs(items) do
			table.insert(target, {
				label = item.label,
				block = item.block,
				kind = item.kind
			})
		end
	end

	insert_items(data.class or {}, self._sources[resolved].classes)
	insert_items(data.id or {}, self._sources[resolved].ids)

	self._version = self._version + 1
end

---@param bufnr integer
---@param new_sources table<string>
function cache:link_buffer(bufnr, new_sources)
	local resolved_new = {}
	-- Resolve all new sources
	for _, src in ipairs(new_sources) do
		resolved_new[utils.resolve_path(src)] = true
	end

	-- Get previous state
	local previous = self._buffers[bufnr] or { sources = {}, version = 0 }
	local current_sources = vim.deepcopy(previous.sources)

	-- Diff old and new sources
	local added = {}
	local removed = {}

	-- Find added sources
	for src in pairs(resolved_new) do
		if not current_sources[src] then
			added[src] = true
			current_sources[src] = true
		end
	end

	-- Find removed sources
	for src in pairs(previous.sources) do
		if not resolved_new[src] then
			removed[src] = true
			current_sources[src] = nil
		end
	end

	-- Process dependencies for added sources
	for src in pairs(added) do
		self:_add_dependencies(src, current_sources)
	end

	-- Process reverse dependencies for removed sources
	for src in pairs(removed) do
		self:_remove_dependencies(src, current_sources)
	end

	-- Update buffer state
	self._buffers[bufnr] = {
		sources = current_sources,
		version = self._version + 1
	}
	self._version = self._version + 1

	-- Setup watchers for new local sources
	for src in pairs(added) do
		if utils.is_local(src) and not self._watchers[src] then
			self:_setup_watcher(src)
		end
	end
end

function cache:_remove_dependencies(source, current_sources)
	-- Check if any remaining sources depend on this one
	local dependents = self:get_dependents(source)
	if #dependents == 0 then
		current_sources[source] = nil
	end

	-- Recursively check nested dependencies
	for _, dep in pairs(self._dependencies[source] or {}) do
		self:_remove_dependencies(dep, current_sources)
	end
end

function cache:get_buffer_sources(bufnr)
	return self._buffers[bufnr] and self._buffers[bufnr].sources or {}
end

---@param path string
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
		local data = require("html-css.parsers.css").setup(content)
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

---@param bufnr integer
function cache:_get_ids(bufnr)
	local buffer_sources = self._buffers[bufnr].sources or {}
	local ids = {}

	for source, _ in pairs(buffer_sources) do
		local source_data = self._sources[source]
		if source_data then
			for _, id in pairs(source_data.ids) do
				id.source_name = source_data.meta.name
				id.source_path = source_data.meta.path
				table.insert(ids, id)
			end
		end
	end

	return ids
end

---@param bufnr integer
---@param css_content string
function cache:update_inline_styles(bufnr, css_content)
	local inline_source = "buffer://" .. bufnr .. "/inline-styles"
	local data = require("html-css.parsers.css").setup(css_content)
	self:update(inline_source, data)
end

---@param bufnr integer
function cache:_clear_buffer(bufnr)
	self._buffers[bufnr] = nil
	-- TODO: Implement watcher cleanup when last buffer using a source is closed
end

function cache:cleanup_sources()
	local used_sources = {}
	-- Mark directly used sources
	for _, buffer in pairs(self._buffers) do
		for src in pairs(buffer.sources) do
			used_sources[src] = true
		end
	end

	-- Mark dependencies through dependency graph
	local function mark_dependencies(source)
		local deps = self._dependencies[source] or {}
		for dep in pairs(deps) do
			if not used_sources[dep] then
				used_sources[dep] = true
				mark_dependencies(dep)
			end
		end
	end

	for src in pairs(used_sources) do
		mark_dependencies(src)
	end

	-- Remove unused sources
	for src in pairs(self._sources) do
		print(src)
		if not used_sources[src] then
			self._sources[src] = nil
		end
	end
end

---@param source string
function cache:needs_refresh(source)
	local resolved = utils.resolve_path(source)
	if not self._sources[resolved] then return true end

	if utils.is_remote(source) then
		-- Implement TTL check for remote resources
		local max_age = 3600 -- 1 hour
		return os.time() - self._sources[resolved].meta.mtime > max_age
	else
		-- Check file modification time
		local stat = uv.fs_stat(resolved)
		return stat and stat.mtime.sec > self._sources[resolved].meta.mtime
	end
end

---@param source string
function cache:_unwatch_source(source)
	local resolved = utils.resolve_path(source)
	if self._watchers[resolved] then
		self._watchers[resolved]:stop()
		self._watchers[resolved] = nil
	end
end

return cache
