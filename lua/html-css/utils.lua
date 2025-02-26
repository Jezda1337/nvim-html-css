local uv = vim.uv
local utils = {}

---@param path string
utils.is_remote = function(path)
	return path:match("^https?://") ~= nil
end

---@param path string
utils.is_local = function(path)
	return not utils.is_remote(path)
end

---@param path string
utils.resolve_path = function(path)
	if utils.is_remote(path) then return path end
	return uv.fs_realpath(path) or ""
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
