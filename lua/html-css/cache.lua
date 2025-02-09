local cache = {}
local uv = vim.uv

local function ensure_directory(path, mode)
	local stat = uv.fs_stat(path)
	if stat and stat.type == "directory" then
		return "Already exists"
	end

	local ok, err = uv.fs_mkdir(path, mode)
	if not ok then
		return err
	end

	return "Created"
end

local base_path = vim.fn.stdpath("data") .. "/nvim-html-css"
local cache_path = base_path .. "/cache"
local mode = 493

for _, path in ipairs({base_path, cache_path}) do
	local result = ensure_directory(path, mode)
	if result ~= "Already exists" and result ~= "Created" then
		print("Error creating directory: " .. path .. " - " .. result)
		return
	end
end

local function url_to_file_name(url)
	return cache_path .. "/"  .. vim.fn.sha256(url) .. ".json"
end

function cache:get(url)
	local file_name = url_to_file_name(url)
	local f = io.open(file_name, "r")
	if not f then return nil end
	local content = f:read("*a")
	f:close()

	local ok, data = pcall(vim.json.decode, content)
	if not ok and not data then return nil end
	if os.time() - data.timestamp > 86400 then
		os.remove(file_name)
		return nil
	end
	return data.selectors
end
function cache:set(url, selectors)
	local file_name = url_to_file_name(url)

	local cache_data = {
		url = url,
		timestamp = os.time(),
		selectors = selectors
	}

	local f = io.open(file_name, "w")
	if f then
		f:write(vim.json.encode(cache_data))
		f:close()
	end
end

function cache:has(url)
	local file_name = url_to_file_name(url)
	local f = io.open(file_name, "r")
	if not f then return false end

	local content = f:read("*a")
	f:close()

	local ok, data = pcall(vim.json.decode, content)
	if not ok or not data then return false end

	if os.time() - data.timestamp > 86400 then
		os.remove(file_name)
		return false
	end

	return true
end

function cache:clear(url)
	if url then
		local file_name = url_to_file_name(url)
		os.remove(file_name)
	else
		local handle = uv.fs_scandir(cache_path)
		if handle then
			while true do
				local name = uv.fs_scandir_next(handle)
                if not name then break end
				os.remove(cache_path .. "/" .. name)
			end
		end
	end
end

return cache
