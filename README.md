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
    { "Jezda1337/html-css",
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
        "html" -- default
        ...
    },
    style_sheets = {
        -- example of remote styles
        "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css",
        "https://cdn.jsdelivr.net/npm/bulma@0.9.4/css/bulma.min.css",

        -- example of local styles that can be found inside root folder
        "./style.css",
        "index.css",
    }
}
```

# Pretty Menu Items

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
