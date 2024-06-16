local M = {}

M.cache = {
	-- [1] = {
	-- 	file_name = "",
	-- 	links = {
	-- 		{
	-- 			url = "",
	-- 			fetched = false,
	-- 			provider = "bootstrap",
	-- 		},
	-- 		{
	-- 			url = "",
	-- 			fetched = false,
	-- 			provider = "bootstrap",
	-- 		},
	-- 	},
	-- 	ids = {},
	-- 	classes = {},
	-- },
}

---@param bufnr number
---@param key string
function M:get(bufnr, key)
	if not self.cache[bufnr] then
		return nil
	end
	return self.cache[bufnr][key]
end

---@param bufnr number
function M:set(bufnr, key, value)
	if not self.cache[bufnr] then
		self.cache[bufnr] = {
			[key] = {},
		}
	end

	self.cache[bufnr][key] = value
end

---@param bufnr number
---@return boolean or nil
function M:has(bufnr)
	return self.cache[bufnr] ~= nil
end

return M
