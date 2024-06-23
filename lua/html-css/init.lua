local M = {}

local source = require("html-css.source")
local externals = require("html-css.externals")
local spa = require("html-css.spa")
local cmp_config = require("cmp.config")
local extractor = require("html-css.extractor")

local source_name = "html-css"
---@type Config
local config = cmp_config.get_source_config(source_name).option or {}
---@type string[]
local enable_on = config.enable_on or { "html", "css" } -- html is enabled by default

---@type string[]
local enable_on_dto = {}

for _, ext in pairs(enable_on) do
	table.insert(enable_on_dto, "*." .. ext)
end

function M:setup()
	require("cmp").register_source("html-css", source)

	if config.spa.enable then
		vim.api.nvim_create_autocmd({ "VimEnter", "BufWritePre", "WinEnter" }, {
			pattern = "*",
			callback = function()
				local entry_file = config.spa.entry_file or "index.html"
				spa.init(entry_file)
			end,
		})
		return
	end

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre", "WinEnter" }, {
		pattern = enable_on_dto,
		callback = function(event)
			local hrefs = extractor.href()
			externals.init(event.buf, hrefs)
		end,
	})
end

return M
