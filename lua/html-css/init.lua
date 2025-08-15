local utils    = require "html-css.utils"
local config   = require "html-css.config"
local cache    = require "html-css.cache"
local fetcher  = require "html-css.fetcher"
local uv       = vim.uv
local cwd      = uv.cwd()

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
    if uv.fs_stat(project_config_path) then
        dofile(project_config_path)
        local project_config = vim.g.html_css or {}
        opts = vim.tbl_deep_extend("force", opts, project_config)
    end

    vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePre" }, {
        group = vim.api.nvim_create_augroup("html-css", { clear = true }),
        pattern = vim.tbl_map(function(ext) return "*." .. ext end, opts.enable_on),
        callback = function(args)
            if utils.is_special_buffer(args.buf) then return end

            local html_data = require "html-css.parsers.html".setup(args.buf)
            local sources = vim.list_extend(html_data.cdn, opts.style_sheets)

            if #sources <= 0 then return end

            if #html_data.raw_text > 0 then
                local css_data = require "html-css.parsers.css".setup(html_data.raw_text, true)
                cache:update("buffer://" .. args.file, css_data)
                if #css_data.imports > 0 then
                    for _, imp in pairs(css_data.imports) do
                        table.insert(sources, imp)
                    end
                end
                table.insert(sources, "buffer://" .. args.file)
            end

            -- normalize and proper formatting the paths of the local linked files
            for i, src in ipairs(sources) do
                if utils.is_local(src) then
                    local resolved

                    if src:match("^/") then
                        -- remove starting slash for joining
                        local relative_path = src:gsub("^/", "")
                        local candidate_paths = {
                            -- TODO - make public/static configurable, include table with values so client can use what ever static folder he wants
                            vim.fs.joinpath(cwd, relative_path),
                            vim.fs.joinpath(cwd, "public", relative_path),
                            vim.fs.joinpath(cwd, "static", relative_path),
                        }
                        for _, p in ipairs(candidate_paths) do
                            if utils.file_exists(p) then
                                resolved = p
                                break
                            end
                        end

                    elseif src:match("^buffer://") then
                        resolved = src

                    else
                        -- Check if this source comes from user configuration (opts.style_sheets)
                        local is_from_config = false
                        for _, config_src in ipairs(opts.style_sheets) do
                            if config_src == src then
                                is_from_config = true
                                break
                            end
                        end

                        local base_dir
                        if is_from_config then
                            base_dir = cwd
                        else
                            base_dir = vim.fn.expand("%:p:h")
                        end

                        local candidate_paths = {
                            vim.fs.joinpath(base_dir, src),
                            vim.fs.joinpath(cwd, "public", src),
                            vim.fs.joinpath(cwd, "static", src),
                        }
                        for _, p in ipairs(candidate_paths) do
                            if utils.file_exists(p) then
                                resolved = p
                                break
                            end
                        end
                    end

                    if resolved then
                        sources[i] = vim.fs.normalize(resolved)
                    end
                end
            end
            for _, src in pairs(sources) do
                if src:match("buffer://") then goto continue end
                fetcher:fetch(src, args.buf, opts.notify)
                ::continue::
            end
            cache:link_sources(args.buf, sources)
        end
    })

    vim.api.nvim_create_autocmd("BufDelete", {
        group = vim.api.nvim_create_augroup("html-css-cleanup", { clear = true }),
        callback = function(args)
            cache:cleanup(args.buf)
        end
    })

    -- Handlers
    require "html-css.definition".setup(opts.handlers.definition)
    require "html-css.hover".setup(opts.handlers.hover)

    local ok, cmp = pcall(require, "cmp")
    if ok then
        cmp.register_source("html-css", require "html-css.source":new(opts))
    end
end

return html_css
