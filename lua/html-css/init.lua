local Source = {}
local cmp = require("cmp")
local config = require("html-css.config")
local utils = require("html-css.utils.init")

function Source:setup()
	require("cmp").register_source("bootstrap", Source)
end

function Source:new()
	self.cache = {}

	return self
end

function Source:is_available()
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
	self.items = {}
	self.isRemote = "^https?://"

	if not self.cache.items then
		if config.get("style_sheets") then
			for _, uri in ipairs(config.get("style_sheets")) do
				if string.match(uri, self.isRemote) then
					self.response = utils.remote_file().get_remote_file(uri) -- pass the url and return body
					if not self.response then
						print("nema responsa")
					end
					self.classes = utils.remote_file().extract_selectors(self.response) -- extract classes form response
					self.unique_list = utils.remote_file().remove_duplicates(self.classes) -- remote duplicates from response

					for _, class in ipairs(self.unique_list) do
						table.insert(self.items, {
							label = class,
							kind = cmp.lsp.CompletionItemKind.Enum,
							documentation = "Bootstrap",
						})
					end
				else
					self.local_file = utils.local_file().get_local_file(uri)
					if not self.local_file then
						print("nema fajla")
					end
					self.read_local_file = utils.local_file().read_local_file(self.local_file)
					self.local_classes = utils.remote_file().extract_selectors(self.read_local_file)
					self.unique_local_list = utils.remote_file().remove_duplicates(self.local_classes)
					for _, class in ipairs(self.unique_local_list) do
						table.insert(self.items, {
							label = class,
							kind = cmp.lsp.CompletionItemKind.Enum,
							documentation = "Local Style",
						})
					end
				end
			end
		end
		callback({ items = self.items, isIncomplete = false })
		self.cache.items = self.items
	else
		callback({ items = self.cache.items, isIncomplete = false })
	end
end

return Source:new()
