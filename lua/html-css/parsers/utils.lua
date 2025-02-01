local utils = {}

---@type fun(file: string): string
utils.get_file_name = function(file)
	return vim.fn.fnamemodify(file, ":t:r")
end

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

---@type fun(href_value: string): string | nil
utils.provider_name = function(href_value)
	local filename = href_value:match("[^/]+%.css$") or href_value:match("[^/]+%.min%.css$")
	if filename then
		filename = filename:gsub("%.min%.css$", "")
		filename = filename:gsub("%.css$", "")
		filename = filename:gsub("^%l", string.upper)
		return filename
	end
	return nil
end

return utils
