local util = {}

util.get_file_name = function(file)
    return vim.fn.fnamemodify(file, ":t:r")
end

return util
