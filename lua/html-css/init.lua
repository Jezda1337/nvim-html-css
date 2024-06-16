local M = {}
local href = require("html-css.href").init
local source = require("html-css.source")
local cache = require("html-css.cache")

---@type string[]
local enable_on = { "html" }

---@type string[]
local enable_on_dto = {}

for _, opt in pairs(enable_on) do
	table.insert(enable_on_dto, "*." .. opt)
end

function M:setup()
	vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre" }, {
		pattern = enable_on_dto,
		callback = function(event)
			local bufnr = event.buf
			cache:set(bufnr, "file_name", event.file)
			cache:set(bufnr, "buf", bufnr)

			---@param data any
			href(function(data)
				print(vim.inspect(cache:get(bufnr, "links")))
			end)
		end,
	})
	require("cmp").register_source("html-css", source)
end

return M
