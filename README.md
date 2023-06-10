# Neovim HTML, CSS Support

CSS Intellisense for HTML

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
