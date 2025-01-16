local store = {}

---@type fun(bufnr: number, key: string, value: any)
store.set = function(bufnr, key, value)
    if not store[bufnr] then
        store[bufnr] = {
            [key] = value,
        }
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
