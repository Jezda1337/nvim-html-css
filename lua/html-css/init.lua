local html_css = {}
local config = require("html-css.config")
local store = require("html-css.store")

html_css.setup = function(opts)
	config = vim.tbl_extend("force", config.default, opts)
	local enable_on_dto = {}

	if vim.fn.has("nvim-0.10") == 0 then
		vim.notify("nvim-html-css requires nvim 0.10 and newer", vim.log.levels.ERROR, { title = "nvim-html-css" })
		return
	end

	for _, ext in pairs(config.enable_on) do
		table.insert(enable_on_dto, "*." .. ext)
	end

	if config.style_sheets ~= nil and #config.style_sheets ~= 0 then
		-- this bufnr represents global style_sheets
		local bufnr = 999
		require("html-css.fetcher").setup(bufnr, config.style_sheets)
	end

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre", "WinEnter" }, {
		pattern = enable_on_dto,
		callback = function(ctx)
			vim.schedule(function()
				-- current html data like hrefs and raw_text
				local html_data = require("html-css.parsers").html.setup(ctx.buf)
				-- extract classes and ids + stulyes from raw_text
				local local_selectors = require("html-css.parsers").css.setup(html_data.raw_text)
				-- extract selectors from external links in hrefs from a buffer
				require("html-css.fetcher").setup(ctx.buf, html_data.cdn)

				store:set(ctx.buf, "selectors", local_selectors)
			end)
		end,
	})


	require("cmp").register_source("html-css", require("html-css.source"):new(config))
end

return html_css
