local M = {}

function M.remote_file()
	return require("html-css.utils.get-remote-file")
end

function M.local_file()
	return require("html-css.utils.get-local-file")
end

return M
