local health = {}

health.check = function()
    vim.health.start("nvim-html-css report")

    if vim.fn.executable("curl") == 0 then
        vim.health.error("curl not found on path")
        return
    end
    vim.health.ok("curl found on path")

    local results = vim.system({ "curl", "--version" }):wait()
    local version = vim.version.parse(results.stdout)
    if version.major ~= 8 then
        vim.health.error("curl must be 8.x.x, but got " .. tostring(version))
    else
        vim.health.ok("curl version is good")
    end

    local res = vim.system({ "curl", "https://neovim.io/" }, { text = true }):wait()
    if res.code == 0 then
        vim.health.ok("site is accessible")
    else
        vim.health.error("site is not accessible")
    end
end

return health
