local store = {}

---@type fun(bufnr: number, key: string | table, value: any)
store.set = function(bufnr, key, value)
    if not store[bufnr] then
        store[bufnr] = {}
    end
    if type(key) == "table" and value == nil then
        for k, v in pairs(key) do
            store[bufnr][k] = v
        end
        return
    end
    store[bufnr][key] = value
end

---@type fun(bufnr: number, key: string?):any
store.get = function(bufnr, key)
    if not store[bufnr] then
        return nil
    end
    if not key then
        return store[bufnr]
    end
    return store[bufnr][key]
end

---@type fun(bufnr: number, key: string?):boolean
store.has = function(bufnr, key)
    if not store[bufnr] then
        return false
    end
    if not key then
        return store[bufnr] ~= nil
    end
    return store[bufnr][key] ~= nil
end

return store
