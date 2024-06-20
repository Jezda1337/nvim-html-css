local M = {}
local source = require("html-css.source")
local externals = require("html-css.externals")

---@type string[]
local enable_on = { "html" }
local source_name = "html-css"

---@type string[]
local enable_on_dto = {}

for _, opt in pairs(enable_on) do
	table.insert(enable_on_dto, "*." .. opt)
end

local config = require("cmp.config")

function M:setup()
	local opt = config.get_source_config(source_name).option

	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre" }, {
		pattern = enable_on_dto,
		callback = function(event)
			externals.init(event.buf, event.file)
		end,
	})
	require("cmp").register_source("html-css", source)
end

return M
