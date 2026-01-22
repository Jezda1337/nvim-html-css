local utils = require "html-css.utils"
local config = require "html-css.config"
local cache = require "html-css.cache"
local fetcher = require "html-css.fetcher"

local uv = vim.uv
local cwd = uv.cwd()

-- TODO
-- if the file e.g index.css while in use was being deleted error occurred

local html_css = {}

---@param opts Config
html_css.setup = function(opts)
    opts = vim.tbl_extend("force", config, opts)

    -- manually load everything from plugin runtime
    -- this was the solution for the #44
    vim.cmd("runtime! plugin/**/*.{vim,lua}")

    vim.opt.ex = true
    local project_config_path = cwd .. "/" .. ".nvim.lua"
    if utils.file_exists(project_config_path) then
        dofile(project_config_path)
        local project_config = vim.g.html_css or {}
        opts = vim.tbl_deep_extend("force", opts, project_config)
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre" }, {
        group = vim.api.nvim_create_augroup("html-css", { clear = true }),
        pattern = vim.tbl_map(function(ext)
            return "*." .. ext
        end, opts.enable_on),
        callback = function(args)
            if utils.is_special_buffer(args.buf) then
                return
            end

            if opts.lsp.enable then
                require("html-css.lsp").create_client(opts, args.buf)
            end

            local html_data = require("html-css.parsers.html").setup(args.buf)
            local sources = vim.list_extend(html_data.cdn, opts.style_sheets)

            if #sources <= 0 then
                return
            end

            if #html_data.raw_text > 0 then
                local css_data = require("html-css.parsers.css").setup(html_data.raw_text, true)
                cache:update("buffer://" .. args.file, css_data)
                if #css_data.imports > 0 then
                    for _, imp in pairs(css_data.imports) do
                        table.insert(sources, imp)
                    end
                end
                table.insert(sources, "buffer://" .. args.file)
            end

            -- normalize and properly format the paths of local linked files
            for i = #sources, 1, -1 do
                local src = sources[i]
                if utils.is_local(src) then
                    -- Check if this source comes from user configuration (opts.style_sheets)
                    local is_from_config = false
                    for _, config_src in ipairs(opts.style_sheets) do
                        if config_src == src then
                            is_from_config = true
                            break
                        end
                    end

                    -- base_dir is cwd for config, otherwise current file’s folder
                    local base_dir = is_from_config and cwd or vim.fn.expand("%:p:h")
                    local resolved = utils.resolve_path(src, base_dir)

                    if resolved and utils.file_exists(resolved) then
                        sources[i] = resolved
                    else
                        if is_from_config then
                            vim.notify(
                                string.format("[html-css] Configured stylesheet not found: %s", src),
                                vim.log.levels.WARN
                            )
                        end
                        table.remove(sources, i)
                    end
                end
            end
            for _, src in pairs(sources) do
                if src:match("buffer://") then
                    goto continue
                end
                fetcher:fetch(src, args.buf, opts.notify)
                ::continue::
            end
            cache:link_sources(args.buf, sources)
        end,
    })

    vim.api.nvim_create_autocmd("BufDelete", {
        group = vim.api.nvim_create_augroup("html-css-cleanup", { clear = true }),
        callback = function(args)
            cache:cleanup(args.buf)
        end,
    })

    -- if opts.lsp.enable then
    --     require "html-css.lsp".setup(opts)
    -- end

    -- Handlers
    require("html-css.definition").setup(opts.handlers.definition)
    require("html-css.hover").setup(opts.handlers.hover)

    if not opts.lsp.enable then
        local ok, cmp = pcall(require, "cmp")
        if ok then
            cmp.register_source("html-css", require("html-css.source"):new(opts))
        end
    end
end

return html_css
