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
	vim.system({ "curl", "-fsSL", "-L", url }, { text = true }, vim.schedule_wrap(function(out)
		if out.code ~= 0 then
			cache._sources[utils.resolve_path(url)] = nil
			if notify then
				vim.notify("Failed to fetch: " .. url, vim.log.levels.ERROR)
			end
			return
		end

		local data = require("html-css.parsers.css").setup(out.stdout)
		cache:update(url, data)
	end))
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
	self:_process_imports(path, data.imports, bufnr, notify)
end

function fetcher:_process_imports(parent_path, imports, bufnr, notify)
	local sources = {}

	for _, imp in ipairs(imports) do
		local resolved = utils.resolve_import(imp, bufnr)
		if resolved then
			sources[resolved] = true
			self:fetch(resolved, bufnr, notify)
		end
	end

	local current_sources = cache._buffers[bufnr] and cache._buffers[bufnr].sources or {}
	for src in pairs(current_sources) do
		sources[src] = true
	end

	local final_sources = {}
	for src in pairs(sources) do
		table.insert(final_sources, src)
	end

	cache:link_buffers(bufnr, final_sources)
end

return fetcher
