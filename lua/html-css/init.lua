local Source = {}
local config = require("cmp.config")
local a = require("plenary.async")
local r = require("html-css.remote")
local l = require("html-css.local")
local e = require("html-css.embedded")

function Source:setup()
	require("cmp").register_source(self.source_name, Source)
end

function Source:new()
	self.source_name = "html-css"
	self.isRemote = "^https?://"
	self.remote_classes = {}
	self.items = {}

	-- reading user config
	self.user_config = config.get_source_config(self.source_name) or {}
	self.option = self.user_config.option or {}
	self.file_extensions = self.option.file_extensions or { "css", "scss", "less", "sass" }
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
		e.read_html_files(function(classes)
			for _, class in ipairs(classes) do
				table.insert(self.items, class)
			end
		end)
	end)

	-- read all local files on start
	a.run(function()
		l.read_local_files(self.file_extensions, function(classes)
			for _, class in ipairs(classes) do
				table.insert(self.items, class)
			end
		end)
	end)

	return self
end

function Source:complete(_, callback)
	vim.api.nvim_create_autocmd("BufWritePost", {
		-- pattern = { "*.css", "*.scss", "*.sass", "*.less" },
		pattern = self.file_extensions,
		command = ":silent !cmp run",
	})

	self.items = {}

	-- handle embedded styles
	a.run(function()
		e.read_html_files(function(classes)
			for _, class in ipairs(classes) do
				table.insert(self.items, class)
			end
		end)
	end)

	-- read all local files on start
	a.run(function()
		l.read_local_files(self.file_extensions, function(classes)
			for _, class in ipairs(classes) do
				table.insert(self.items, class)
			end
		end)
		for _, class in ipairs(self.remote_classes) do
			table.insert(self.items, class)
		end
	end)
	callback({ items = self.items, isComplete = false })
end

function Source:is_available()
	if not next(self.option) then
		return false
	end

	if not vim.tbl_contains(self.option.enable_on, vim.bo.filetype) then
		return false
	end

	local line = vim.api.nvim_get_current_line()

	if line:match('class%s-=%s-".-"') or line:match('className%s-=%s-".-"') then
		local cursor_pos = vim.api.nvim_win_get_cursor(0)
		local class_start_pos, class_end_pos = line:find('class%s-=%s-".-"')
		local className_start_pos, className_end_pos = line:find('className%s-=%s-".-"')

		if
			(
				class_start_pos
				and class_end_pos
				and cursor_pos[2] > class_start_pos
				and cursor_pos[2] <= class_end_pos
			)
			or (
				className_start_pos
				and className_end_pos
				and cursor_pos[2] > className_start_pos
				and cursor_pos[2] <= className_end_pos
			)
		then
			return true
		else
			return false
		end
	end
end

return Source:new()
