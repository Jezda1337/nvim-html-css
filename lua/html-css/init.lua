local Source = {}
local cmp = require("cmp")
local config = require("html-css.config")
local utils = require("html-css.utils.init")
local async = require("plenary.async")

function Source:before_init()
	if not self.cache.items then
		if config.get("style_sheets") then
			for _, uri in ipairs(config.get("style_sheets")) do
				if string.match(uri, self.isRemote) then
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
								table.insert(self.items, {
									label = class,
									kind = cmp.lsp.CompletionItemKind.Enum,
									menu = utils.get_file_name(uri, "[^/]+%.%w+$"),
								})
							end
						end)
					end)
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
						table.insert(self.items, {
							label = class,
							kind = cmp.lsp.CompletionItemKind.Enum,
							menu = utils.get_file_name(uri, "[^/]+$"),
						})
					end
				end
			end
		end
		self.cache.items = self.items
	end
end

function Source:setup()
	require("cmp").register_source("html-css", Source)
end

function Source:new()
	self.cache = {}
	self.items = {}
	self.isRemote = "^https?://"

	self.before_init(self) -- fetch the data and read the file

	-- require("html-css.utils.read-embeded-file")
	return self
end

function Source:is_available()
	if not vim.tbl_contains(config.get("file_types"), vim.bo.filetype) then
		return false
	end

	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	local lines = vim.api.nvim_buf_get_lines(0, row - 1, row, false)
	local line = lines[1]

	local classProperty = line:match('%sclass%s*=%s*"(.-)"') or line:match('%sclassName%s*=%s*"(.-)"')
	if not classProperty then
		return false
	end

	local start, finish = line:find('"' .. classProperty .. '"')
	if not (start and finish >= col) then
		return false
	end

	return true
end

function Source:complete(_, callback)
	-- if not self.cache.items then
	-- 	if config.get("style_sheets") then
	-- 		for _, uri in ipairs(config.get("style_sheets")) do
	-- 			if string.match(uri, self.isRemote) then
	-- 				async.run(function()
	-- 					utils.remote_file.get_remote_file(uri, function(status, body)
	-- 						if status ~= 200 then
	-- 							vim.notify("Link to external source is not valid", "error", {
	-- 								title = "Source not found",
	-- 							})
	-- 							return
	-- 						end

	-- 						self.classes = utils.extract_selectors(body)
	-- 						self.unique_list = utils.remove_duplicates(self.classes)

	-- 						for _, class in ipairs(self.unique_list) do
	-- 							table.insert(self.items, {
	-- 								label = class,
	-- 								kind = cmp.lsp.CompletionItemKind.Enum,
	-- 								menu = utils.get_file_name(uri, "[^/]+%.%w+$"),
	-- 							})
	-- 						end
	-- 					end)
	-- 				end)
	-- 			else
	-- 				self.local_file = utils.local_file.get_local_file(uri)
	-- 				if not self.local_file then
	-- 					vim.notify("There is no file " .. uri, "error", {
	-- 						title = "File not found",
	-- 					})
	-- 					return
	-- 				end

	-- 				self.read_local_file = utils.local_file.read_local_file(self.local_file)
	-- 				self.local_classes = utils.extract_selectors(self.read_local_file)
	-- 				self.unique_local_list = utils.remove_duplicates(self.local_classes)
	-- 				for _, class in ipairs(self.unique_local_list) do
	-- 					table.insert(self.items, {
	-- 						label = class,
	-- 						kind = cmp.lsp.CompletionItemKind.Enum,
	-- 						menu = utils.get_file_name(uri, "[^/]+$"),
	-- 					})
	-- 				end
	-- 			end
	-- 		end
	-- 	end
	-- 	callback({ items = self.items, isIncomplete = false })
	-- 	self.cache.items = self.items
	-- else
	-- 	callback({ items = self.cache.items, isIncomplete = false })
	-- end

	if not self.cache.items then
		callback({ items = self.items, isIncomplete = false })
		self.cache.items = self.items
	else
		callback({ items = self.cache.items, isIncomplete = false })
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
