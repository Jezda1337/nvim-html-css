local collector = {}

local s = require("html-css.store")
-- local u = require("html-css.util")

collector.setup = function(ctx, config)
    require("html-css.parsers").html.parse(ctx.buf, config.style_sheets)
end

return collector
