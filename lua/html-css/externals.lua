local M = {}

local store = require("html-css.store")
local extractor = require("html-css.extractor")
local fetch = require("html-css.fetch").fetch
local uv = vim.loop

local function readFile(path, callback)
	uv.fs_open(path, "r", 438, function(err, fd)
		assert(not err, err)
		uv.fs_fstat(fd, function(err, stat)
			assert(not err, err)
			uv.fs_read(fd, stat.size, 0, function(err, data)
				assert(not err, err)
				uv.fs_close(fd, function(err)
					assert(not err, err)
					return callback(data)
				end)
			end)
		end)
	end)
end

local function url_exists(url, list)
	for _, link in ipairs(list) do
		if link.url == url then
			return true
		end
	end
	return false
end

---@type fun(ctx: Ctx, link: Link, bufnr: number)
local extractDataFromLinks = function(ctx, link, bufnr)
	local selectors = store.get(bufnr, "selectors")
		or {
			ids = {},
			classes = {},
		}

	if ctx.code == 0 then
		local extracted_selectors = extractor.selectors(ctx.stdout)
		selectors.classes =
			vim.list_extend(selectors.classes, extracted_selectors.classes)
		selectors.ids = vim.list_extend(selectors.ids, extracted_selectors.ids)

		link.fetched = true
		store.set(bufnr, "selectors", selectors)
	end
end

---@type fun(bufnr: number, file_name: string)
M.init = function(bufnr, file_name)
	-- so this init fun extract hrefs on enter the buf or save,
	-- checks does we already  have this in store, and if we does
	-- then it will skip fetching, if not then we will fetch
	-- only new href that is added
	local hrefs = extractor.href()
	local externals = store.get(bufnr, "externals")
		or {
			cdn = {},
			locals = {},
		}

	-- checking does the url already exist in the store
	for type, external in pairs(hrefs) do
		for _, v in ipairs(external) do
			if not url_exists(v.url, externals[type]) then
				table.insert(externals[type], v)
			end
		end
	end

	store.set(bufnr, "externals", externals) -- maybe this needs refactoring since we write the same stuff to store evrytime

	-- looping over cdns and fetch them if they are not fetch if tehy are just skip
	for _, link in pairs(externals.cdn) do
		if not link.fetched then
			local opts = {}
			fetch(link.url, opts, function(ctx)
				print("Fetching:", link.url)
				extractDataFromLinks(ctx, link, bufnr)
			end)
		end
	end

	-- looping over the locals and read files and store selectors
	for _, file in pairs(externals.locals) do
		if not file.fetched then
			print("Fetching:", file.path)
			readFile(file.path, function(data)
				local extracted_selectors = extractor.selectors(data)
				local selectors = store.get(bufnr, "selectors")
					or {
						ids = {},
						classes = {},
					}
				selectors.classes = vim.list_extend(
					selectors.classes,
					extracted_selectors.classes
				)
				selectors.ids =
					vim.list_extend(selectors.ids, extracted_selectors.ids)

				file.fetched = true
				store.set(bufnr, "selectors", selectors)
			end)
		end
	end
end

return M
