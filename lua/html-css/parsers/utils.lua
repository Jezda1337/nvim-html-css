local utils = {}

---@type fun(lang: string, qs: string, bufnr: integer): TSNode, vim.treesitter.Query
utils.parse = function(lang, qs, bufnr)
	local ts = vim.treesitter

	local root = ts.get_parser(bufnr, lang):parse()[1]:root()
	local query = ts.query.parse(lang, qs)

	return root, query
end

---@type fun(lang: string, qs: string, s: string): TSNode, vim.treesitter.Query
utils.string_parse = function(lang, qs, s)
	local ts = vim.treesitter

	local root = ts.get_string_parser(s, lang):parse()[1]:root()
	local query = ts.query.parse(lang, qs)

	return root, query
end

return utils
