local cache = require "html-css.cache"
local ts = vim.treesitter

local definition = {}

---@return boolean
---@param word string
local function get_selector(word)
    local node = ts.get_node()
    local bufnr = vim.api.nvim_get_current_buf()

    local selectors = nil
    local context = nil


    while node do
        if node:type() == "attribute" or node:type() == "jsx_attribute" then
            local attr_name = ts.get_node_text(node:child(0), 0)
            if attr_name == "class" or attr_name == "className" then
                context = "class"
                break
            elseif attr_name == "id" then
                context = "id"
                break
            end
        end
        node = node:parent()
    end

    if context == "id" then
        selectors = cache:get_ids(bufnr)
    elseif context == "class" then
        selectors = cache:get_classes(bufnr)
    elseif context == nil then
        return false
    end

    if selectors ~= nil then
        for _, item in pairs(selectors) do
            if item.label == word and item.range then
                vim.lsp.util.show_document({
                    uri = vim.uri_from_fname(item.source_name),
                    range = item.range,
                    focus = true
                }, "utf-32")
                return true
            end
        end
    end

    return false
end

---@param opts Definition
function definition.setup(opts)
    vim.keymap.set("n", opts.bind, function()
        local word = vim.fn.expand("<cword>")

        -- if not found selector fall back to the default lps definition
        if not get_selector(word) then
            vim.lsp.buf.definition()
        end
    end, { noremap = true, silent = true })
end

return definition
