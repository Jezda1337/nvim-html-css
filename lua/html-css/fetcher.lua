local utils = require("html-css.utils")
local parsers = require("html-css.parsers")
local store = require("html-css.store")
local fetcher = {}

fetcher.setup = function(bufnr, sources)
	local cdn = {}
	local locals = {}
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
					print("GET: " .. url)
				end
			end)
		elseif utils.is_local(url) then
			utils.readFile(url, function(stdout)
				local css_selectors = parsers.css.setup(stdout)

				for type, data in pairs(css_selectors) do
					if not selectors[type] then selectors[type] = {} end
					for _, selector in pairs(data) do
						table.insert(selectors[type], selector)
					end
				end
			end)
			table.insert(locals, {
				source = url,
				fetched = true,
			})
		end
	end

	store:set(bufnr, "selectors", selectors)
	store:set(bufnr, "cdn", cdn)
end

return fetcher
