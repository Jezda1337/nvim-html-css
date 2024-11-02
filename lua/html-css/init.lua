local Source = {}
local config = require("cmp.config")
local a = require("plenary.async")
local r = require("html-css.remote")
local l = require("html-css.local")
local e = require("html-css.embedded")
local h = require("html-css.hrefs")
local ts = vim.treesitter
local tsu = require("nvim-treesitter.ts_utils")
local parsers = require("nvim-treesitter.parsers")

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
	self.dir_to_exclude = self.option.dir_to_exclude or {}
	self.style_sheets = self.option.style_sheets or {}
	self.enable_on = self.option.enable_on or {}

	table.insert(self.dir_to_exclude, "node_modules") -- node_modules as default dit to be excluded

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
			e.read_html_files(self.dir_to_exclude, function(classes, ids)
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
			l.read_local_files(self.file_extensions, self.dir_to_exclude, function(classes, ids)
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
	if vim.tbl_count(rootDir) ~= 0 then
		self.items = {}
		self.ids = {}

		-- handle embedded styles
		a.run(function()
			e.read_html_files(self.dir_to_exclude, function(classes, ids)
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
			l.read_local_files(self.file_extensions, self.dir_to_exclude, function(classes, ids)
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

		if self.current_selector == "class" or self.current_selector == "className" then
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

	local bufnr = vim.api.nvim_get_current_buf()
	local parser = parsers.get_parser(bufnr)
	local node_at_cursor = tsu.get_node_at_cursor()

	if node_at_cursor == nil then
		return
	end

	local current_node = node_at_cursor
	local lang = parser:lang()

	while current_node do
		if lang == "html" or lang == "svelte" or lang == "vue" then
			if current_node:type() == "attribute_name" then
				local identifier_name = ts.get_node_text(current_node, 0)
				if
					identifier_name == "className"
					or identifier_name == "class"
					or identifier_name == "id"
				then
					self.current_selector = identifier_name
					return true
				end
				break
			end
			current_node = current_node:prev_named_sibling()
		else
			if current_node:type() == "jsx_attribute" then
				if current_node:child(0):type() == "property_identifier" then
					local identifier_name = ts.get_node_text(current_node:child(0), 0)
					if
						identifier_name == "className"
						or identifier_name == "class"
						or identifier_name == "id"
					then
						self.current_selector = identifier_name
						return true
					end
					break
				end
			end
			current_node = current_node:parent()
		end
	end

	return false
end

return Source:new()
