local M = {}

---@type item{}
local selectors = {}

function M.extract_selectors(tbl)
	-- local selectors_pattern = "%.[a-zA-Z_][%w-]+[%w_]*"
	-- local selectors_pattern = "(?<!/%*)%.[a-zA-Z_][%w-]*"
	local selectors_pattern = "%.([%a%_%-%d]+)"
	-- local selectors_pattern = "(?<!https?://)%.[a-zA-Z_][%w-]*%s*[^%w%-]"
	selectors = {} -- reser selectors

	local css_formatted = tbl:gsub("{", " {\n"):gsub("; *", ";\n  "):gsub("}", "\n}\n\n")

	-- print(css_formatted)

	for selector in css_formatted:gmatch(selectors_pattern) do
		table.insert(selectors, selector) -- using pattern we don't need to remove .
		-- table.insert(selectors, selector:sub(2)) -- remove leading '.'
	end

	return selectors
end

function M.get_file_name(file, pattern)
	-- "[^/]+%.%w+$"  -- from url
	-- "[^/]+$" -- from local file
	local fileName = file:match(pattern)
	return fileName
end

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
