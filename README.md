# ☕ Neovim HTML & CSS Support  

CSS IntelliSense for HTML  

![image](https://github.com/user-attachments/assets/c2e49c08-ca03-42f4-a973-6330ae211da3)  

## ✨ Features  

- Autocompletion for `id` and `class` attributes in HTML.  
- Supports linked and inline stylesheets.  
- Allows additional external stylesheets.  
- Provides documentation for `class` and `id` attributes.  
- Supports project-specific configurations via `.nvim.lua` files.

## ⚡️ Requirements  

- Neovim 0.10+  
- curl 8.7+  

## 📦 Installation  

### Supported Completion Engines  

- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp)  
- [blink.cmp](https://github.com/saghen/blink.cmp) with [(blink.compat)](https://github.com/saghen/blink.compat)  

### Lazy.nvim  

```lua
{
  "Jezda1337/nvim-html-css",
  dependencies = { "hrsh7th/nvim-cmp", "nvim-treesitter/nvim-treesitter" }, -- Use this if you're using nvim-cmp
  -- dependencies = { "saghen/blink.cmp", "nvim-treesitter/nvim-treesitter" }, -- Use this if you're using blink.cmp
  opts = {
    enable_on = { -- Example file types
      "html",
      "htmldjango",
      "tsx",
      "jsx",
      "erb",
      "svelte",
      "vue",
      "blade",
      "php",
      "templ",
      "astro",
    },
    documentation = {
      auto_show = true,
    },
    style_sheets = {
      "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css",
      "https://cdnjs.cloudflare.com/ajax/libs/bulma/1.0.3/css/bulma.min.css",
      "./index.css", -- `./` refers to the current working directory.
    },
  },
}
```

### nvim-cmp Integration  

If you're using `nvim-cmp`, add `html-css` as a source in your configuration:  

```lua
{ name = "html-css" }
```

### blink.cmp Integration  

If you're using `blink.cmp`, you'll need the `blink.compat` plugin, which acts as a bridge between `nvim-cmp` and `blink.cmp`.  

Here's the default configuration from their wiki—you just need to add `html-css` to the sources:  

```lua
{
  {
    "saghen/blink.compat",
    version = "*",
    lazy = true, -- Automatically loads when required by blink.cmp
    opts = {}
  },
  {
    "saghen/blink.cmp",
    dependencies = { "rafamadriz/friendly-snippets" }, -- Optional snippet support
    version = "*", -- Use a release tag to get pre-built binaries
    opts = {
      keymap = { preset = "default" },
      completion = {
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 500
        }
      },
      appearance = {
        use_nvim_cmp_as_default = true,
        nerd_font_variant = "mono"
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer", "html-css" },
        providers = {
          ["html-css"] = {
            name = "html-css",
            module = "blink.compat.source"
          }
        }
      }
    },
    opts_extend = { "sources.default" }
  }
}
```

## ⚙ Default Configuration  

```lua
{
  enable_on = { "html" },
  documentation = {
    auto_show = true,
  },
  style_sheets = {}
}
```

## 🔧 Project-Specific Configuration

You can set project-specific configurations using a `.nvim.lua` file in your project root. This allows you to have different settings for each project without modifying your global Neovim configuration.

### Setup

Create a `.nvim.lua` file in your project root directory and add the following:

```lua
-- Project-specific HTML/CSS configuration
vim.g.html_css = {
  enable_on = { "html", "jsx" },  -- File types for this project only
  documentation = {
    auto_show = true,
  },
  style_sheets = {
    -- Project-specific stylesheets
    "./src/styles/main.css",
    "./src/styles/components.css",
    "https://cdn.jsdelivr.net/npm/tailwindcss@2.2.19/dist/tailwind.min.css",
  }
}
```

The plugin will automatically detect and apply these settings when working within this project. This is particularly useful for:

- Adding project-specific stylesheets
- Enabling the plugin for project-specific file types
- Customizing documentation behavior for a specific project

### Priority

Project-specific configurations take precedence over global settings, allowing you to override any global configuration options on a per-project basis.

## 🤩 Pretty Menu Items  

To display the file name and extension in the completion menu, modify the formatter like this:  

### nvim-cmp
```lua
require("cmp").setup({
  formatting = {
    format = function(entry, vim_item)
      if entry.source.name == "html-css" then
        vim_item.menu = "[" .. (entry.completion_item.provider or "html-css") .. "]"
      end
      return vim_item
    end
  }
})
```

### blink.cmp
```lua
{
  completion = {
    documentation = {
      auto_show = true,
      auto_show_delay_ms = 500,
    },
    menu = {
      draw = {
        treesitter = { "lsp" },
        columns = { { "kind_icon" }, { "label", "label_description", gap = 1 } },
        components = {
          kind_icon = {
            ellipsis = true,
            text = function(ctx)
              local kind_icon = require "config.icons"[ctx.kind]
              return kind_icon .. "|"
            end,
          },
          label_description = {
            text = function(ctx)
              local item = ctx.item

              local sources = {
                {
                  pattern = "bootstrap",
                  label = "[Bootstrap]",
                  icon = " "
                },
                {
                  pattern = "foundation",
                  label = "[Foundation]",
                  icon = "履 "
                },
              }

              if ctx.source_name == "html-css" then
                for _, s in pairs(sources) do
                  if item.data.source_name:match(s.pattern) then
                    return s.icon
                  elseif item.data.source_type == "local" then
                    return "local"
                  end
                end
              end
            end
          }
        }
      }
    }
  }
}
```
