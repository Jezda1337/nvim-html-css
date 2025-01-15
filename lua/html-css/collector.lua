local collector = {}

-- local store = require("html-css.store")
local u = require("html-css.util")

collector.setup = function(ctx)
    local file_name = u.get_file_name(ctx.file)

    require("html-css.parsers.css").setup()
    require("html-css.parsers.html").setup()
end

return collector
