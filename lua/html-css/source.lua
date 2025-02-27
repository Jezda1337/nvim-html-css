local ok, cmp = pcall(require, "cmp")
local cache   = require "html-css.cache"
local utils   = require "html-css.utils"
if not ok then return end

local source = {}

---@param opts Config
function source:new(opts)
	self.opts = opts or {}

	return self
end

function source:get_trigger_character()
	return { '"', "'", " " }
end

function source:is_available()
	if utils.is_special_buffer(vim.api.nvim_get_current_buf()) then return false end

	-- grab the file extension
	local ext = vim.fn.expand("%:t:e")

	if not utils.is_lang_enabled(ext, self.opts.enable_on) then
		return false
	end

	local node = vim.treesitter.get_node()
	self.context = nil

	while node do
		if node:type() == "attribute" then
			local attr_name = vim.treesitter.get_node_text(node:child(0), 0)
			if attr_name == "class" or attr_name == "className" then
				self.context = "class"
				return true
			elseif attr_name == "id" then
				self.context = "id"
				return true
			end
		end
		node = node:parent()
	end

	return false
end

function source:complete(params, callback)
	local items = {}
	local bufnr = params.context.bufnr

	if self.context == "class" then
		items = self:_format_items(cache:get_classes(bufnr))
	elseif self.context == "id" then
		-- items = self:_format_items(cache:get_ids(bufnr))
	end

	callback({ items = items })
end

function source:_format_items(items)
	return vim.tbl_map(function(item)
		return {
			label = item.label,
			kind = cmp.lsp.CompletionItemKind.Field,
			menu = item.source_name and ("🠖 " .. item.source_name) or "[Unknown]",
			documentation = {
				kind = cmp.lsp.MarkupKind.Markdown,
				value = self:_create_docs(item)
			},
			dup = 1,
			data = {
				source_name = item.source_name,
				source_type = item.source_type
			}
		}
	end, items)
end

function source:_create_docs(item)
	return string.format(
		"```css\n/* Source: %s */\n%s\n```",
		item.source_name,
		item.block:gsub("%s*{%s*", " {\n  ")
		:gsub("%s*;%s*", ";\n  ")
		:gsub("%s*}", "\n}")
	)
end

function source:resolve(completion_item, callback)
	callback(completion_item)
end

function source:get_debug_name()
	return "html-css"
end

return source
