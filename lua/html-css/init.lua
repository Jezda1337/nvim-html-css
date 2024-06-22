local M = {}
local source = require("html-css.source")
local externals = require("html-css.externals")
local cmp_config = require("cmp.config")
local config = cmp_config.get_source_config("html-css").option or {}

---@type string[]
local enable_on = config.enable_on or { "html" } -- html is enabled by default
local source_name = "html-css"

---@type string[]
local enable_on_dto = {}

for _, ext in pairs(enable_on) do
	table.insert(enable_on_dto, "*." .. ext)
end

function M:setup()
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre" }, {
		pattern = enable_on_dto,
		callback = function(event)
			externals.init(event.buf, event.file)
		end,
	})
	require("cmp").register_source("html-css", source)
end

return M
