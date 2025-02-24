local config   = require "html-css.config"
local cmp      = require "cmp"
local utils    = require "html-css.utils"
local fetcher  = require "html-css.fetcher"
local cache    = require "html-css.cache"

local html_css = {}

html_css.setup = function(opts)
	opts = vim.tbl_extend("force", config, opts)
	local i = 1
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre", "WinEnter" }, {
		group = vim.api.nvim_create_augroup("html-css", {}),
		pattern = vim.tbl_map(function(ext) return "*." .. ext end, opts.enable_on),
		callback = function(args)
			if utils.is_special_buffer(args.buf) then return end

			local html_data = require "html-css.parsers.html".setup(args.buf)
			local sources = vim.list_extend(html_data.cdn, opts.style_sheets) -- order is important!


			if #html_data.raw_text > 0 then
				local data = require "html-css.parsers.css".setup(html_data.raw_text)
				cache:update(args.file, data)

				table.insert(sources, args.file)

				for _, imp in pairs(data.imports) do
					table.insert(sources, imp)
				end
			end

			cache:link_buffers(args.buf, sources)

			for _, src in pairs(sources) do
				fetcher:fetch(src, args.buf, opts.notify)
			end
		end
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		group = vim.api.nvim_create_augroup("html-css-cleanup", {}),
		callback = function(args)
			-- cache:_clear_buffer(args.buf)
		end
	})

	cmp.register_source("html-css", require "html-css.source")
end

return html_css
