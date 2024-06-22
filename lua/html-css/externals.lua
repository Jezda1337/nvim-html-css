local M = {}

local store = require("html-css.store")
local extractor = require("html-css.extractor")
local fetch = require("html-css.fetch").fetch
local readFile = require("html-css.helpers").readFile

local function url_exists(url, list)
	for _, link in ipairs(list) do
		if link.url == url or link.path == url then
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
		local extracted_selectors = extractor.selectors(ctx.stdout, link.url)
		selectors.classes =
			vim.list_extend(selectors.classes, extracted_selectors.classes)
		selectors.ids = vim.list_extend(selectors.ids, extracted_selectors.ids)

		link.fetched = true
		link.available = true
		store.set(bufnr, "selectors", selectors)
	end
end

---@type fun(bufrn: number, hrefs: Externals , externals: Externals):Externals
local function remove_missing_hrefs(bufnr, hrefs, externals)
	local updated_externals = {
		cdn = {},
		locals = {},
	}
	local selectors = store.get(bufnr, "selectors")
		or {
			ids = {},
			classes = {},
		}

	for type, external in pairs(externals) do
		for _, link in ipairs(external) do
			if url_exists(link.url or link.path, hrefs[type]) then
				table.insert(updated_externals[type], link)
			else
				selectors.classes = vim.tbl_filter(function(class)
					return class.source ~= (link.url or link.path)
				end, selectors.classes)
				selectors.ids = vim.tbl_filter(function(id)
					return id.source ~= (link.url or link.path)
				end, selectors.ids)
			end
		end
	end

	store.set(bufnr, "selectors", selectors)
	return updated_externals
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

	externals = remove_missing_hrefs(bufnr, hrefs, externals)

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
				local extracted_selectors = extractor.selectors(data, file.path)
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
				file.available = true
				store.set(bufnr, "selectors", selectors)
			end)
		end
	end
end

return M
