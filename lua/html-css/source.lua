local u = require("html-css.util")
local source = {
    items = {
        {
            label = "test",
            kind = 13,
        },
    },
}

function source:new(enable_on)
    self.enable_on = enable_on

    return self
end

function source:complete(_, callback)
    callback({ items = self.items })
end

function source:is_available()
    local ts = vim.treesitter
    local bufnr = vim.api.nvim_get_current_buf()

    if u.is_special_buffer() then
        return false
    end

    if not u.is_lang_enabled(self.enable_on) then
        return false
    end

    local current_node = ts.get_node({ bufnr = bufnr, lang = "html" })

    local allow_attrs = {
        "id",
        "class",
        "className",
    }

    while current_node do
        if current_node:type() == "attribute" then
            if current_node:child(0):type() == "attribute_name" then
                if u.contains(allow_attrs, ts.get_node_text(current_node:child(0), bufnr)) then
                    return true
                end
            end
            break
        end
        current_node = current_node:parent()
    end
    return false
end

---@return string
function source:get_debug_name()
    return "html-css"
end

-- function source:resolve(completion_item, callback)
--     completion_item.detail = nil
--     if completion_item.block ~= nil then
--         completion_item.documentation = {
--             kind = require("cmp").lsp.MarkupKind.Markdown,
--             value = ("```css\n%s%s\n```"):format(
--                 completion_item.label,
--                 completion_item
--                     .block
--                     :gsub("%s*{%s*", " {\n  ") -- Space before { and newline with indent after
--                     :gsub("%s*:%s*", ": ")
--                     :gsub("%s*;%s*", ";\n  ") -- Newline and indent after each ;
--                     :gsub("%s*}%s*", "\n}") -- Newline before }
--                     :gsub("!", " !")
--             ),
--         }
--     end
--     callback(completion_item)
-- end

return source
