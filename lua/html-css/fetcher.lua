local utils = require "html-css.utils"
local cache = require "html-css.cache"

local fetcher = {}

function fetcher:fetch(source, bufnr, notify)
	if utils.is_remote(source) then
		self:_fetch_remote(source, bufnr)
	elseif utils.is_local(source) then
		self:_fetch_local(source, bufnr)
	end
end

function fetcher:_fetch_remote(source, bufnr)
	if cache:has_source(source) then return end

	vim.system({ "curl", source }, { text = true }, function(out)
		if out.code ~= 0 then
			vim.schedule(function()
				vim.notify("Failt to fetch: " .. source, vim.log.levels.ERROR)
			end)
			return
		end

		local css_data = require "html-css.parsers.css".setup(out.stdout)
		cache:update(source, css_data)
	end)
end

function fetcher:_fetch_local(source, bufnr)
	local resolved = utils.resolve_path(source)
	utils.read_file(resolved, function(out)
		local css_data = require "html-css.parsers.css".setup(out)
		cache:update(source, css_data)
		if #css_data.imports > 0 then
			self:_process_imports(resolved, css_data.imports, bufnr, false)
		end
	end)
end

function fetcher:_process_imports(resolved_parent, imports, bufnr, notify)
	local sources = {}

	for _, imp in pairs(imports) do
		local resolved = utils.resolve_path(imp)
		if resolved then
			table.insert(sources, imp)
			self:fetch(resolved, bufnr, notify)
		end
	end

	for src, _ in pairs(cache._buffers[bufnr]._sources or {}) do
		table.insert(sources, src)
	end

	cache:link_sources(bufnr, sources)
end

return fetcher
