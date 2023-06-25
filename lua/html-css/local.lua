local M = {}
local cmp = require("cmp")
local u = require("html-css.utils.init")
local a = require("plenary.async")
local j = require("plenary.job")

M.read_local_files = a.wrap(function(_, cb)
	local styles = {}

	-- for _, ft in ipairs(file_types) do
	-- 	print(ft)
	-- end

	local files = j:new({
		command = "fd",
		args = {
			"-a",
			"-e",
			"css",
			"-e",
			"scss",
			"-e",
			"sass",
			"-e",
			"less",
			"--exclude",
			"node_modules",
		},
		-- args = { "-a", "-e", "" .. ft .. "", "--exclude", "node_modules" },
	}):sync()

	if #files == 0 then
		return nil
	else
		print("test")
		for _, file in ipairs(files) do
			local _, fd = a.uv.fs_open(file, "r", 438)
			local _, stat = a.uv.fs_fstat(fd)
			local _, data = a.uv.fs_read(fd, stat.size, 0)
			a.uv.fs_close(fd)
			local extract_selectors = u.extract_selectors(data)
			local remove_dup_selectors = u.remove_duplicates(extract_selectors)
			for _, class in ipairs(remove_dup_selectors) do
				table.insert(styles, {
					label = class,
					kind = cmp.lsp.CompletionItemKind.Enum,
					menu = u.get_file_name(file, "[^/]+$"),
				})
			end
			cb(styles)
		end
	end
	-- for _, file in ipairs(files) do
	-- 	local lines = {}
	-- 	for line in io.lines(file) do
	-- 		table.insert(lines, line)
	-- 	end

	-- 	local content = table.concat(lines, "\n")
	-- 	local start_pos, end_pos = content:find("<style>(.-)</style>")

	-- 	while start_pos do
	-- 		local style_code = content:sub(start_pos + 7, end_pos - 8)
	-- 		for class in style_code:gmatch("%.[%w_-]+") do
	-- 			local cleaned_class = class:sub(2) -- Remove the leading '.'
	-- 			table.insert(styles, cleaned_class)
	-- 		end
	-- 		start_pos, end_pos = content:find("<style>(.-)</style>", end_pos + 1)
	-- 	end
	-- end
end, 2)

return M
