local utils = require "html-css.utils"
local cache = require "html-css.cache"
local fetcher = {}

function fetcher:fetch(source, bufnr, notify)
	local resolved = utils.resolve_path(source)
	if cache._sources[resolved] then return end

	if utils.is_remote(source) then
		self:_fetch_remote(resolved, bufnr, notify)
	else
		self:_fetch_local(resolved, bufnr, notify)
	end
end

function fetcher:_fetch_remote(url, bufnr, notify)
	vim.system({ "curl", "-fsSL", "-L", url }, { text = true }, function(out)
		if out.code ~= 0 then
			-- Remove from cache if fetch fails
			cache._sources[utils.resolve_path(url)] = nil
			if notify then
				vim.notify("Failed to fetch: " .. url, vim.log.levels.ERROR)
			end
			return
		end

		local data = require("html-css.parsers.css").setup(out.stdout)
		cache:update(url, data)

		-- Verify the URL is still needed
		local current_sources = cache._buffers[bufnr].sources or {}
		if not current_sources[utils.resolve_path(url)] then
			cache._sources[utils.resolve_path(url)] = nil
		end
	end)
end

function fetcher:_fetch_local(path, bufnr, notify)
	local content = utils.read_file_sync(path)
	if not content then
		if notify then
			vim.notify("Missing CSS file: " .. path, vim.log.levels.ERROR)
		end
		return
	end

	local data = require("html-css.parsers.css").setup(content)
	cache:update(path, data)
	self:_process_imports(path, data.imports, bufnr, notify) -- Pass parent path
end

function fetcher:_process_imports(parent_path, imports, bufnr, notify)
	local sources = {}
	for _, imp in ipairs(imports) do
		local resolved = utils.resolve_import(imp, bufnr)
		if resolved then
			-- Track dependency relationship
			cache:add_dependency(parent_path, resolved)
			table.insert(sources, resolved)
			self:fetch(resolved, bufnr, notify)
		end
	end

	if #sources > 0 then
		cache:link_buffer(bufnr, sources)
	end
end

return fetcher
