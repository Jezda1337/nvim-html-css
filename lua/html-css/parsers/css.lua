local utils = require "html-css.parsers.utils"
local css = {}
local ts = vim.treesitter

css.lang = "css"
css.query = [[
  ((rule_set
     (selectors
         (class_selector
             (class_name) @class_name)
         ) @class_decl
     (#lua-match? @class_decl "^[.][a-zA-Z0-9_-]+$")
     (#not-has-ancestor? @class_decl "media_statement")
     (block) @class_block
     ))

  ((rule_set
      (block
        (rule_set
         (selectors
             (class_selector
                 (class_name) @class_name)
             ) @class_decl
         (#lua-match? @class_decl "^[.][a-zA-Z0-9_-]+$")
         (block) @class_block
         )
      )
  ))

  ((media_statement
      (block
        (rule_set
         (selectors
             (class_selector
                 (class_name) @class_name)
             ) @class_decl
         (#lua-match? @class_decl "^[.][a-zA-Z0-9_-]+$")
         (block) @class_block
         )
      )
  ) @media_statement)

  ((rule_set
     (selectors
         (id_selector
             (id_name) @id_name)
         ) @id_decl
     (#lua-match? @id_decl "^#[a-zA-Z0-9_-]+")
     (#not-has-ancestor? @id_decl "media_statement")
     (block) @id_block
     ))

  ((rule_set
      (block
        (rule_set
         (selectors
             (id_selector
                 (id_name) @id_name)
             ) @id_decl
         (#lua-match? @id_decl "^#[a-zA-Z0-9_-]+")
         (block) @id_block
         )
      )
  ))

  ((media_statement
      (block
        (rule_set
         (selectors
             (id_selector
                 (id_name) @id_name)
             ) @id_decl
         (#lua-match? @id_decl "^#[a-zA-Z0-9_-]+")
         (block) @id_block
         )
      )
  ) @media_statement)
]]

css.setup = function(stdout, withLocation)
    local root, query = utils.string_parse(css.lang, css.query, stdout)
    ---@type CSS_Data
    local css_data = {
        imports = {},
        class = {},
        id = {},
    }

    for _, match, _ in query:iter_matches(root, stdout, 0, -1, { all = true }) do
        local media = nil
        for id, nodes in pairs(match) do
            if query.captures[id] == "media_statement" then
                local media_node = nodes[1]
                local parts = {}
                for child in media_node:iter_children() do
                    local ctype = child:type()
                    if ctype ~= "block" then
                        local text = ts.get_node_text(child, stdout)
                        if text ~= "@media" then
                            table.insert(parts, text)
                        end
                    end
                end
                media = table.concat(parts, " ")
                media = media:gsub("^%s+", ""):gsub("%s+$", "")
                break
            end
        end

        for id, nodes in pairs(match) do
            local name = query.captures[id]
            for _, node in ipairs(nodes) do
                local start_row, start_col, end_row, end_col = node:range()

                if name == "class_name" then
                    table.insert(css_data.class, {
                        type = "class",
                        label = ts.get_node_text(node, stdout),
                        -- The block capture is separate. We need to find which node corresponds to class_block in this match.
                        -- In the query, @class_block is used.
                        -- We can iterate match to find it.
                        block = (function()
                            for cid, cnodes in pairs(match) do
                                if query.captures[cid] == "class_block" then
                                    return ts.get_node_text(cnodes[1], stdout)
                                end
                            end
                            return ""
                        end)(),
                        media = media,
                        kind = 13,
                        range = withLocation
                                and {
                                    start = { line = start_row, character = start_col },
                                    ["end"] = { line = end_row, character = end_col },
                                }
                            or nil,
                    })
                end
                if name == "id_name" then
                    table.insert(css_data.id, {
                        type = "id",
                        label = ts.get_node_text(node, stdout),
                        block = (function()
                            for cid, cnodes in pairs(match) do
                                if query.captures[cid] == "id_block" then
                                    return ts.get_node_text(cnodes[1], stdout)
                                end
                            end
                            return ""
                        end)(),
                        media = media,
                        kind = 13,
                        range = withLocation
                                and {
                                    start = { line = start_row, character = start_col },
                                    ["end"] = { line = end_row, character = end_col },
                                }
                            or nil,
                    })
                end
                if name == "value" then
                    table.insert(css_data.imports, ts.get_node_text(node, stdout))
                end
            end
        end
    end

    return css_data
end

return css
