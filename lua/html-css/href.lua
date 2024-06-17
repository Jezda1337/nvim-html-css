local M = {}

local fetch = require("html-css.fetch").fetch
local extractor = require("html-css.extractor")
local cache = require("html-css.cache")

---@type fun(url: string, remote: Link[]): boolean
local function url_exists(url, remote)
	for _, link in ipairs(remote) do
		if link.url == url then
			return true
		end
	end
	return false
end

---@type fun(bufnr: number): {remote: Link[], locals: Link[]}
local function collect_links(bufnr)
	local cached_links = cache:get(bufnr, "links")
		or { remote = {}, locals = {} }

	local links = {
		remote = cached_links.remote,
		locals = cached_links.locals,
	}

	for _, link in pairs(extractor.href().remote) do
		if not url_exists(link.url, links.remote) then
			table.insert(links.remote, link)
		end
	end

	cache:set(bufnr, "links", links)
	return links
end

M.init = function(bufnr, file_name)
	local cached_selectors = cache:get(bufnr, "selectors")
		or {
			classes = {},
			ids = {},
		}
	local selectors = {
		classes = cached_selectors.classes,
		ids = cached_selectors.ids,
	}

	local links = collect_links(bufnr)
	local remote = links.remote
	local locals = links.locals

	---@type fun(ctx: Ctx, link: Link)
	local function extractDataFromLinks(ctx, link)
		if ctx.code == 0 then
			local extracted_selectors = extractor.selectors(ctx.stdout)
			selectors.classes =
				vim.list_extend(selectors.classes, extracted_selectors.classes)
			selectors.ids =
				vim.list_extend(selectors.ids, extracted_selectors.ids)

			link.fetched = true
			cache:set(bufnr, "selectors", selectors)
		end
	end

	for _, link in ipairs(remote) do
		if not link.fetched then
			local opts = {}
			fetch(link.url, opts, function(ctx)
				print("Fetching:", link.url)
				extractDataFromLinks(ctx, link)
			end)
		end
	end
end
return M
