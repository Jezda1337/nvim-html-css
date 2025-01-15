local html_css = {}

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
    config = vim.tbl_extend("force", opts, config)

    local enable_on_dto = {}
    for _, ext in pairs(config.enable_on) do
        table.insert(enable_on_dto, "*." .. ext)
    end

    if #config.style_sheets ~= 0 then
        require("html-css").setup(config.style_sheets)
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre", "WinEnter" }, {
        pattern = enable_on_dto,
        callback = function(ctx)
            require("html-css.collector").setup(ctx)
        end,
    })

    require("cmp").register_source(html_css.source_name, require("html-css.source"))
end

return html_css
