local utils = require("html-css.utils")
local parsers = require("html-css.parsers")
local store = require("html-css.store")

local fetcher = {}

local function process_selectors(css_selectors, selectors)
	for type, data in pairs(css_selectors) do
		if type ~= "imports" then
			if not selectors[type] then selectors[type] = {} end
			for _, selector in pairs(data) do
				table.insert(selectors[type], selector)
			end
		end
	end
end

local function fetch_css(url, bufnr, selectors, imports, cdn, locals, notify)
	if utils.is_link(url) then
		utils.curl(url, {}, function(ctx)
			if ctx.code == 0 then
				local css_selectors = parsers.css.setup(ctx.stdout)

				-- -- Handle imports recursively
				-- if css_selectors.imports then
				-- 	for _, import in pairs(css_selectors.imports) do
				-- 		table.insert(imports, import)
				-- 		-- Recursively fetch the imported CSS
				-- 		fetch_css(import, bufnr, selectors, imports, cdn, locals, notify)
				-- 	end
				-- end

				process_selectors(css_selectors, selectors)

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
	elseif utils.is_local(url) then
		utils.readFile(url, function(stdout)
			local css_selectors = parsers.css.setup(stdout)


			vim.schedule(function()
				if css_selectors.imports then
					for _, import in pairs(css_selectors.imports) do
						table.insert(imports, import)
						fetch_css(import.source, bufnr, selectors, imports, cdn, locals, notify)
					end
				end
			end)

			process_selectors(css_selectors, selectors)

			table.insert(locals, {
				source = url,
				fetched = true,
			})
		end)
	end
end

fetcher.setup = function(bufnr, sources, notify)
	local cdn = {}
	local locals = {}
	local selectors = {}
	local imports = {}

	for _, url in pairs(sources) do
		fetch_css(url, bufnr, selectors, imports, cdn, locals, notify)
	end

	store:set(bufnr, "selectors", selectors)
	store:set(bufnr, "imports", imports)
	store:set(bufnr, "cdn", cdn)
end

return fetcher
