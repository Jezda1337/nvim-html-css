local config   = require "html-css.config"
local cmp      = require "cmp"
local utils    = require "html-css.utils"
local fetcher  = require "html-css.fetcher"
local cache    = require "html-css.cache"

local html_css = {}

html_css.setup = function(opts)
	opts = vim.tbl_extend("force", config, opts)

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre" }, {
		group = vim.api.nvim_create_augroup("html-css", {}),
		pattern = vim.tbl_map(function(ext) return "*." .. ext end, opts.enable_on),
		callback = function(args)
			if utils.is_special_buffer(args.buf) then return end

			local previous_sources = cache:get_buffer_sources(args.buf)

			local html_data = require("html-css.parsers.html").setup(args.buf)
			local sources = vim.list_extend(opts.style_sheets, html_data.cdn)

			-- Process inline styles as a single CSS block
			if #html_data.raw_text > 0 then
				cache:update_inline_styles(args.buf, html_data.raw_text)
				table.insert(sources, "buffer://" .. args.buf .. "/inline-styles")
			end

			for _, src in pairs(sources) do
				fetcher:fetch(src, args.buf, opts.notify)
			end

			cache:link_buffer(args.buf, sources)

			for _, src in ipairs(sources) do
				if not utils.is_remote(src) or cache._sources[utils.resolve_path(src)] then
					fetcher:fetch(src, args.buf, opts.notify)
				end
			end

			local current_sources = cache:get_buffer_sources(args.buf)
			for src in pairs(current_sources) do
				if not previous_sources[src] or cache:needs_refresh(src) then
					fetcher:fetch(src, args.buf, opts.notify)
				end
			end

			-- Cleanup old watchers for removed sources
			for src in pairs(previous_sources) do
				if not current_sources[src] then
					cache:_unwatch_source(src)
				end
			end
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
