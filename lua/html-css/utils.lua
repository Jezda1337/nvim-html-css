local uv = vim.uv
local utils = {}

-- FIXME
---@param self string
---@param str string
string.start_with = function(self, str)
    return self:sub(1, #str) == str
end


---@param path string
---@return boolean
utils.file_exists = function(path)
    if vim.fn.filereadable(path) == 1 then
        return true
    end
    return false
end

---@param path string
---@param cb function
utils.read_file = function(path, cb)
    uv.fs_open(path, "r", 438, function(err, fd)
        if err ~= nil then return end
        assert(not err, err)
        uv.fs_fstat(fd, function(err, stat)
            assert(not err, err)
            uv.fs_read(fd, stat.size, 0, function(err, data)
                assert(not err, err)
                uv.fs_close(fd, function(err)
                    assert(not err, err)
                    return cb(data)
                end)
            end)
        end)
    end)
end

---@param path string
---@return string
utils.get_source_name = function(path)
    if utils.is_remote(path) then
        return path:match("([^/]+)%.css$") or path:match("([^/]+)/$") or "remote"
    end
    return vim.fn.fnamemodify(path, ":t:r")
end

---@param lang string
---@param langs table<string>
utils.is_lang_enabled = function(lang, langs)
    langs = langs or {}
    for _, v in ipairs(langs) do
        if v == lang then
            return true
        end
    end
    return false
end

---@param path string
utils.is_remote = function(path)
    return path:match("^https?://") ~= nil
end

---@param path string
utils.is_local = function(path)
    return not utils.is_remote(path)
end

---@param path string
utils.resolve_path = function(path)
    if utils.is_remote(path) then return path end
    return uv.fs_realpath(path) or path or ""
end

---@param bufnr integer
---@return boolean
utils.is_special_buffer = function(bufnr)
    local buftype = vim.api.nvim_get_option_value("buftype", { buf = bufnr })
    if buftype ~= "" then
        return true
    end
    return false
end

return utils
