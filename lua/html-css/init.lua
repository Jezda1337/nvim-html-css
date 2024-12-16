local M = {}

local source = require("html-css.source")
local externals = require("html-css.externals")
local extractor = require("html-css.extractor")
local ss = require("html-css.style_sheets")
local internal = require("html-css.internal")
local config = require("html-css.config").config

local source_name = "html-css"

---@type string[]
local enable_on_dto = {}

for _, ext in pairs(config.enable_on) do
	table.insert(enable_on_dto, "*." .. ext)
end

function M:setup()
	require("cmp").register_source(source_name, source)

	if #config.style_sheets ~= 0 then
		ss.init(config.style_sheets)
	end

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre", "WinEnter" }, {
		pattern = enable_on_dto,
		callback = function(event)
			local hrefs = extractor.href(config.style_sheets)
			externals.init(event.buf, hrefs)
			internal.init(event.buf, event.file)
		end,
	})
end

return M
