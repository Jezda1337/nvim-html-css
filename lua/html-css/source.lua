local ok, cmp = pcall(require, "cmp")
local cache   = require("html-css.cache")
if not ok then return end

local source = {}

function source:get_trigger_character()
	return { '"', "'", " " }
end

function source:is_available()
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
		items = self:_format_items(cache:_get_classes(bufnr))
	elseif self.context == "id" then
		items = self:_format_items(cache:_get_ids(bufnr))
	end

	callback({items = items})
end

function source:_format_items(items)
	return vim.tbl_map(function(item)
		return {
			label = item.label,
			kind = cmp.lsp.CompletionItemKind.Field,
			documentation = {
				kind = cmp.lsp.MarkupKind.Markdown,
				value = self:_create_docs(item)
			},
			dup = 1,
			data = item
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
