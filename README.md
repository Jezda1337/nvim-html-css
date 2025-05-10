# ☕ Neovim HTML & CSS Support  

CSS IntelliSense for HTML  

![image](https://github.com/user-attachments/assets/c2e49c08-ca03-42f4-a973-6330ae211da3)  

## ✨ Features  

- Autocompletion for `id` and `class` attributes in HTML.
- Automatic detection of linked (`<link>`) and inline (`<style>`) stylesheets within the currently active HTML/component file.
- Allows explicit configuration of additional project-wide or external stylesheets (e.g., global styles, CSS frameworks not directly linked in the current file).
- Provides documentation for `class` and `id` attributes.
- Supports project-specific configurations via `.nvim.lua` files.
- Go to definition.
- Hover.

## ⚡️ Requirements  

- Neovim 0.10+  
- curl 8.7+  

## 💡 How Style Discovery Works

1. This plugin provides CSS IntelliSense by understanding the styles applicable to your current buffer (the file you are editing). It discovers styles in two main ways:
    - Buffer-Specific Automatic Detection:
        - When you open an HTML or component file (e.g., `index.html`, `MyComponent.jsx`), the plugin automatically parses it for:
            - Linked stylesheets: Any `<link rel="stylesheet" href="...">` tags, whether they point to local files (e.g., `./style.css`) or remote URLs (e.g., a CDN link).
            - Inline styles: Any CSS rules defined within `<style>...</style>` tags directly in the file.
        - Completions from these automatically detected styles are available only for the specific file where they are linked or embedded.

2. Explicit Configuration for Global/Project-Wide Styles (`style_sheets` option):
    - Many modern web projects (e.g., using React, Vue, Svelte, Angular, or with build tools like Vite, Webpack) have global stylesheets that are bundled and apply to the entire application, even if not explicitly linked in every single component file.
    - For these scenarios, you need to inform the plugin about these stylesheets using the `style_sheets` array in your configuration (either globally in your Neovim setup or via a project-specific `.nvim.lua`).
    - When to use style_sheets:
        - You have a global `main.css`, `theme.css`, or similar that applies to your whole project.
        - You are using a CSS framework like Tailwind CSS, Bootstrap, Bulma, etc., and these styles are imported/included at a project level (e.g., in your main JavaScript entry file) rather than linked in each individual HTML/component.
        - Your styles are processed by a bundler and you want completions from the source CSS files before they are bundled.
    - The plugin will then parse these configured stylesheets and make their `id` and `class` definitions available for autocompletion across all relevant file types enabled in `enable_on`.

In essence:
- For styles directly linked or embedded in the file you're editing, the plugin works automatically for that file.
- For styles that are part of your project but not directly linked in the current file (like global stylesheets or framework CSS bundled elsewhere), you must list them in the `style_sheets` configuration option for the plugin to find them.

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
    handlers = {
      definition = {
        bind = "gd"
      },
      hover = {
        bind = "K",
        wrap = true,
        border = "none",
        position = "cursor",
      },
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
  handlers = {
    definition = {
      bind = "gd"
    },
    hover = {
      bind = "K",
      wrap = true,
      border = "none",
      position = "cursor",
    }
  },
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
  handlers = {
    definition = {
      bind = "gd"
    },
    hover = {
      bind = "K",
      wrap = true,
      border = "none",
      position = "cursor",
    }
  },
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

### Go to Definition
The default key binding for Go to Definition functionality is set to `gd`. If a class or ID is not found, it automatically falls back to the LSP definition using vim.lsp.buf.definition(). This allows for seamless navigation between your custom HTML/CSS definitions and LSP-managed definitions.

### Hover functionality
The default key binding for the hover functionality is set to `K`. If a class or ID is not found, it automatically falls back to the LSP hover using vim.lsp.buf.hover(). This enables quick access to your custom HTML/CSS definitions alongside standard LSP information for a seamless development experience.
