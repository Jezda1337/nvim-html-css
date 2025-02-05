local store = {}

---@type fun(self: metatable, bufnr: integer, key?: string, value?: integer | string | table)
function store:set(bufnr, key, value)
	if not self[bufnr] then self[bufnr] = {} end
	if not self[bufnr][key] then self[bufnr][key] = {} end

	if next(self[bufnr][key]) and type(value) == "table" then
		self[bufnr][key] = vim.list_extend(vim.deepcopy(self[bufnr][key]), value)
		return
	end

	self[bufnr][key] = value
end

---@type fun(self: metatable, bufnr: integer, key?: string): any
function store:get(bufnr, key)
	if not self[bufnr] then return nil end
	if not self[bufnr][key] then return self[bufnr] end
	return self[bufnr][key]
end

---@type fun(self: metatable, bufnr: integer, key?: string):boolean
function store:has(bufnr, key)
	if not key then
		return self[bufnr] ~= nil
	end
	return self[bufnr][key] ~= nil
end

return store
