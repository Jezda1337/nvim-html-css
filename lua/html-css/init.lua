local config   = require "html-css.config"
local cmp      = require "cmp"
local utils    = require "html-css.utils"
local fetcher  = require "html-css.fetcher"
local cache    = require "html-css.cache"

local html_css = {}

html_css.setup = function(opts)
	opts = vim.tbl_extend("force", config, opts)

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre", "WinEnter" }, {
		group = vim.api.nvim_create_augroup("html-css", {}),
		pattern = vim.tbl_map(function(ext) return "*." .. ext end, opts.enable_on),
		callback = function(args)
			if utils.is_special_buffer(args.buf) then return end

			local html_data = require("html-css.parsers.html").setup(args.buf)
			local sources = vim.list_extend(opts.style_sheets, html_data.cdn)

			if #html_data.raw_text > 0 then
				local inline_source = args.file
				local data = require("html-css.parsers.css").setup(html_data.raw_text)

				cache:update(inline_source, data)

				for _, src in pairs(data.imports) do
					table.insert(sources, src)
				end

				table.insert(sources, inline_source)
			end


			for _, src in pairs(sources) do
				fetcher:fetch(src, args.buf, opts.notify)
			end

			cache:link_buffer(args.buf, sources)
		end
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		group = vim.api.nvim_create_augroup("html-css-cleanup", {}),
		callback = function(args)
			cache:_clear_buffer(args.buf)
		end
	})

	cmp.register_source("html-css", require "html-css.source")
end

return html_css
