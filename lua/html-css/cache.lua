local utils = require "html-css.utils"

local cache = {
	_sources = {},
	_buffers = {}
}

---@param source string
---@param data table<any>
function cache:update(source, data)
	self._sources[source] = {
		classes = data.class,
		ids = data.ids
	}
end

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
