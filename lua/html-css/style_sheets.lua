local M = {}

local store = require("html-css.store")
local extractor = require("html-css.extractor")
local fetcher = require("html-css.fetcher")

---@type fun(ctx: Ctx, cdn: string, bufnr: number)
local function extractDataFromLinks(ctx, cdn, bufnr)
	local selectors = store.get(bufnr, "selectors") or {
		ids = {},
		classes = {},
	}

	if ctx.code == 0 then
		local extracted_selectors = extractor.selectors(ctx.stdout, cdn)
		selectors.ids = vim.list_extend(selectors.ids, extracted_selectors.ids)
		selectors.classes = vim.list_extend(selectors.classes, extracted_selectors.classes)

		store.set(bufnr, "selectors", selectors)
	end
end

---@type fun(styles: string[], bufnr: number)
M.init = function(styles, bufnr)
	for _, style in pairs(styles) do
		local opts = {}
		fetcher(style, opts, function(ctx)
			print("Fetching:", style)
			extractDataFromLinks(ctx, style, bufnr)
		end)
	end
end

return M
