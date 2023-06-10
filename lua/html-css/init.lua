local Source = {}
local cmp = require("cmp")
local config = require("html-css.config")
local utils = require("html-css.utils.init")

-- vim.cmd("autocmd BufWritePost * lua require('html-css'):new()")

function Source:setup()
	require("cmp").register_source("bootstrap", Source)
end

function Source:new()
	self.cache = {}

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
	self.items = {}
	self.isRemote = "^https?://"

	if not self.cache.items then
		if config.get("style_sheets") then
			for _, uri in ipairs(config.get("style_sheets")) do
				if string.match(uri, self.isRemote) then
					self.status, self.response = utils.remote_file.get_remote_file(uri)
					if self.status ~= 200 then
						vim.notify("Link to external source is not valid", "error", {
							title = "Source not found",
						})
						return
					end

					self.classes = utils.remote_file.extract_selectors(self.response)
					self.unique_list = utils.remote_file.remove_duplicates(self.classes)

					for _, class in ipairs(self.unique_list) do
						table.insert(self.items, {
							label = class,
							kind = cmp.lsp.CompletionItemKind.Enum,
							menu = utils.remote_file.get_file_name(uri),
						})
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
					self.local_classes = utils.remote_file.extract_selectors(self.read_local_file)
					self.unique_local_list = utils.remote_file.remove_duplicates(self.local_classes)
					for _, class in ipairs(self.unique_local_list) do
						table.insert(self.items, {
							label = class,
							kind = cmp.lsp.CompletionItemKind.Enum,
							menu = utils.local_file.get_file_name(uri),
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
