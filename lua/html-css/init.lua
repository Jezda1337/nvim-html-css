local utils    = require "html-css.utils"
local config   = require "html-css.config"
local cache    = require "html-css.cache"
local fetcher  = require "html-css.fetcher"

local html_css = {}

html_css.setup = function(opts)
	opts = vim.tbl_extend("force", config, opts)

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre" }, {
		group = vim.api.nvim_create_augroup("html-csss", { clear = true }),
		pattern = vim.tbl_map(function(ext) return "*." .. ext end, opts.enable_on),
		callback = function(args)
			if utils.is_special_buffer(args.buf) then return end


			local html_data = require "html-css.parsers.html".setup(args.buf)
			local sources = vim.list_extend(html_data.cdn, opts.style_sheets)

			if #html_data.raw_text > 0 then
				local css_data = require "html-css.parsers.css".setup(html_data.raw_text)
				cache:update("buffer://" .. args.file, css_data)
				table.insert(sources, "buffer://" .. args.file)
			end

			for _, src in pairs(sources) do
				if src:match("buffer://") then goto continue end
				fetcher:fetch(src, args.buf, opts.notify)
			    ::continue::
			end

			cache:link_sources(args.buf, sources)
		end
	})

	require "cmp".register_source("html-css", require "html-css.source":new(opts))
end

return html_css
