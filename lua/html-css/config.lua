local M = {}
M.default = {
	enable_on = {
		"html",
	},
	notify = false,
	documentation = {
		auto_show = true,
	},
	style_sheets = {},
}

M.config = {}

---@param opts table|nil Configuration options provided by the user
---@return table Final merged configuration
M.setup = function(opts)
    opts = opts or {}

    M.config = vim.tbl_deep_extend("force", M.default, opts)

    return M.config
end

return M
