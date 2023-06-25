# Neovim HTML, CSS Support

# 🚧 plugin is in dev mod 🚧

CSS Intellisense for HTML

# About

# Installation

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
        init = function()
            require("html-css"):setup()
        end
    }
})
```

# Configuration

```lua
option = {
    max_count = {}, -- not ready yet
    file_types = {
        "html"
        ...
    },
    -- css_file_types = {}, -- not ready yet
    style_sheets = {
        -- example of remote styles
        "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css",
        "https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css",
    }
}
```

# Pretty Menu Items

Setting the formatter this way you will get the file name with an extension in your cmp
menu, so you know from which file that class coming.

```lua
local source_mapping = {
    ...
}

require("cmp").setup({
    sources = {
        {
            name = "html-css"
        },
    },
    formatting = {
        format = function(entry, vim_item)
            if entry.source.name == "html-css" do
                source_mapping["html-css"] = entry.completion_item.menu
            end
        end
    }

})
```
