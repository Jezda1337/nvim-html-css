local M = { links = {} }
local J = require("plenary.job")
local ts = vim.treesitter
local isRemote = "^https?://"

local qs = [[
(attribute
	(attribute_name) @att_name (#eq? @att_name "href")
	(quoted_attribute_value
		(attribute_value) @att_val))
]]

function M.get_hrefs()
	local files = J:new({
		command = "fd",
		args = { "-a", "-e", "html", "--exclude", "node_modules" },
	}):sync()

	if #files == 0 then
		return {}
	else
		for _, file in ipairs(files) do
			local fd = io.open(file, "r")
			local data = fd:read("*a")
			fd:close()

			-- html parser for href links
			local html_parser = ts.get_string_parser(data, "html")
			local html_tree = html_parser:parse()[1]
			local html_root = html_tree:root()
			local href_query = ts.query.parse("html", qs)

			for _, matches, _ in href_query:iter_matches(html_root, data, 0, 0, {}) do
				for _, node in pairs(matches) do
					if node:type() == "attribute_value" then
						local href_value = ts.get_node_text(node, data)
						if href_value:match(isRemote) then
							table.insert(M.links, href_value)
						end
					end
				end
			end
		end
	end
	return M.links
end

return M
