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
local function collect_links(bufnr)
	local links = cache:get(bufnr, "links") or {}
	for _, link in pairs(extractor.href()) do
		if not url_exists(link.url, links) then
			table.insert(links, link)
		end
	end

	cache:set(bufnr, "links", links)
	return links
end

M.init = function(bufnr, file_name)
	local selectors = {
		classes = cache:get(bufnr, "classes") or {},
		ids = cache:get(bufnr, "ids") or {},
	}

	local links = collect_links(bufnr)

	---@type fun(ctx: Ctx)
	local function extractDataFromLinks(ctx)
		if ctx.code == 0 then
			local extracted_selectors = extractor.selectors(ctx.stdout)
			selectors.classes =
				vim.list_extend(selectors.classes, extracted_selectors.classes)
			selectors.ids =
				vim.list_extend(selectors.ids, extracted_selectors.ids)
		end
	end

	for _, link in ipairs(links) do
		if not link.fetched then
			local opts = {}
			fetch(link.url, opts, function(ctx)
				print("Fetching:", link.url)
				extractDataFromLinks(ctx)
				link.fetched = true
			end)

			cache:set(bufnr, "classes", selectors.classes)
			cache:set(bufnr, "ids", selectors.ids)
		end
	end
end
return M
