local M = {}

local source = require("html-css.source")
local externals = require("html-css.externals")
local spa = require("html-css.spa")
local cmp_config = require("cmp.config")
local extractor = require("html-css.extractor")
local ss = require("html-css.style_sheets")
local internal = require("html-css.internal")

local source_name = "html-css"
---@type Config
local config = cmp_config.get_source_config(source_name).option or {}
---@type string[]
local enable_on = config.enable_on or { "html" } -- html is enabled by default
local style_sheets = config.style_sheets or {}

---@type string[]
local enable_on_dto = {}

for _, ext in pairs(enable_on) do
	table.insert(enable_on_dto, "*." .. ext)
end

function M:setup()
	require("cmp").register_source("html-css", source)

	-- GLOBAL STYLING
	if not config.spa.enable then
		if config.style_sheets ~= nil then
			vim.api.nvim_create_autocmd({ "VimEnter" }, {
				pattern = enable_on_dto,
				callback = function(event)
					ss.init(style_sheets, event.buf)
				end,
			})
		end
	end

	-- SPA
	if config.spa.enable then
		vim.api.nvim_create_autocmd(
			{ "FileType", "VimEnter", "BufWritePre", "WinEnter" },
			{
				pattern = {
					"javascript",
					"javascriptreact",
					"typescript",
					"typescriptreact",
					"astro",
					"html",
					"vue",
					"svelte",
				},
				callback = function()
					local entry_file = config.spa.entry_file or "index.html"
					spa.init(entry_file)
				end,
			}
		)
		return
	end

	-- GENERAL
	if not config.spa.enable then
		vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre", "WinEnter" }, {
			pattern = enable_on_dto,
			callback = function(event)
				local hrefs = extractor.href()
				externals.init(event.buf, hrefs)
				internal.init(event.buf, event.file)
			end,
		})
	end
end

return M
