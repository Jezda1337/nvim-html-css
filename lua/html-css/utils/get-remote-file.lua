local M = {}
local Curl = require("plenary.curl")
local async = require("plenary.async")

M.get_remote_file = async.wrap(function(url, callback)
	Curl.get(url, {
		callback = function(out)
			callback(out.status, out.body)
		end,
	})
end, 2)

return M
