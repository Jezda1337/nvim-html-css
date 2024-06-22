local M = {}

local uv = vim.loop

M.readFile = function(path, cb)
	uv.fs_open(path, "r", 438, function(err, fd)
		assert(not err, err)
		uv.fs_fstat(fd, function(err, stat)
			assert(not err, err)
			uv.fs_read(fd, stat.size, 0, function(err, data)
				assert(not err, err)
				uv.fs_close(fd, function(err)
					assert(not err, err)
					return cb(data)
				end)
			end)
		end)
	end)
end

return M
