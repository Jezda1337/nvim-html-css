local M = {}
local Curl = require("plenary.curl")

function M.get_remote_file(url)
	local response = Curl.get(url)

	if not response then
		print("There is no response.")
		return nil, {}
	end

	return response.body
end

function M.extract_selectors(styles)
	local class_pattern = "%.[a-zA-Z_][%w-]*"
	local classes = {}

	for class in styles:gmatch(class_pattern) do
		local class_name = string.sub(class, 2)
		table.insert(classes, class_name)
	end

	return classes
end

function M.remove_duplicates(t)
	local seen = {}

	local result = {}

	for _, value in ipairs(t) do
		if not seen[value] then
			table.insert(result, value)
			seen[value] = true
		end
	end

	return result
end

return M
