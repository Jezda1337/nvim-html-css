local M = {}

function trim(s)
	return (string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

-- --------------------------
-- v1
-- --------------------------

-- function parse_css_selectors(css_text)
-- 	local selectors = {}

-- 	-- split css rules into individual strings
-- 	local rules = {}
-- 	for rule in css_text:gmatch("[^{}]+") do
-- 		table.insert(rules, rule)
-- 	end

-- 	-- iterate over rules and extract selectors
-- 	for _, rule in ipairs(rules) do
-- 		rule = trim(rule) -- remove leading/trailing whitespace
-- 		if rule:sub(1, 1) == "#" or rule:sub(1, 1) == "." then
-- 			-- match ID or class selector
-- 			local selector = rule:match("^[%#%.-]?([%w-_]+)")
-- 			if selector then
-- 				table.insert(selectors, selector)
-- 			end
-- 		elseif rule:sub(1, 1) == "[" then
-- 			-- match attribute selector
-- 			local selector = rule:match("^%[([^%]]+)%]")
-- 			if selector then
-- 				table.insert(selectors, selector)
-- 			end
-- 		elseif rule:sub(1, 1) == "@" then
-- 			-- ignore @-rules
-- 		elseif rule:sub(1, 1) ~= "" then
-- 			-- assume the rule contains a tag selector
-- 			local tag = rule:match("^([%w-_]+)")
-- 			if tag then
-- 				table.insert(selectors, tag)
-- 			end
-- 		end
-- 	end

-- 	return selectors
-- end

-- --------------------------
-- v2
-- --------------------------

-- function parse_css_selectors(css_text)
-- 	local selectors = {}

-- 	-- split css rules into individual strings
-- 	local rules = {}
-- 	for rule in css_text:gmatch("[^{}]+") do
-- 		table.insert(rules, rule)
-- 	end

-- 	-- iterate over rules and extract selectors
-- 	for _, rule in ipairs(rules) do
-- 		rule = trim(rule) -- remove leading/trailing whitespace
-- 		if rule:sub(1, 1) == "#" or rule:sub(1, 1) == "." then
-- 			-- match ID or class selector
-- 			local selector = rule:match("^[%#%.-]?([%w-_]+)")
-- 			if selector then
-- 				table.insert(selectors, selector)
-- 			end
-- 		elseif rule:sub(1, 1) == "[" then
-- 			-- match attribute selector
-- 			local selector = rule:match("^%[([^%]]+)%]")
-- 			if selector then
-- 				table.insert(selectors, selector)
-- 			end
-- 		elseif rule:sub(1, 1) == "@" then
-- 			-- ignore @-rules
-- 		elseif rule:sub(1, 1) ~= "" then
-- 			-- assume the rule contains a tag selector
-- 			local tag = rule:match("^([%w-_]+)")
-- 			if tag then
-- 				table.insert(selectors, tag)
-- 			end
-- 		end

-- 		-- check for special cases of concatenated selectors
-- 		if rule:find("[.#][%w-_]+[.#][%w-_]+") then
-- 			for selector in rule:gmatch("[.#][%w-_]+") do
-- 				selector = selector:sub(2)
-- 				if selector then
-- 					table.insert(selectors, selector)
-- 				end
-- 			end
-- 		end

-- 		if rule:find("[^%w][%w-_]+[.#][%w-_]+") then
-- 			for selector in rule:gmatch("[^%w][%w-_]+") do
-- 				selector = selector:sub(2)
-- 				if selector then
-- 					table.insert(selectors, selector)
-- 				end
-- 			end
-- 			for selector in rule:gmatch("[.#][%w-_]+") do
-- 				selector = selector:sub(2)
-- 				if selector then
-- 					table.insert(selectors, selector)
-- 				end
-- 			end
-- 		end
-- 	end

-- 	return selectors
-- end

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
