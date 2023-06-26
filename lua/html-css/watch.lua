local M = {}
local p = require("plenary.path")
local file_data = {}

local get_local_path = function(path)
	local file_path = p:new({ path, sep = "/" })
	if not file_path:exists() then
		return nil
	end
	return file_path:absolute()
end

function M.has_file_changed(path)
	local file = get_local_path(path)
	local current_stats = vim.loop.fs_stat(file)

	if not file then
		print("File not found.")
		return false
	end

	if not file_data[file] then
		file_data[file] = current_stats
		return false
	end

	if file_data[file] and current_stats and file_data[file].mtime.sec == current_stats.mtime.sec then
		return false
	else
		file_data[file] = current_stats
		return true
	end
end

return M
