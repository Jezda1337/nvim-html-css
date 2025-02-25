local uv = vim.uv
local utils = require "html-css.utils"

local cache = {
	_sources = {},
	_buffers = {},
	_watchers = {}
}

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
	local resolved_sources = {}
	for _, src in pairs(sources) do
		local resolved = utils.resolve_path(src)
		resolved_sources[resolved] = true

		if utils.is_local(resolved) and not self._watchers[resolved] then
			self:_setup_watcher(resolved)
		end
	end

	self._buffers[bufnr] = {
		sources = resolved_sources,
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
