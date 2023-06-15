local Source = {}
local cmp = require("cmp")
local config = require("html-css.config")
local cmp_config = require("cmp.config")
local utils = require("html-css.utils.init")
local async = require("plenary.async")

function Source:before_init()
	if self.user_config.option.style_sheets then
		for _, uri in ipairs(self.user_config.option.style_sheets) do
			if string.match(uri, self.isRemote) then
				if not self.cache.items then -- run once
					async.run(function()
						utils.remote_file.get_remote_file(uri, function(status, body)
							if status ~= 200 then
								vim.notify("Link to external source is not valid", "error", {
									title = "Source not found",
								})
								return
							end

							self.classes = utils.extract_selectors(body)
							self.unique_list = utils.remove_duplicates(self.classes)

							for _, class in ipairs(self.unique_list) do
								table.insert(self.external_sources, {
									label = class,
									kind = cmp.lsp.CompletionItemKind.Enum,
									menu = utils.get_file_name(uri, "[^/]+%.%w+$"),
								})
							end
							for _, class in ipairs(self.external_sources) do
								table.insert(self.items, class)
							end
						end)
					end)
				end
			else
				self.local_file = utils.local_file.get_local_file(uri)
				if not self.local_file then
					vim.notify("There is no file " .. uri, "error", {
						title = "File not found",
					})
					return
				end

				self.read_local_file = utils.local_file.read_local_file(self.local_file)
				self.local_classes = utils.extract_selectors(self.read_local_file)
				self.unique_local_list = utils.remove_duplicates(self.local_classes)
				for _, class in ipairs(self.unique_local_list) do
					table.insert(self.local_sources, {
						label = class,
						kind = cmp.lsp.CompletionItemKind.Enum,
						menu = utils.get_file_name(uri, "[^/]+$"),
					})
				end

				for _, class in ipairs(self.local_sources) do
					table.insert(self.items, class)
				end
			end
		end
	end
	self.cache.items = self.items
end

function Source:setup()
	require("cmp").register_source(self.source_name, Source)
end

function Source:new()
	self.source_name = "html-css"
	self.cache = {}
	self.items = {}
	self.isRemote = "^https?://"
	self.external_sources = {}
	self.local_sources = {}
	self.fileStates = {}
	self.has_new_items = false
	self.user_config = {}

	-- reading user config
	self.user_config = cmp_config.get_source_config(self.source_name) or {}
	self.user_config.option = self.user_config.option or {}

	if not next(self.user_config.option) then
		error("There is no config?", 2)
	else
		for _, file in ipairs(self.user_config.option.style_sheets) do
			if not string.match(file, self.isRemote) then
				self.fileStates[file] = nil
			end
		end
		-- get external data and read local files before
		-- user start typing
		self.before_init(self)
	end

	-- require("html-css.utils.read-embeded-file")
	return self
end

function Source:is_available()
	-- if there is no user config then plugin is disabled
	if not next(self.user_config.option) then
		return false
	end

	-- if not vim.tbl_contains(self.user_config.option.file_types or config.get("file_types"), vim.bo.filetype) then
	-- 	return false
	-- end

	local line = vim.api.nvim_get_current_line()

	if line:match('class%s-=%s-".-"') or line:match('className%s-=%s-".-"') then
		local cursor_pos = vim.api.nvim_win_get_cursor(0)
		local class_start_pos, class_end_pos = line:find('class%s-=%s-".-"')
		local className_start_pos, className_end_pos = line:find('className%s-=%s-".-"')

		if
			(class_start_pos and class_end_pos and cursor_pos[2] > class_start_pos and cursor_pos[2] <= class_end_pos)
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
	if self.user_config.option.style_sheets then
		for _, file in ipairs(self.user_config.option.style_sheets) do
			if not string.match(file, self.isRemote) then
				local local_file = utils.local_file.get_local_file(file)
				local currentStat = vim.loop.fs_stat(local_file)
				if
					self.fileStates[local_file]
					and currentStat
					and self.fileStates[local_file].mtime.sec == currentStat.mtime.sec
				then
					local result = utils.remove_duplicate_tables_by_label(self.cache.items)
					callback({ items = result, isIncomplete = false })
				else
					-- reset ocal and items, to aboid class duplications
					self.local_sources = {}
					self.items = {}

					for _, class in ipairs(self.external_sources) do
						table.insert(self.items, class)
					end
					for _, class in ipairs(self.local_sources) do
						table.insert(self.items, class)
					end

					self.before_init(self)

					local result = utils.remove_duplicate_tables_by_label(self.items)

					self.has_new_items = true
					callback({ items = result, isIncomplete = false })
				end
				self.fileStates[local_file] = currentStat
				if self.has_new_items then
					self.fileStates[local_file] = currentStat
					self.cache.items = vim.deepcopy(self.items)
				end
			else
				-- in case there is no local files, then use cached items
				local result = utils.remove_duplicate_tables_by_label(self.cache.items)
				callback({ items = result, isIncomplete = false })
			end
		end
	end
end

---Return the debug name of this source (optional).
---@return string
function Source:get_debug_name()
	return "debug name"
end

---Return LSP's PositionEncodingKind.
---@NOTE: If this method is ommited, the default value will be `utf-16`.
---@return lsp.PositionEncodingKind
function Source:get_position_encoding_kind()
	return "utf-16"
end

---Resolve completion item (optional). This is called right before the completion is about to be displayed.
---Useful for setting the text shown in the documentation window (`completion_item.documentation`).
---@param completion_item lsp.CompletionItem
---@param callback fun(completion_item: lsp.CompletionItem|nil)
function Source:resolve(completion_item, callback)
	callback(completion_item)
end

function Source:execute(completion_item, callback)
	callback(completion_item)
end

return Source:new()
