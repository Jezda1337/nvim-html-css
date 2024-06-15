---@type Source
local source = {
	items = {},
	ids = {},
	classes = {},
}

function source:new(selectors)
	for _, selector in ipairs(selectors) do
		table.insert(self.items, selector)
	end
	return self
end

function source:complete(_, callback)
	callback({ items = self.items, isComplete = false })
end

function source:is_available()
	return true
end

return source
