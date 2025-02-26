local uv = vim.uv
local utils = {}

---@param path string
---@return string
utils.get_source_name = function(path)
	if utils.is_remote(path) then
		return path:match("([^/]+)%.css$") or path:match("([^/]+)/$") or "remote"
	end
	return vim.fn.fnamemodify(path, ":t:r")
end

---@param lang string
---@param langs table<string>
utils.is_lang_enabled = function(lang, langs)
	langs = langs or {}
	for _, v in ipairs(langs) do
		if v == lang then
			return true
		end
	end
	return false
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
utils.resolve_path = function(path)
	if utils.is_remote(path) then return path end
	return uv.fs_realpath(path) or path or ""
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
