local Source = {}
local cmp_config = require("cmp.config")
local utils = require("html-css.utils")

function Source:before_init()
	local style_sheets_classes =
		require("html-css.style_sheets").init(self.user_config.option.style_sheets)
	for _, class in ipairs(style_sheets_classes) do
		table.insert(self.items, class)
	end
end

function Source:setup()
	require("cmp").register_source(self.source_name, Source)
end

function Source:new()
	self.source_name = "html-css"
	self.cache = {}
	self.items = {}
	self.user_config = {}

	-- reading user config
	self.user_config = cmp_config.get_source_config(self.source_name) or {}
	self.user_config.option = self.user_config.option or {}

	self:before_init()

	return self
end

function Source:is_available()
	-- if there is no user config then plugin is disabled
	if not next(self.user_config.option) then
		return false
	end

	if not vim.tbl_contains(self.user_config.option.file_types, vim.bo.filetype) then
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

function Source:complete(_, callback)
	if self.cache.items ~= nil then
		local items = utils.remove_duplicate_tables_by_label(self.cache.items)
		callback({ items = items, isIncomplete = false })
	else
		self:before_init()
		local items = utils.remove_duplicate_tables_by_label(self.items)
		callback({ items = items, isIncomplete = false })
		self.cache.items = self.items
	end
end

return Source:new()
