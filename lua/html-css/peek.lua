local M = {}

---@param cfg Peek
---@param filepath string
---@param range Range
function M.open(cfg, filepath, range)
    local width = math.floor(vim.o.columns * cfg.width)
    local height = math.floor(vim.o.lines * cfg.height)

    local win_opts
    if cfg.position == "cursor" then
        win_opts = {
            relative = "cursor",
            row = 1,
            col = 0,
            width = width,
            height = height,
            style = cfg.style,
            border = cfg.border,
        }
    else
        win_opts = {
            relative = "editor",
            row = math.floor((vim.o.lines - height) / 2),
            col = math.floor((vim.o.columns - width) / 2),
            width = width,
            height = height,
            style = cfg.style,
            border = cfg.border,
        }
    end

    win_opts.title = vim.fs.basename(filepath)

    local scratch = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(scratch, cfg.focus, win_opts)

    local bufnr
    local existing = vim.fn.bufnr(filepath, false)

    if existing ~= -1 then
        bufnr = existing
    else
        bufnr = vim.fn.bufadd(filepath)
        vim.fn.bufload(bufnr)
        vim.bo[bufnr].filetype = vim.filetype.match({ filename = filepath }) or ""
    end

    vim.api.nvim_win_set_buf(win, bufnr)
    vim.api.nvim_buf_delete(scratch, { force = true })

    local au_id

    local function try_close()
        if vim.bo[bufnr].modified then
            vim.notify("[html-css] Unsaved changes — save or discard before closing peek", vim.log.levels.WARN)
            return
        end
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
        if au_id then
            vim.api.nvim_del_autocmd(au_id)
            au_id = nil
        end
    end

    for _, key in ipairs({ "q", "<Esc>" }) do
        vim.keymap.set("n", key, function()
            try_close()
        end, { buffer = bufnr, nowait = true })
    end

    au_id = vim.api.nvim_create_autocmd("WinLeave", {
        buffer = bufnr,
        callback = function()
            if vim.bo[bufnr].modified then
                vim.notify("[html-css] Unsaved changes — save or discard before closing peek", vim.log.levels.WARN)
                vim.schedule(function()
                    if vim.api.nvim_win_is_valid(win) then
                        vim.api.nvim_set_current_win(win)
                    end
                end)
                return
            end
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
            if au_id then
                vim.api.nvim_del_autocmd(au_id)
                au_id = nil
            end
        end,
    })

    vim.api.nvim_win_set_cursor(win, { range.start.line + 1, range.start.character })
    vim.api.nvim_win_call(win, function()
        vim.cmd("normal! zz")
    end)
end

return M
