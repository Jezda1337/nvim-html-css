local M = {}
local cmp = require("cmp")
local u = require("html-css.utils.init")
local a = require("plenary.async")
local j = require("plenary.job")
local ts = vim.treesitter
local classes = {}
local ids = {}
local unique_class = {}
local unique_ids = {}

-- treesitter query for extracting css clasess
local qs = [[
	(id_selector
		(id_name)@id_name)
	(class_selector
		(class_name)@class_name)
]]

---@async
M.read_local_files = a.wrap(function(file_extensions, cb)
	local files = {}
	local fa = { "-a" }

	-- WARNING need to check for performance in larger projects
	for _, extension in ipairs(file_extensions) do
		table.insert(fa, "-e")
		table.insert(fa, extension)
	end
	table.insert(fa, "--exclude")
	table.insert(fa, "node_modules")
	j:new({
		command = "fd",
		args = fa,
		on_stdout = function(_, data)
			table.insert(files, data)
		end,
	}):sync()

	if #files == 0 then
		return
	else
		for _, file in ipairs(files) do
			---@type string
			local file_name = u.get_file_name(file, "[^/]+$")

			local fd = io.open(file, "r")
			local data = fd:read("*a")
			fd:close()

			-- reading html files
			-- local _, fd = a.uv.fs_open(file, "r", 438)
			-- local _, stat = a.uv.fs_fstat(fd)
			-- local _, data = a.uv.fs_read(fd, stat.size, 0)
			-- a.uv.fs_close(fd)

			classes = {} -- clean up prev classes
			ids = {}
			unique_class = {}
			unique_ids = {}

			local parser = ts.get_string_parser(data, "css")
			local tree = parser:parse()[1]
			local root = tree:root()
			local query = ts.query.parse("css", qs)

			for _, matches, _ in query:iter_matches(root, data, 0, 0, {}) do
				for _, node in pairs(matches) do
					if node:type() == "id_name" then
						local id_name = ts.get_node_text(node, data)
						table.insert(unique_ids, id_name)
					else
						local class_name = ts.get_node_text(node, data)
						table.insert(unique_class, class_name)
					end
				end
			end

			local unique_list = u.unique_list(unique_class)
			for _, class in ipairs(unique_list) do
				table.insert(classes, {
					label = class,
					kind = cmp.lsp.CompletionItemKind.Enum,
					menu = file_name,
				})
			end

			local unique_ids_list = u.unique_list(unique_ids)
			for _, id in ipairs(unique_ids_list) do
				table.insert(ids, {
					label = id,
					kind = cmp.lsp.CompletionItemKind.Enum,
					menu = file_name,
				})
			end

			cb(classes, ids)
		end
	end
end, 2)

return M
