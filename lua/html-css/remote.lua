local M = {}
local a = require("plenary.async")
local c = require("plenary.curl")
local u = require("html-css.utils.init")
local cmp = require("cmp")

local classes = {}

local get_remote_styles = a.wrap(function(url, cb)
	c.get(url, {
		callback = function(res)
			cb(res.status, res.body)
		end,
	})
end, 2)

M.init = a.wrap(function(url, cb)
	if not url then
		return {}
	end

	get_remote_styles(url, function(status, body)
		if not status == 200 then
			return {}
		end
		local extract_selectors = u.extract_selectors(body)
		local remote_dup_selectors = u.remove_duplicates(extract_selectors)
		for _, class in ipairs(remote_dup_selectors) do
			table.insert(classes, {
				label = class,
				kind = cmp.lsp.CompletionItemKind.Enum,
				menu = u.get_file_name(url, "[^/]+$"),
			})
		end
		cb(classes)
	end)
end, 2)

return M
