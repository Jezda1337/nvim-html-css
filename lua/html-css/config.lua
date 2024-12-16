local M = {}
M.default = {
	enable_on = {
		"html",
	},
	notify = false,
	style_sheets = {},
}

M.config = {}

---@param opts Config
---@return Config
M.setup = function(opts)
	M.config = vim.tbl_deep_extend("force", M.default, opts)
	return M.config
end

return M
