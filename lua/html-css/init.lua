local Source = {}
local config = require("cmp.config")
local a = require("plenary.async")
local Job = require("plenary.job")
local r = require("html-css.remote")
local l = require("html-css.local")
local e = require("html-css.embedded")
local h = require("html-css.hrefs")

local ts = vim.treesitter

local scan = require("plenary.scandir")
local rootDir = scan.scan_dir(".", {
	hidden = true,
	add_dirs = true,
	depth = 1,
	respect_gitignore = true,
	search_pattern = function(entry)
		local subEntry = entry:sub(3) -- remove ./
		-- %f[%a]git%f[^%a] -- old regex for matching .git
		return subEntry:match(".git$") or subEntry:match("package.json") -- if project contains .git folder or package.json its gonna work
	end,
})

local function mrgtbls(t1, t2)
	for _, v in ipairs(t2) do
		table.insert(t1, v)
	end
	return t1
end

function Source:setup()
	require("cmp").register_source(self.source_name, Source)
end

function Source:new()
	self.source_name = "html-css"
	self.isRemote = "^https?://"
	self.remote_classes = {}
	self.items = {}
	self.ids = {}
	self.href_links = {}

	-- reading user config
	self.user_config = config.get_source_config(self.source_name) or {}
	self.option = self.user_config.option or {}
	self.file_extensions = self.option.file_extensions or {}
	self.style_sheets = self.option.style_sheets or {}
	self.enable_on = self.option.enable_on or {}

	-- Get the current working directory
	local current_directory = vim.fn.getcwd()

	-- Check if the current directory contains a .git folder
	local git_folder_exists = vim.fn.isdirectory(current_directory .. "/.git")

	-- if git_folder_exists == 1 then
	if vim.tbl_count(rootDir) ~= 0 then
		self.href_links = h.get_hrefs()
		self.style_sheets = mrgtbls(self.style_sheets, self.href_links) -- merge lings together

		-- init the remote styles
		for _, url in ipairs(self.style_sheets) do
			if url:match(self.isRemote) then
				a.run(function()
					r.init(url, function(classes)
						for _, class in ipairs(classes) do
							table.insert(self.items, class)
							table.insert(self.remote_classes, class)
						end
					end)
				end)
			end
		end

		-- handle embedded styles
		a.run(function()
			e.read_html_files(function(classes, ids)
				for _, class in ipairs(classes) do
					table.insert(self.items, class)
				end
				for _, id in ipairs(ids) do
					table.insert(self.ids, id)
				end
			end)
		end)

		-- read all local files on start
		a.run(function()
			l.read_local_files(self.file_extensions, function(classes, ids)
				for _, class in ipairs(classes) do
					table.insert(self.items, class)
				end
				for _, id in ipairs(ids) do
					table.insert(self.ids, id)
				end
			end)
		end)
	end

	return self
end

function Source:complete(_, callback)
	-- Get the current working directory
	local current_directory = vim.fn.getcwd()

	-- Check if the current directory contains a .git folder
	local git_folder_exists = vim.fn.isdirectory(current_directory .. "/.git")

	-- if git_folder_exists == 1 then
	if vim.tbl_count(rootDir) ~= 0 then
		self.items = {}
		self.ids = {}

		-- handle embedded styles
		a.run(function()
			e.read_html_files(function(classes, ids)
				for _, class in ipairs(classes) do
					table.insert(self.items, class)
				end
				for _, id in ipairs(ids) do
					table.insert(self.ids, id)
				end
			end)
		end)

		-- read all local files on start
		a.run(function()
			l.read_local_files(self.file_extensions, function(classes, ids)
				for _, class in ipairs(classes) do
					table.insert(self.items, class)
				end
				for _, id in ipairs(ids) do
					table.insert(self.ids, id)
				end
			end)
			for _, class in ipairs(self.remote_classes) do
				table.insert(self.items, class)
			end
		end)

		if self.current_selector == "class" then
			callback({ items = self.items, isComplete = false })
		else
			if self.current_selector == "id" then
				callback({ items = self.ids, isComplete = false })
			end
		end
	end
end

function Source:is_available()
	if not next(self.user_config) then
		return false
	end

	if not vim.tbl_contains(self.option.enable_on, vim.bo.filetype) then
		return false
	end

	local inside_quotes = ts.get_node({ bfnr = 0, lang = "html" })

	if inside_quotes == nil then
		return false
	end

	local type = inside_quotes:type()

	local prev_sibling = inside_quotes:prev_named_sibling()
	if prev_sibling == nil then
		return false
	end

	local prev_sibling_name = ts.get_node_text(prev_sibling, 0)

	if prev_sibling_name == "class" then
		self.current_selector = "class"
	elseif prev_sibling_name == "id" then
		self.current_selector = "id"
	end

	if
		prev_sibling_name == "class" or prev_sibling_name == "id" and type == "quoted_attribute_value"
	then
		return true
	end

	return false
end

return Source:new()
