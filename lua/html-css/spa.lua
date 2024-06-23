local M = {}

local q = require("html-css.querys")
local readFile = require("html-css.helpers").readFile
local ts = vim.treesitter

local extract_hrefs_and_locals = function(data)
	local externals = {
		cdn = {},
		locals = {},
	}

	local parser = ts.get_string_parser(data, "html")
	local tree = parser:parse()[1]
	local root = tree:root()
	local query = ts.query.parse("html", q.general_link_href)

	for _, captures, _ in query:iter_matches(root, data, 0, 0) do
		local href_value = ts.get_node_text(captures[3], data)
		if href_value:match("^https?://") then
			table.insert(externals.cdn, {
				url = href_value,
				fetched = false,
				available = false,
				source = href_value,
			})
		else
			table.insert(externals.locals, {
				path = href_value,
				fetched = false,
				available = false,
				source = href_value,
			})
		end
	end

	return externals
end

local externals = require("html-css.externals")
M.init = function(entry_file)
	local file = vim.fn.findfile(entry_file, ".**")
	if not file then
		return
	end

	readFile(file, function(data)
		local externals_dto = extract_hrefs_and_locals(data)
		local hrefs = externals.init(0, externals_dto)
	end)
end

return M
