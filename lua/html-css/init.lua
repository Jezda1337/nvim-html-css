local Source = {}
local config = require("cmp.config")
local a = require("plenary.async")
local r = require("html-css.remote")
local l = require("html-css.local")
local e = require("html-css.embedded")
local ts = vim.treesitter

function Source:setup()
	require("cmp").register_source(self.source_name, Source)
end

function Source:new()
	self.source_name = "html-css"
	self.isRemote = "^https?://"
	self.remote_classes = {}
	self.items = {}
	self.ids = {}

	-- reading user config
	self.user_config = config.get_source_config(self.source_name) or {}
	self.option = self.user_config.option or {}
	self.file_extensions = self.option.file_extensions or {}
	self.style_sheets = self.option.style_sheets or {}
	self.enable_on = self.option.enable_on or {}

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

	return self
end

function Source:complete(_, callback)
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

function Source:is_available()
	if not next(self.user_config) then
		return false
	end

	if not vim.tbl_contains(self.option.enable_on, vim.bo.filetype) then
		return false
	end

	local inside_quotes = ts.get_node({ bfnr = 0 })

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
		prev_sibling_name == "class"
		or prev_sibling_name == "id" and type == "quoted_attribute_value"
	then
		return true
	end

	return false
end

return Source:new()
