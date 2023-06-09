local M = {}

local Path = require("plenary.path")

function M.get_local_file(path)
	local p = Path:new({ path, sep = "/" })

	-- check does file exists
	if not p:exists() then
		return nil
	end

	print(p:absolute())

	return p:absolute()
end

function M.read_local_file(path)
	print(path)
	local file = io.open(path, "rb")
	if not file then
		return nil
	end
	local f = file:read("*a")
	file:close()
	return f
end

return M
