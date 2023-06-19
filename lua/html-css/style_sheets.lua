local M = {}

local class_list = {}
local isRemote = "^https?://"
local a = require("plenary.async")
local c = require("plenary.curl")
local p = require("plenary.path")
local cmp = require("cmp")
local utils = require("html-css.utils")

M.get_remote_styles = a.wrap(function(url, cb)
	c.get(url, {
		callback = function(res)
			cb(res.status, res.body)
		end,
	})
end, 2)

function M.get_local_path(path)
	local file_path = p:new({ path, sep = "/" })
	if not file_path:exists() then
		return nil
	end

	return file_path:absolute()
end

function M.init(styles)
	if not styles then
		return
	end
	for _, path in ipairs(styles) do
		if path:match(isRemote) then
			a.run(function()
				M.get_remote_styles(path, function(status, classes)
					if status ~= 200 then
						return
					end
					local extract_selectors = utils.extract_selectors(classes)
					local remove_dup_selectors = utils.remove_duplicates(extract_selectors)
					for _, class in ipairs(remove_dup_selectors) do
						table.insert(class_list, {
							label = class,
							kind = cmp.lsp.CompletionItemKind.Enum,
							menu = utils.get_file_name(path, "[^/]+$"),
						})
					end
				end)
			end)
		else
			a.run(function()
				local file_path = M.get_local_path(path)

				if file_path == nil then
					return
				end

				local _, fd = a.uv.fs_open(file_path, "r", 438)
				local _, stat = a.uv.fs_fstat(fd)
				local _, data = a.uv.fs_read(fd, stat.size, 0)
				a.uv.fs_close(fd)
				local extract_selectors = utils.extract_selectors(data)
				local remove_dup_selectors = utils.remove_duplicates(extract_selectors)
				for _, class in ipairs(remove_dup_selectors) do
					table.insert(class_list, {
						label = class,
						kind = cmp.lsp.CompletionItemKind.Enum,
						menu = utils.get_file_name(path, "[^/]+$"),
					})
				end
			end)
		end
	end
	return class_list
end

return M
