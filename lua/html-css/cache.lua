local uv = vim.uv
local utils = require "html-css.utils"

local cache = {
	_sources = {},
	_buffers = {},
	_watchers = {},

	_version = 0
}

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
---@param sources table<string>
function cache:link_buffer(bufnr, sources)
	local resolved_sources = {}
	for _, src in ipairs(sources) do
		local resolved = utils.resolve_path(src)
		resolved_sources[resolved] = true

		if utils.is_local(resolved) and not self._watchers[resolved] then
			self:_setup_watcher(resolved)
		end
	end

	self._buffers[bufnr] = {
		sources = resolved_sources,
		version = self.version
	}
	self._version = self._version + 1
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
function cache:_clear_buffer(bufnr)
	self._buffers[bufnr] = nil
	-- TODO: Implement watcher cleanup when last buffer using a source is closed
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
