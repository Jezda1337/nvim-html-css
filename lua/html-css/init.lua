local html_css = {}
local store = require("html-css.store")
local defaults = require("html-css.config")

html_css.setup = function (opts)
	opts = vim.tbl_extend("force", defaults, opts)

	if vim.fn.has("nvim-0.10") == 0 then
		vim.notify("nvim-html-css requires nvim 0.10 and newer", vim.log.levels.ERROR, { title = "nvim-html-css" })
		return
	end


	if next(opts.style_sheets) then
		require("html-css.fetcher").setup(999, opts.style_sheets, opts.notify)
	end

	local group = vim.api.nvim_create_augroup("html-css", { clear = true })
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre", "WinEnter" }, {
		group = group,
		pattern = vim.tbl_map(function (ext) return "*." .. ext end, opts.enable_on),
		callback = function (ctx)

		end
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		group = group,
		pattern = "*",
		callback = function (ctx)
			store:clear(ctx.buf)
		end
	})
	require("cmp").register_source("html-css", require("html-css.source"):new(opts))
end


return html_css
