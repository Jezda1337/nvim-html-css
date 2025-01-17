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
    config = vim.tbl_extend("force", config, opts)

    if vim.fn.has("nvim-0.10") == 0 then
        vim.notify("nvim-html-css requires nvim 0.10 and newer", vim.log.levels.ERROR, { title = "nvim-html-css" })
        return
    end

    local enable_on_dto = {}
    for _, ext in pairs(config.enable_on) do
        table.insert(enable_on_dto, "*." .. ext)
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre", "WinEnter" }, {
        pattern = enable_on_dto,
        callback = function(ctx)
            require("html-css.store").set(ctx.buf, "full_path", ctx.file)
            require("html-css.store").set(ctx.buf, "id", ctx.id)

            require("html-css.collector").setup(ctx, config)
            vim.print(require("html-css.store").get(ctx.buf))
        end,
    })
    require("cmp").register_source(html_css.source_name, require("html-css.source"):new(config.enable_on))
end

return html_css
