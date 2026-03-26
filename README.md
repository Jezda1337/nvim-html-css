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
- Peek — open the CSS source in a floating window without leaving your current buffer.

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

- [nvim-cmp](https://github.com/hrsh7th/nvim-cmp) (requires `cmp-nvim-lsp`)
- [blink.cmp](https://github.com/saghen/blink.cmp) (via `lsp` source)

### Native neovim PM

```lua
    vim.pack.add({src="https://github.com/jezda1337/nvim-html-css"})
    -- example
    require("html-css").setup {
        enable_on = { "html" },
        -- if you want custom opt for handlers
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
        peek = {
            enabled = true,
            border = "rounded",
            position = "center",
            width = 0.5,
            height = 0.5,
            focus = true,
            style = "minimal",
        },
        style_sheets = {
            "https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css",
            "https://cdnjs.cloudflare.com/ajax/libs/bulma/1.0.3/css/bulma.min.css",
        },
    }
```

### Lazy.nvim

```lua
{
  "Jezda1337/nvim-html-css",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  opts = {
    enable_on = {
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
    peek = {
      enabled = true,
      border = "rounded",
      position = "center",
      width = 0.5,
      height = 0.5,
      focus = true,
      style = "minimal",
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

This plugin acts as an LSP server (`html-css-lsp`). Ensure you have `cmp-nvim-lsp` installed and the `nvim_lsp` source enabled in your `nvim-cmp` configuration:

```lua
sources = {
  { name = "nvim_lsp" },
  -- other sources...
}
```

### blink.cmp Integration

Since this plugin acts as an LSP, simply ensure the `lsp` source is enabled in your `blink.cmp` configuration:

```lua
sources = {
  default = { "lsp", "path", "snippets", "buffer" },
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
  peek = {
    enabled = true,
    border = "rounded",
    position = "center", -- "center" | "cursor"
    width = 0.5,         -- fraction of editor width (0.0–1.0)
    height = 0.5,        -- fraction of editor height (0.0–1.0)
    focus = true,        -- whether the float steals focus on open
    style = "minimal",
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
  peek = {
    enabled = true,
    position = "cursor",
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

## ⌨️ Keybindings

### Go to Definition

The default key binding for Go to Definition functionality is set to `gd`. If a class or ID is not found, it automatically falls back to the LSP definition using vim.lsp.buf.definition(). This allows for seamless navigation between your custom HTML/CSS definitions and LSP-managed definitions.

### Hover functionality

The default key binding for the hover functionality is set to `K`. If a class or ID is not found, it automatically falls back to the LSP hover using vim.lsp.buf.hover(). This enables quick access to your custom HTML/CSS definitions alongside standard LSP information for a seamless development experience.

### Peek

Peek opens the CSS source file in a floating window directly at the definition of the class or ID under your cursor, without leaving your current buffer. The file is fully editable — if you have unsaved changes, the window will refuse to close until you save or discard them.

The plugin exposes a `:HtmlCssPeek` command. Bind it however you like in your own config:

```lua
vim.keymap.set("n", "<leader>cp", "<cmd>HtmlCssPeek<CR>", { desc = "Peek CSS source" })
```

Inside the peek window the following keys are available:

| Key     | Action      |
| ------- | ----------- |
| `q`     | Close float |
| `<Esc>` | Close float |
