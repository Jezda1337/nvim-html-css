local M = {}

---@return string
function M.get_file_name(file, pattern)
	-- "[^/]+%.%w+$"  -- from url
	-- "[^/]+$" -- from local file
	local fileName = file:match(pattern)
	return fileName
end

---@return table<string[]>
function M.unique_list(tbl)
	local seen = {}
	local result = {}

	for _, value in ipairs(tbl) do
		if not seen[value] then
			table.insert(result, value)
			seen[value] = true
		end
	end

	return result
end

return M
