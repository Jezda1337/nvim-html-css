local M = {}

local default_config = {
	file_types = {
		"html",
		"css",
		"scss",
	},
	max_count = 10,
	-- style_sheets = {
	-- 	"https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.css",
	-- 	"./style.css",
	-- },
}

function M:setup(user_config)
	if not user_config then
		return self or {}
	end

	for k, v in pairs(user_config) do
		default_config[k] = v
	end
end

function M.get(what)
	return default_config[what]
end

return M
