local config = require("html-css.config")
---@type fun(url: string, opts: any[], cb: fun(ctx: Ctx))
return function(url, opts, cb)
	opts = opts or {}
	---@param ctx Ctx
	local function on_exit(ctx)
		if cb then
			cb(ctx)
			if config.config.notify then
				vim.schedule(function()
					if url == {} then
						vim.notify(url.path, vim.log.levels.INFO, { title = "Fetching ..." })
					else
						vim.notify(url, vim.log.levels.INFO, { title = "Fetching ..." })
					end
				end)
			end
		end
	end
	-- this runs asynchronously
	vim.system({ "curl", url }, { text = true }, on_exit)
end
