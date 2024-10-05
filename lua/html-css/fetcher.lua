---@type fun(url: string, opts: any[], cb: fun(ctx: Ctx))
return function(url, opts, cb)
	opts = opts or {}
	---@param ctx Ctx
	local function on_exit(ctx)
		if cb then
			cb(ctx)
		end
	end
	-- this runs asynchronously
	vim.system({ "curl", url }, { text = true }, on_exit)
end
