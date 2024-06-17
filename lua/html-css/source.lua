---@type Source
local source = {
	items = {},
}

local cache = require("html-css.cache")

function source:complete(_, callback)
	callback({ items = self.items, isComplete = false })
end

function source:is_available()
	local bufnr = vim.api.nvim_get_current_buf()
	local selectors = cache:get(bufnr, "selectors")
		or {
			classes = {},
			ids = {},
		}

	if #selectors > 0 then
		self.items = cache:get(bufnr, "selectors").classes
	end
	return true
end

return source
