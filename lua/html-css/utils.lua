local utils = {}

---@type fun(path: string, cb: fun(stdout: string))
utils.readFile = function(path, cb)
	local uv = vim.loop
	uv.fs_open(vim.fn.expand("%:p:h") .. "/" .. path, "r", 438, function(err, fd)
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

---@type fun(file: string):string
utils.get_file_name = function(file)
	return vim.fn.fnamemodify(file, ":t:r")
end

---@type fun(source: string, opts: table, cb: fun(ctx: table))
utils.curl = function(source, opts, cb)
	local def_opts = { text = true }
	opts = vim.tbl_extend("force", def_opts, opts)

	vim.system({ "curl", source }, opts, function(ctx)
		if not cb then return end
		cb(ctx)
	end)
end


---@type fun(t: table, v:integer | string): boolean
utils.contains = function(t, v)
	for _, k in ipairs(t) do
		if k == v then
			return true
		end
	end
	return false
end

---@type fun():boolean
utils.is_special_buffer = function()
	local bufnr = vim.api.nvim_get_current_buf()
	local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
	if buftype ~= "" then
		return true
	end
	return false
end

---@type fun(langs: table<string>):boolean
utils.is_lang_enabled = function(langs)
	langs = langs or {}
	local lang = vim.fn.expand("%:t:e")

	for _, v in ipairs(langs) do
		if v == lang then
			return true
		end
	end
	return false
end

---@type fun(url: string): boolean
utils.is_link = function(url)
	local is_remote = "^https?://"
	return url:match(is_remote) ~= nil
end

---@type fun(url: string): boolean
utils.is_local = function(url)
	return not utils.is_link(url)
end


return utils
