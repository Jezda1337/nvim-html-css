# ☕ Neovim HTML, CSS Support

### 🚧 plugin is in dev mod 🚧

CSS Intellisense for HTML

![image](https://github.com/Jezda1337/nvim-html-css/assets/42359294/782f9ce8-a442-4012-b64b-5257f3527efa)

## ⚡ Required dependencies

- [plenary.nvim](https://github.com/nvim-lua/plenary.nvim)
- [sharkdp/fd](https://github.com/sharkdp/fd) (finder)

## 📦 Installation

##### ⚠️ In case your tree-sitter is lazy loaded, you must also lazy load the html-css plugin in the same way as the tree-sitter. Another way is to add dependencies as in the example below.

## Lazy

```lua
return require("lazy").setup({
    {
        "hrsh7th/nvim-cmp",
        opts = {
            sources = {
                -- other sources
                {
                    name = "html-css",
                    option = {
                        -- your configuration here
                    },
                },
            },
        },
    },
    { "Jezda1337/nvim-html-css",
        dependencies = {"nvim-treesitter/nvim-treesitter"},
        config = function()
            require("html-css"):setup()
        end
    }
})
```

## ⚙ Configuration

```lua
option = {
    max_count = {}, -- not ready yet
    enable_on = {
        "html"
        ...
    }, -- set the file types you want the plugin to work on
    file_extensions = { "css", "sass", "less" }, -- set the local filetypes from which you want to derive classes
    style_sheets = {
        -- example of remote styles
        "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css",
        "https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css",
    }
}
```

#### 🔌 Option spec

explanation and types for options.

| Property        | Type  | Description                                                                                                     |
| :-------------- | :---: | :-------------------------------------------------------------------------------------------------------------- |
| max_count       |  Int  | Max item in cmp menu                                                                                            |
| enable_on       | table | Table accepts strings, one string one extension in which the plugin will be available                           |
| file_extensions | table | Table accepts strings, extensions that you enter, classes that will be available to you will be read from them. |
| style_sheets    | table | External cdn css styles such as bootstrap or bulma. The link must be valid. Can be minified version or normal.  |

## 🤩 Pretty Menu Items

Setting the formatter this way you will get the file name with an extension in
your cmp menu, so you know from which file that class coming.

```lua
require("cmp").setup({
    sources = {
        {
            name = "html-css"
        },
    },
    formatting = {
        format = function(entry, vim_item)
            if entry.source.name == "html-css" then
                vim_item.menu = entry.source.menu
            end
            return vim_item
        end
    }

})
```
