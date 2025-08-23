local cache = require "html-css.cache"
local u = require "html-css.utils"
local ts = vim.treesitter
local hover = {}

-- TODO some parts like format_css already exist in soruce.lua and needs to be moved into utils
-- also some other functionality are needs cleanup like looking into treesitter nodes.

-- TODO maybe make width and height configurable

local WIDE_HEIGHT = 80

-- FIXME better css formatting is needed
---@param item Selector

---@param word string
---@param opts Hover
---@return boolean
local function get_block(word, opts)
    local node = ts.get_node()
    local bufnr = vim.api.nvim_get_current_buf()
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

    local selectors = context == "id" and cache:get_ids(bufnr) or (context == "class" and cache:get_classes(bufnr))

    if selectors then
        local content = {}
        for _, item in pairs(selectors) do
            if item.label == word then
                table.insert(content, u.format_css(item))
            end
        end

        if #content > 0 then
            local win_opts = {
                max_height = math.floor(WIDE_HEIGHT * (WIDE_HEIGHT / vim.o.lines)),
                max_width = math.floor((WIDE_HEIGHT * 2) * (vim.o.columns / (WIDE_HEIGHT * 2 * 16 / 9))),
                wrap = opts.wrap,
                relative = opts.position,
                border = opts.border,
            }
            vim.lsp.util.open_floating_preview(content, "markdown", win_opts)
            return true
        end
    end

    return false
end

---@param opts Hover
function hover.setup(opts)
    vim.opt.iskeyword:append("-")

    vim.keymap.set("n", opts.bind, function()
        local word = vim.fn.expand("<cword>")
        if not get_block(word, opts) then
            -- TODO FIXME - if current buffer doesn't have any lsp attached then we are fckt
            -- i need to find out a fallback
            vim.lsp.buf.hover()
        end
    end, { noremap = true, silent = true })
end

return hover
