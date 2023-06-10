local M = {}
local Curl = require("plenary.curl")

function M.get_remote_file(url)
	local response = Curl.get(url)

	if not response then
		print("There is no response.")
		return nil, {}
	end

	return response.status, response.body
end

return M
