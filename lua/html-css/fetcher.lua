local utils = require("html-css.utils")
local parsers = require("html-css.parsers")
local store = require("html-css.store")
local fetcher = {}

fetcher.setup = function(bufnr, sources, notify)
	local cdn = {}
	local selectors = {}

	for _, url in pairs(sources) do
		if utils.is_link(url) then
			utils.curl(url, {}, function(ctx)
				if ctx.code == 0 then
					local css_selectors = parsers.css.setup(ctx.stdout)

					for type, data in pairs(css_selectors) do
						if not selectors[type] then selectors[type] = {} end
						for _, selector in pairs(data) do
							table.insert(selectors[type], selector)
						end
					end

					table.insert(cdn, {
						source = url,
						fetched = true,
					})
					if notify then
						vim.schedule(function()
							vim.notify("GET: " .. url)
						end)
					end
				end
			end)
		end
	end

	store:set(bufnr, "selectors", selectors)
	store:set(bufnr, "cdn", cdn)
end

return fetcher
