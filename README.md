# ☕ Neovim HTML, CSS Support

Neovim CSS Intellisense for HTML

#### HTML id and class attribute completion for Neovim written in Lua.

<br />

![image](https://github.com/Jezda1337/nvim-html-css/assets/42359294/76205c6f-7ab4-42d9-a2e0-6e9120549279)

## ✨ Features

- HTML `id` and `class` attribute completion.
- Supports linked and `internal` style sheets.
- Supports additional `external` style sheets.
- SPA mode support.

## 📦 Installation

### Lazy

```lua
return require("lazy").setup({
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            "Jezda1337/nvim-html-css"
        },
        opts = {
            sources = {
                -- other sources
                {
                    name = "html-css",
                    option = {
                        -- your configuration here
                    },
                },
                -- other sources
            },
        },
    },
})
```

## ⚙ Configuration

```lua
option = {
    enable_on = { "html" }, -- html is enabled by default
    spa = {
        enable = false, -- SPA mode is disabled by default
        entry_file = "index.html", -- if entry_file is omitted, it defaults to index.html in root dir
    },
    style_sheets = {
        "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css",
        "https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css",
    }
}
```

#### 🔌 Option spec

Explanation and types for options.

| Property     | Type  | Description                                                                                                                                      |
| :----------- | :---: | :----------------------------------------------------------------------------------------------------------------------------------------------- |
| enable_on    | table | Table accepts strings, one string per extension in which the plugin will be available (HTML is enabled by default).                              |
| spa          | table | SPA mode is used for spa apps, in case you have defined exteranl styels in gloabl spa index.html file, all styles will be available in project.. |
| style_sheets | table | External CDN CSS styles such as Bootstrap or Bulma. The link must be valid. Can be minified or normal versions.                                  |

## 🤩 Pretty Menu Items

Setting the formatter this way, you will get the file name with an extension in your cmp menu, so you know from which file that class is coming.

```lua
require("cmp").setup({
    -- ...
    formatting = {
        format = function(entry, vim_item)
            if source == "html-css" then
                source_mapping["html-css"] = "[" .. entry.completion_item.provider .. "]" or "[html-css]"
            end
            return vim_item
        end
    }
    -- ...
})
```
