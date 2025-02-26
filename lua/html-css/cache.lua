local utils = require "html-css.utils"

local cache = {
	_sources = {},
	_buffers = {}
}

---@param bufnr integer
---@return table<table>
function cache:get_classes(bufnr)
	local buffer_sources = self._buffers[bufnr]._sources or {}
	local classes = {}

	for src in pairs(buffer_sources) do
		vim.list_extend(classes, self._sources[src].classes)
	end

	return classes
end

---@param source string
---@param data table<any>
function cache:update(source, data)
	local resolved = utils.resolve_path(source)
	local now = os.time()

	local source_type = utils.is_remote(source) and "remote" or "local"

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

	insert_items(data.class, self._sources[resolved].classes)
end

---@param bufnr integer
---@param sources table<string>
function cache:link_sources(bufnr, sources)
	local resolved_sources = {}
	for _, src in pairs(sources) do
		local resolved = utils.resolve_path(src)
		resolved_sources[resolved] = true
	end

	self._buffers[bufnr] = {
		_sources = resolved_sources
	}
end

---@param source string
---@return boolean
function cache:has_source(source)
	return cache._sources[source] ~= nil
end

return cache
