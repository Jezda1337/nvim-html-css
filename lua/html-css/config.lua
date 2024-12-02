local M = {}
M.default = {
	enable_on = {
		"html",
	},
	style_sheets = {},
	spa = {
		enable = false,
		entry_file = "index.html",
	},
}

M.config = {}

---@param opts Config
---@return Config
M.setup = function(opts)
	M.config = vim.tbl_deep_extend("force", M.default, opts)
	return M.config
end

return M
