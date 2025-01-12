# ☕ Neovim HTML, CSS Support

> [!WARNING]
> This plugin is under construction.

Neovim CSS Intellisense for HTML

#### HTML id and class attribute completion for Neovim written in Lua.

<br />

![image](https://github.com/user-attachments/assets/c2e49c08-ca03-42f4-a973-6330ae211da3)

## ✨ Features

- HTML `id` and `class` attribute completion.
- Supports linked and `internal` style sheets.
- Supports additional `external` style sheets.

## ⚡️ Requirements

- Neovim 0.10+
- curl 8.7+

## 📦 Installation

### Lazy

```lua
return require("lazy").setup({
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "Jezda1337/nvim-html-css" -- add it as dependencies of `nvim-cmp` or standalone plugin
        },
        opts = {
            sources = {
                {
                    name = "html-css",
                    option = {
                        enable_on = { "html" }, -- html is enabled by default
                        notify = false,
                        documentation = {
                            auto_show = true, -- show documentation on select
                        },
                        -- add any external scss like one below
                        style_sheets = {
                            "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css",
                            "https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css",
                        },
                    },
                },
            },
        },
    },
})
```

## ⚙ Default Configuration

```lua
option = {
    enable_on = { "html" },
    notify = false,
    documentation = {
        auto_show = true,
    },
    style_sheets = {}
}
```

## 🤩 Pretty Menu Items

Setting the formatter this way, you will get the file name with an extension in your cmp menu, so you know from which file that class is coming.

```lua
require("cmp").setup({
    -- ...
    formatting = {
        format = function(entry, vim_item)
            local source = entry.source.name
            if source == "html-css" then
                vim_item.menu = "[" .. entry.completion_item.provider .. "]" or "[html-css]"
            end
            return vim_item
        end
    }
    -- ...
})
```
