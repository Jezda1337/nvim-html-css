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
        if err ~= nil then
            return
        end
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

local function normalize_path(p)
    if not p or p == "" then
        return p
    end
    local np = vim.fs.normalize(p) -- cleans ./ and ../
    return np
end

---@param path string
---@param base_dir string|nil  -- directory of current file
utils.resolve_path = function(path, base_dir)
    local cwd = uv.cwd()

    if utils.is_remote(path) then
        return path
    end
    if not path or path == "" then
        return ""
    end

    -- normalize ./ and ../ relative to base_dir
    if path:match("^%.") and base_dir then
        local abs = vim.fs.normalize(vim.fs.joinpath(base_dir, path))
        if utils.file_exists(abs) then
            return normalize_path(abs)
        end
    end

    -- absolute starting with /
    if path:match("^/") then
        local relative_path = path:gsub("^/", "")
        local candidate_paths = {
            vim.fs.joinpath(cwd, relative_path),
            vim.fs.joinpath(cwd, "public", relative_path),
            vim.fs.joinpath(cwd, "static", relative_path),
        }
        for _, p in ipairs(candidate_paths) do
            if utils.file_exists(p) then
                return normalize_path(p)
            end
        end
    end

    -- bare path: try relative to base_dir, then public/static
    local candidates = {}
    if base_dir then
        table.insert(candidates, vim.fs.joinpath(base_dir, path))
    end
    vim.list_extend(candidates, {
        vim.fs.joinpath(cwd, "public", path),
        vim.fs.joinpath(cwd, "static", path),
    })

    for _, cand in ipairs(candidates) do
        if utils.file_exists(cand) then
            return normalize_path(cand)
        end
    end

    return path
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

utils.format_css = function(item)
    local css = item.block
    
    -- Extract selector and body
    local selector = item.label
    local body = css:match("{(.*)}") or ""

    -- Split body into lines, trim whitespace
    local rules = {}
    for rule in body:gsub(";%s*$", ""):gmatch("[^;]+") do
        local trimmed = vim.trim(rule)
        if trimmed ~= "" then
            table.insert(rules, trimmed)
        end
    end

    -- Format each rule
    local formatted_rules = {}
    for _, rule in ipairs(rules) do
        local property, value = rule:match("^([%w%-]+)%s*:%s*(.*)$")

        if property and value then
            -- Trim and normalize value
            value = vim.trim(value)

            -- Ensure !important has space
            if value:find("!important") then
                value = value:gsub("%s*!important%s*", " !important")
            end

            table.insert(formatted_rules, string.format("  %s: %s;", property, value))
        else
            -- Fallback for malformed rules (e.g. comments or nested)
            local trimmed = vim.trim(rule)
            if trimmed:sub(1, 1) == "/" then -- Comment
                table.insert(formatted_rules, string.format("  %s", trimmed))
            else
                table.insert(formatted_rules, string.format("  %s;", trimmed))
            end
        end
    end

    -- If no rules, still include closing brace
    if #formatted_rules == 0 then
        table.insert(formatted_rules, "  /* No styles */")
    end

    local prefix = (item.type == "id") and "#" or "."
    local selector_line = prefix .. selector .. " {"
    
    local css_code = table.concat({
        selector_line,
        table.concat(formatted_rules, "\n"),
        "}",
    }, "\n")

    -- Wrap in media query if present
    if item.media then
        css_code = "@media " .. item.media .. " {\n" .. css_code:gsub("\n", "\n  ") .. "\n}"
    end

    return table.concat({
        "```css",
        css_code,
        "```",
    }, "\n")
end

return utils
