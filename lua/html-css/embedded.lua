-- embedded styles are all styles between <style></style> tags
-- inside .html files

local M = {}
local j = require("plenary.job")
local u = require("html-css.utils.init")
local a = require("plenary.async")
local cmp = require("cmp")
local w = require("html-css.watch")

M.read_html_files = a.wrap(function(cb)
	local classes = {}
	local has_changed = false

	local files = j:new({
		command = "fd",
		args = { "-a", "-e", "html" },
	}):sync()

	if #files == 0 then
		return nil
	else
		for _, file in ipairs(files) do
			local lines = {}
			for line in io.lines(file) do
				table.insert(lines, line)
			end

			classes = {} -- clean table from prev styles

			has_changed = w.has_file_changed(file)

			local content = table.concat(lines, "\n")
			local start_pos, end_pos = content:find("<style>(.-)</style>")

			while start_pos do
				local style_code = content:sub(start_pos + 7, end_pos - 8)
				for class in style_code:gmatch("%.[%w_-]+") do
					local cleaned_class = class:sub(2) -- Remove the leading '.'
					table.insert(classes, {
						label = cleaned_class,
						kind = cmp.lsp.CompletionItemKind.Enum,
						menu = u.get_file_name(file, "[^/]+$"),
					})
				end
				start_pos, end_pos = content:find("<style>(.-)</style>", end_pos + 1)
			end

			cb(styles, has_changed)
		end
	end
end, 1)

return M
