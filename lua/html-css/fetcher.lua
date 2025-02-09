local store = require("html-css.store")
local cache = require("html-css.cache")
local utils = require("html-css.utils")
local parsers = require("html-css.parsers")
local fetcher = {}

---@param bufnr integer
---@param sources table<string>
---@param notify boolean
fetcher.setup = function(bufnr, sources, notify)
	if type(sources) ~= "table" then return end

	for _, source in pairs(sources) do
		cache:get(source)
		if cache:has(source) then
			local cache_selectors = cache:get(source)
			store:set(bufnr, "selectors", cache_selectors)
		else
			if utils.is_link(source) then
				utils.curl(source, {}, function(ctx)
					if ctx.code ~= 0 then return end
					if notify then
						vim.schedule(function()
							vim.notify("GET: " .. source, vim.log.levels.info)
						end)
					end
					local css = parsers.css.setup(ctx.stdout)
					vim.schedule(function()
						cache:set(source, css)
					end)
					store:set(bufnr, "selectors", css)
				end)
			else
				local content = vim.fn.readfile(source)
				if content then
					content = table.concat(content, "\n")
					if notify then
						vim.schedule(function()
							vim.notify("GET: " .. source, vim.log.levels.info)
						end)
					end
					local css = parsers.css.setup(content)
					if #css.imports > 0 then
						fetcher.setup(bufnr, css.imports, notify)
					end
					store:set(bufnr, "selectors", css)
				end
			end
		end
	end
end

return fetcher
