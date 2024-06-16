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
	self.items = cache:get(bufnr, "classes")
	return true
end

return source
