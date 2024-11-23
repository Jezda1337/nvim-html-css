local M = {}
M.check = function()
	vim.health.start("nvim-html-css report")
	if vim.fn.executable("curl") == 0 then
		vim.health.error("curl not found on path")
		return
	end

	vim.health.ok("curl found on path")

	local res = vim.system({ "curl", "https://radoje.dev" }, { text = true })
		:wait()
	if res.code == 0 then
		vim.health.ok("site is accessible")
	else
		vim.health.error("site is not accessible")
	end
end
return M
