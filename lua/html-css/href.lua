local M = {}

local fetch = require("html-css.fetch").fetch
local extractor = require("html-css.extractor")
local cache = require("html-css.cache")

local bufnr = vim.api.nvim_get_current_buf()

-- links are stored here, even if user delets <link href="link" /> the link will still be cached
-- need to find better soluton for this
---@type Link[]
M.links = cache:get(bufnr, "links") or {}

---@type fun(url: string): boolean
local function url_exists(url)
	for _, link in ipairs(M.links) do
		if link.url == url then
			return true
		end
	end
	return false
end

---@param on_complete fun(selectors: Selector[])
M.init = function(on_complete)
	for _, link in pairs(extractor.href()) do
		if not url_exists(link.url) then
			table.insert(M.links, link)
			cache:set(bufnr, "links", link)
		end
	end

	---@type fun(ctx: Ctx)
	local function handleDataFromHrefLinks(ctx)
		if ctx.code == 0 then
			on_complete(extractor.selectors(ctx.stdout))
		end
	end

	for _, link in ipairs(M.links) do
		if not link.fetched then
			fetch(link.url, {}, handleDataFromHrefLinks)
			link.fetched = true
		end
	end
end

return M
