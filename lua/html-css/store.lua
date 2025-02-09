local store = {}

---@param bufnr integer
---@param key string
---@param value table<any>
function store:set(bufnr, key, value)
	if not self[bufnr] then self[bufnr] = {} end
	if not self[bufnr][key] then self[bufnr][key] = {} end

	if key == "selectors" then
		local existing = self[bufnr][key]
		for selector_type, selectors in pairs(value) do
			existing[selector_type] = existing[selector_type] or {}
			vim.list_extend(existing[selector_type], vim.deepcopy(selectors))
		end
    else
        self[bufnr][key] = value
    end
end

---@param bufnr integer
---@param key string
---@return table<any> | nil
function store:get(bufnr, key)
	if self[bufnr] ~= nil then
		if self[bufnr][key] ~= nil then
			return self[bufnr][key]
		end
		return self[bufnr]
	end
	return nil
end

---@param bufnr integer
---@param key string
---@return boolean
function store:has(bufnr, key)
	if next(self[bufnr]) then
		if next(self[bufnr][key]) then
			return true
		end
		return true
	end

	return false
end

function store:clear(bufnr)
	store[bufnr] = nil
end

return store
