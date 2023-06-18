local M = {
	cache = {},
	styles = {},
	file_stats = {},
}

function M:read_html_files(root_dir)
	local files = vim.fn.globpath(root_dir, "**/*.html", true, true)

	for _, file in ipairs(files) do
		local current_stat = vim.loop.fs_stat(file)

		self.file_stats[current_stat] = current_stat

		if
				self.file_stats[current_stat]
				and current_stat
				and self.file_stats[current_stat].mtime.sec == current_stat.mtime.sec
		then
			self:extract_code(file)
		else
			self:extract_code(file)
		end
	end
	return self.styles
end

function M:extract_code(file)
	local lines = {}
	for line in io.lines(file) do
		table.insert(lines, line)
	end

	local content = table.concat(lines, "\n")
	local start_pos, end_pos = content:find("<style>(.-)</style>")

	while start_pos do
		local style_code = content:sub(start_pos + 7, end_pos - 8)
		for class in style_code:gmatch("%.[%w_-]+") do
			local cleaned_class = class:sub(2)
			table.insert(self.styles, cleaned_class)
		end
		start_pos, end_pos = content:find("<style>(.-)</style>", end_pos + 1)
	end

	self.cache = self.styles
end

return M
