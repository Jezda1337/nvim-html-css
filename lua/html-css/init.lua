local html_css = {}
local source = require("html-css.source")

html_css.source_name = "html-css"

local config = {
    enable_on = { "html" },
    notify = true,
    documentation = {
        auto_show = true,
    },
    style_sheets = {},
}

html_css.setup = function(opts)
    config = vim.tbl_extend("force", config, opts)

    local enable_on_dto = {}
    for _, ext in pairs(config.enable_on) do
        table.insert(enable_on_dto, "*." .. ext)
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre", "WinEnter" }, {
        pattern = enable_on_dto,
        callback = function(ctx)
            require("html-css.collector").setup(ctx, config)
        end,
    })

    if source == nil then
        print("Failed to load 'html-css.source'")
        return
    end
    require("cmp").register_source(html_css.source_name, source:new(config.enable_on))
end

return html_css
