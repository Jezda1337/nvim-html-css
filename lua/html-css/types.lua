---@class Cache
---@field [number] CacheEntry

---@class CacheEntry
---@field file_name string
---@field links Link[]
---@field ids string[]
---@field classes string[]

---@class Ctx
---@field stdout string
---@field code number
---@field signal number
---@field stderr string

---@class Link
---@field url string
---@field fetched boolean
---@field provider string

---@class Selector
---@field type string
---@field label string
---@field kind number

---@class Source
---@field items Selector[]
---@field ids Selector[]
---@field classes Selector[]
---@field new fun(self: Source, Selectors: Selector[]): Source
---@field complete fun(self: Source, arg: any, callback: fun(result: { items: Selector[], isComplete: boolean }))
---@field is_available fun(self: Source): boolean
