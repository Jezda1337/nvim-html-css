local utils = {}
local uv = vim.uv

---@param path string
utils.resolve_path = function(path)
	if utils.is_remote(path) then return path end
	return uv.fs_realpath(path) or ""
end

---@param path string
utils.get_source_name = function(path)
	if utils.is_remote(path) then
		return path:match("([^/]+)%.css$") or path:match("([^/]+)/$") or "remote"
	end
	return vim.fn.fnamemodify(path, ":t:r")
end

---@param path string
utils.is_remote = function(path)
	return path:match("^https?://") ~= nil
end

---@param path string
utils.is_local = function(path)
	return not utils.is_remote(path)
end

---@param path string
utils.read_file_sync = function(path)
	local fd = vim.loop.fs_open(path, "r", 438)
	if not fd then return nil end
	local stat = vim.loop.fs_fstat(fd)
	if not stat then return nil end
	local data = vim.loop.fs_read(fd, stat.size, 0)
	vim.loop.fs_close(fd)
	return data
end

---@param bufnr integer
---@return boolean
utils.is_special_buffer = function(bufnr)
	local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
	if buftype ~= "" then
		return true
	end
	return false
end

return utils
