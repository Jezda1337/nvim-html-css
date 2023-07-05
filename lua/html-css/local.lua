local M = {}
local cmp = require("cmp")
local u = require("html-css.utils.init")
local a = require("plenary.async")
local j = require("plenary.job")
local classes = {}

---@async
M.read_local_files = a.wrap(function(file_extensions, cb)
	local files = {}

	-- j:new({
	-- 	command = "fd",
	-- args = {
	-- 	"-a",
	-- 	"-e",
	-- 	"css",
	-- 	"-e",
	-- 	"scss",
	-- 	"-e",
	-- 	"sass",
	-- 	"-e",
	-- 	"less",
	-- 	"--exclude",
	-- 	"node_modules",
	-- },
	-- 	on_stdout = function(_, data)
	-- 		table.insert(files, data)
	-- 	end,
	-- }):sync()

	-- WARNING need to check for performance in larger projects
	for _, extension in ipairs(file_extensions) do
		j:new({
			command = "fd",
			args = { "-a", "-e", "" .. extension .. "", "--exclude", "node_modules" },
			on_stdout = function(_, data)
				table.insert(files, data)
			end,
		}):sync()
	end

	if #files == 0 then
		return nil
	else
		for _, file in ipairs(files) do
			local file_name = u.get_file_name(file, "[^/]+$")

			classes = {} -- clean up prev classes

			local _, fd = a.uv.fs_open(file, "r", 438)
			local _, stat = a.uv.fs_fstat(fd)
			local _, data = a.uv.fs_read(fd, stat.size, 0)
			a.uv.fs_close(fd)

			local extract_selectors = u.extract_selectors(data)
			local remove_dup_selectors = u.unique_list(extract_selectors)

			for _, class in ipairs(remove_dup_selectors) do
				table.insert(classes, {
					label = class,
					kind = cmp.lsp.CompletionItemKind.Enum,
					menu = file_name,
				})
			end

			cb(classes)
		end
	end
end, 2)

return M
