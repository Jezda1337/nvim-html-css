local utils = require("html-css.utils.init")
local function readAllHTMLFilesInProject()
	local projectPath = "/Users/radojejezdic/.config/nvim"
	local matches = {}

	local function readHTMLFile(filePath)
		local file = io.open(filePath, "r")
		if file then
			local content = file:read("*a")
			file:close()
			return content
		end
	end

	local function traverseDirectory(directory)
		local dir = vim.loop.fs_scandir(directory)
		if not dir then
			return
		end

		for entry in vim.loop.fs_scandir_next, dir do
			local filePath = directory .. "/" .. entry
			local fileType = vim.loop.fs_stat(filePath).type
			if fileType == "file" and filePath:match("%.html$") then
				local content = readHTMLFile(filePath)
				if content then
					for match in content:gmatch("<style[^>]*>([^<]+)</style>") do
						table.insert(matches, match)
					end
					local get_classes = utils.extract_selectors(content)
					for _, class in ipairs(get_classes) do
						print(class)
					end
				end
			elseif fileType == "directory" and entry ~= "." and entry ~= ".." then
				traverseDirectory(filePath)
			end
		end
	end

	traverseDirectory(projectPath)
end

readAllHTMLFilesInProject()
