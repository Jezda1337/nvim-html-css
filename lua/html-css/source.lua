local utils = require("html-css.utils")
local store = require("html-css.store")
local source = {}

source.items = {}

function source:new(opts)
	self.opts = opts or {}

	return self
end

function source:complete(_, callback)
	callback({ items = self.items })
end

function source:is_available()
	local ts = vim.treesitter
	local bufnr = vim.api.nvim_get_current_buf()
	local global_selectors = store:get(999, "selectors")

	if utils.is_special_buffer() then
		return false
	end

	-- if not utils.is_lang_enabled(self.enable_on) then
	-- 	return false
	-- end

	local current_node = ts.get_node({ bufnr = bufnr, lang = "html" })

	local allow_attrs = {
		"id",
		"class",
		"className",
	}

	local current_attr
	while current_node do
		if current_node:type() == "attribute" then
			if current_node:child(0):type() == "attribute_name" then
				if utils.contains(allow_attrs, ts.get_node_text(current_node:child(0), bufnr)) then
					current_attr = ts.get_node_text(current_node:child(0), bufnr)
					local buffer_selectors = store:get(bufnr, "selectors")
					local merged_selectors = {
						class = vim.list_extend(vim.deepcopy(global_selectors.class), buffer_selectors.class),
						id = vim.list_extend(vim.deepcopy(global_selectors.id), buffer_selectors.id),
					}
					print(current_attr)
					self.items = merged_selectors[current_attr]
					return true
				end
			end
			break
		end
		current_node = current_node:parent()
	end

	return false
end

function source:resolve(completion_item, callback)
	if self.opts.documentation.auto_show then
		completion_item.detail = nil
		if completion_item.block ~= nil then
			completion_item.documentation = {
				kind = require("cmp").lsp.MarkupKind.Markdown,
				value = ("```css\n%s%s\n```"):format(
					completion_item.label,
					completion_item
					.block
					:gsub("%s*{%s*", " {\n  ") -- Space before { and newline with indent after
					:gsub("%s*:%s*", ": ")
					:gsub("%s*;%s*", ";\n  ") -- Newline and indent after each ;
					:gsub("%s*}%s*", "\n}") -- Newline before }
					:gsub("!", " !")
				),
			}
		end
	end
	callback(completion_item)
end

return source
