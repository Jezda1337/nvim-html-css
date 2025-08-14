local cache = require "html-css.cache"
local utils = require "html-css.utils"

local LSP = {}

local function create_server(dispatchers)
    local closing = false
    local srv = {}
    local opts = {}

    function srv.request(method, params, callback)
        if method == "initialize" then
            callback(nil, {
                capabilities = {
                    textDocumentSync = {
                        openClose = true,
                        change = 1,
                        willSave = false,
                        willSaveWaitUntil = false
                    },
                    completionProvider = {
                        triggerCharacters = { '"', "'", " " },
                        resolveProvider = false
                    },
                    hoverProvider = true,
                    definitionProvder = true
                },
                serverInfo = {
                    name = "html-css-lsp",
                    version = "0.1.0"
                }
            })
        elseif method == "textDocument/completion" then
            local uri = params.textDocument.uri
            local position = params.position
            local bufnr = vim.uri_to_bufnr(uri)

            if utils.is_special_buffer(bufnr) then
                callback(nil, { items = {} })
                return true, 1
            end

            local ext = vim.fn.expand("%:t:e")
            if not utils.is_lang_enabled(ext, opts.enable_on) then
                callback(nil, { items = {} })
                return true, 1
            end

            local context = nil
            local node = vim.treesitter.get_node({ lang = "html", pos = { position.line, position.character } })

            while node do
                if node:type() == "attribute" or node:type() == "jsx_attribute" then
                    local first_child = node:child(0)
                    if first_child then
                        local attr_name = vim.treesitter.get_node_text(first_child, bufnr)
                        if attr_name == "class" or attr_name == "className" then
                            context = "class"
                            break
                        elseif attr_name == "id" then
                            context = "id"
                            break
                        end
                    end
                end
                node = node:parent()
            end

            if not context then
                callback(nil, { items = {} })
                return true, 1
            end

            local items = {}
            if context == "class" then
                items = cache:get_classes(bufnr)
            elseif context == "id" then
                items = cache:get_ids(bufnr)
            end

            local completion_items = {}
            for _, item in ipairs(items) do
                local formatted_css = item.block
                    :gsub("{%s*", " {\n  ")
                    :gsub(";%s*", ";\n  ")
                    :gsub(":%s*", ": ")
                    :gsub("([^;{}])%s*}", "%1;\n}")
                    :gsub("\n%s+", "\n  ")
                    :gsub("!important", " !important")

                local documentation = string.format(
                    "css\n/* Source: %s */\n.%s%s\n",
                    item.source_name,
                    item.label,
                    formatted_css
                )

                table.insert(completion_items, {
                    label = item.label,
                    kind = 21, -- CompletionItemKind.Constant
                    detail = item.source_name and ("🠖 " .. item.source_name) or "[Unknown]",
                    documentation = {
                        kind = "markdown",
                        value = documentation
                    },
                    insertText = item.label,
                    filterText = item.label,
                    sortText = item.label,
                    data = {
                        source_name = item.source_name,
                        source_type = item.source_type or "unknown"
                    }
                })
            end

            vim.schedule(function()
                callback(nil, { items = completion_items })
            end)
        elseif method == "textDocument/hover" then
            if opts.handlers and opts.handlers.definition then
                callback(nil, nil)
            else
                callback(nil, nil)
            end
        elseif method == "shutdown" then
            callback(nil, nil)
        else
            callback({ code = -32601, message = "Method not found" }, nil)
        end
        return true, 1
    end

    function srv.notify(method, params)
        if method == "exit" then
            dispatchers.on_exit(0, 15)
        elseif method == "textDocument/didOpen" then
        elseif method == "textDocument/didChange" then
        elseif method == "textDocument/didClose" then
        end
    end

    function srv.is_closing()
        return closing
    end

    function srv.terminate()
        closing = true
    end

    function srv.set_opts(new_opts)
        opts = new_opts or {}
    end

    return srv
end

LSP.create_client = function(opts, bufnr)
    -- Check for any existing clients with this name globally
    local clients = vim.lsp.get_clients({ name = "html-css-lsp" })
    if #clients > 0 then
        -- Client exists, just attach it to this buffer
        vim.lsp.buf_attach_client(bufnr, clients[1].id)
        return
    end

    local client_id = vim.lsp.start({
        name = "html-css-lsp",
        cmd = function(dispatchers)
            local srv = create_server(dispatchers)
            srv.set_opts(opts)
            return srv
        end,
        root_dir = vim.fs.dirname(vim.fs.find({ ".git", "package.json", ".nvim.lua" }, { upward = true })[1]) or
            vim.fn.getcwd()
    })
    if client_id then
        vim.lsp.buf_attach_client(bufnr, client_id)
    end
end

return LSP
