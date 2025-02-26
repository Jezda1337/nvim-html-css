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
	end)
end

return fetcher
