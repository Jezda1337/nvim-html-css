local store = require("html-css.store")
---@type Source
local source = {
	new = function(self)
		return self
	end,
	complete = function(self) end,
	is_available = function(self)
		return false
	end,
	items = {},
}

local ts = vim.treesitter
local cmp_config = require("cmp.config")
local config = require("html-css.config")
local utils = require("html-css.utils")

local source_name = "html-css"

---@type Config
local user_config = cmp_config.get_source_config(source_name).option or {}
config = config.setup(user_config) -- override default config with the user_config

function source:complete(_, callback)
	callback({ items = self.items, isComplete = false })
end

function source:is_available()
	local bufnr = vim.api.nvim_get_current_buf()
	local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })

	if buftype ~= "" then
		return false
	end

	local current_node = ts.get_node({ bufnr = 0, lang = "html" })
	if not current_node then
		return false
	end

	local current_selector = nil

	-- grab the file extension
	local ext = vim.fn.expand("%:t:e")

	-- prevent autocompletion for .js file
	if vim.fn.expand("%:t:e") == "js" then
		return false
	end

	if not utils.isLangEnabled(ext, config.enable_on) then
		return false
	end

	local is_available = false

	if store.has(bufnr) then
		while current_node do
			if utils.isLangEnabled(ext, config.enable_on) then
				if current_node:type() == "attribute" then
					local attr_name_node = current_node:child(0)
					if attr_name_node and attr_name_node:type() == "attribute_name" then
						local identifier_name = ts.get_node_text(attr_name_node, 0)
						if
							identifier_name
							and (
								identifier_name == "className"
								or identifier_name == "class"
								or identifier_name == "id"
							)
						then
							current_selector = identifier_name
							is_available = true
						end
						break
					end
				end
				current_node = current_node:parent()
				if not current_node then
					break
				end
			end
		end

		-- prevent autocompletion to be called everywhere
		if not is_available then
			return false
		end

		local buffer_selectors = store.get(bufnr, "selectors") or { classes = {}, ids = {} }
		local global_selectors = store.get(999, "selectors") or { classes = {}, ids = {} }

		-- Merge global and buffer selectors
		local merged_selectors = {
			classes = vim.list_extend(vim.deepcopy(global_selectors.classes), buffer_selectors.classes),
			ids = vim.list_extend(vim.deepcopy(global_selectors.ids), buffer_selectors.ids),
		}

		if current_selector == "class" or current_selector == "className" then
			self.items = merged_selectors.classes
		else
			if current_selector == "id" then
				self.items = merged_selectors.ids
			end
		end
	end
	return true
end

function source:resolve(completion_item, callback)
	if not config.documentation.auto_show then
		return
	end
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
	callback(completion_item)
end

return source
