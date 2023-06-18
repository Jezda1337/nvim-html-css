local M = {}

function M.extract_selectors(tbl)
	local selectors_pattern = "%.[a-zA-Z_][%w-]+[%w_]*"
	local selectors = {}

	for class in tbl:gmatch(selectors_pattern) do
		local class_name = string.sub(class, 2)
		table.insert(selectors, class_name)
	end

	return selectors
end

function M.get_file_name(file, pattern)
	-- "[^/]+%.%w+$"  -- from url
	-- "[^/]+$" -- from local file
	local fileName = file:match(pattern)
	return fileName
end

function M.remove_duplicates(tbl)
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

function M.remove_duplicate_tables_by_label(tbl)
	local uniqueTables = {}
	local result = {}

	for _, item in ipairs(tbl) do
		local isDuplicate = false
		for _, uniqueTable in ipairs(uniqueTables) do
			if item.label == uniqueTable.label then
				isDuplicate = true
				break
			end
		end
		if not isDuplicate then
			table.insert(uniqueTables, item)
			table.insert(result, item)
		end
	end

	return result
end

return M
