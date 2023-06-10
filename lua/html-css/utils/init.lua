local M = {}

function M.extract_selectors(tbl)
	local selectors_pattern = "%.[a-zA-Z_][%w-]*"
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

M.remote_file = require("html-css.utils.get-remote-file")

M.local_file = require("html-css.utils.get-local-file")

return M
