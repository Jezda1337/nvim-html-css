local store = require("html-css.store")
---@type Source
local source = {}

source.items = {}

function source:complete(_, callback)
	callback({ items = self.items, isComplete = false })
end

function source:is_available()
	local bufnr = vim.api.nvim_get_current_buf()
	-- pickup the selectors and store them in items
	if store.has(bufnr, "selectors") then
		local selectors = store.get(bufnr, "selectors")
		self.items = selectors.classes
		return true
	end
	return false
end

return source
