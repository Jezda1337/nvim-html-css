local utils = require "html-css.utils"

local cache = {
	_sources = {},
	_buffers = {}
}

function cache:_link_sources(bufnr, sources)
	local resolved_sources = {}
	for _, src in pairs(sources) do
		local resolved = utils.resolve_path(src)
		resolved_sources[resolved] = true
	end

	self._buffers[bufnr] = {
		_sources = resolved_sources
	}
end

return cache
