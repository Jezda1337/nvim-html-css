local M = {}

local fetch = require("html-css.fetch").fetch
local extractor = require("html-css.extractor")
local cache = require("html-css.cache")

---@type fun(url: string, t: table): boolean
local function url_exists(url, t)
	for _, link in ipairs(t) do
		if link.url == url then
			return true
		end
	end
	return false
end

---@param bufnr number
---@return Link[]
M.collect_links = function(bufnr)
	local links = cache:get(bufnr, "links") or {}

	for _, link in pairs(extractor.href()) do
		if not url_exists(link.url, links) then
			table.insert(links, link)
		end
	end

	cache:set(bufnr, "links", links)
	return links
end

---@param on_complete fun(selectors: Selector[])
M.init = function(on_complete)
	local bufnr = vim.api.nvim_get_current_buf()

	local selectors = {
		classes = cache:get(bufnr, "classes") or {},
		ids = cache:get(bufnr, "ids") or {},
	}

	local links = M.collect_links(bufnr)

	local remaining = #links
	if remaining == 0 then
		on_complete(selectors)
		return
	end

	---@type fun(ctx: Ctx)
	local function extractDataFromLinks(ctx)
		if ctx.code == 0 then
			local extracted_selectors = extractor.selectors(ctx.stdout)
			selectors.classes =
				vim.list_extend(selectors.classes, extracted_selectors.classes)
			selectors.ids =
				vim.list_extend(selectors.ids, extracted_selectors.ids)
		end
		remaining = remaining - 1
		if remaining == 0 then
			cache:set(bufnr, "classes", selectors.classes)
			cache:set(bufnr, "ids", selectors.ids)
			on_complete(selectors)
		end
	end

	for _, link in ipairs(links) do
		if not link.fetched then
			fetch(link.url, {}, function(ctx)
				print("Fetching:", link.url)
				extractDataFromLinks(ctx)
				link.fetched = true
			end)
		else
			remaining = remaining - 1
		end
	end

	cache:set(bufnr, "links", links)
end

return M
