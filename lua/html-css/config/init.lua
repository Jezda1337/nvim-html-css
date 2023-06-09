local M = {}

function M.test()
	print("hello world")
end

function M.default_config()
	return {
		file_types = {
			"html",
			"css",
			"scss",
		},
		max_count = 10,
		style_sheets = {
			"https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.css",
			"./style.css",
		},
	}
end

function M.get(what)
	return M.default_config()[what]
end

return M
