local utils = {}

utils.readFile = function(path, cb)
	local uv = vim.loop
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

utils.isLangEnabled = function(lang, langs)
  langs = langs or {}
	for _, v in ipairs(langs) do
		if v == lang then
			return true
		end
	end
	return false
end

return utils
