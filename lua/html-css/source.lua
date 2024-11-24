local store = require("html-css.store")
---@type Source
local source = {}
source.items = {}

local tsu = require("nvim-treesitter.ts_utils")
local parsers = require("nvim-treesitter.parsers")
local ts = vim.treesitter
local cmp_config = require("cmp.config")

local source_name = "html-css"
---@type Config
local config = cmp_config.get_source_config(source_name).option or {}

function source:complete(_, callback)
	callback({ items = self.items, isComplete = false })
end

function source:is_available()
	local bufnr = vim.api.nvim_get_current_buf()
	local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
	if buftype ~= "" then
		return false
	end
	-- Testing is needed with the larget file.
	-- could be performance issue
	vim.treesitter.get_parser(0):parse()
	local current_node = tsu.get_node_at_cursor()
	if not current_node then
		return false
	end

	local current_selector = nil
	local parser = parsers.get_parser(bufnr)
	local lang = parser:lang()

	local is_available = false

	if config.spa.enable then
		bufnr = 0
	end

	if store.has(bufnr) then
		while current_node do
			if lang == "html" or lang == "svelte" or lang == "vue" then
				if current_node:type() == "attribute_name" then
					local identifier_name = ts.get_node_text(current_node, 0)
					if
						identifier_name == "className"
						or identifier_name == "class"
						or identifier_name == "id"
					then
						current_selector = identifier_name
						is_available = true
					end
					break
				end
				current_node = current_node:prev_named_sibling()
			else
				if current_node:type() == "jsx_attribute" then
					if
						current_node:child(0):type() == "property_identifier"
					then
						local identifier_name =
							ts.get_node_text(current_node:child(0), 0)
						if
							identifier_name == "className"
							or identifier_name == "class"
							or identifier_name == "id"
						then
							current_selector = identifier_name
							is_available = true
						end
						break
					end
				end
				current_node = current_node:parent()
			end
		end
	end

	if not is_available then
		return false
	end

	local selectors = store.get(bufnr, "selectors")
	if current_selector == "class" or current_selector == "className" then
		self.items = selectors.classes
	else
		if current_selector == "id" then
			self.items = selectors.ids
		end
	end
	return true
end

return source