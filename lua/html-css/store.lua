local store = {}

---@type fun(self: metatable, bufnr: integer, key?: string, value?: integer | string | table)
function store:set(bufnr, key, value)
	if not store[bufnr] then store[bufnr] = { [key] = {} } end

	if key == "selectors" and type(value) == "table" and next(value) ~= nil then
		if not store[bufnr][key] then
			store[bufnr][key] = {}
		end

		for type, items in pairs(value) do
			if not store[bufnr][key][type] then
				store[bufnr][key][type] = {}
			end

			for _, item in pairs(items) do
				table.insert(store[bufnr][key][type], item)
			end
		end
	else
		store[bufnr][key] = value
	end
end

---@type fun(self: metatable, bufnr: integer, key?: string): any
function store:get(bufnr, key)
	if not store[bufnr][key] then
		return store[bufnr]
	end
	return store[bufnr][key]
end

---@type fun(self: metatable, bufnr: integer, key?: string):boolean
function store:has(bufnr, key)
	if not key then
		return store[bufnr] ~= nil
	end
	return store[bufnr][key] ~= nil
end

return store
