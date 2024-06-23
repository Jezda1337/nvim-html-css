---@class Ctx
---@field stdout string
---@field code number
---@field signal number
---@field stderr string

---@class Source
---@field items Selectors
---@field new fun(self: Source, Selectors: Selector[]): Source
---@field complete fun(self: Source, arg: any, callback: fun(result: { items: Selector[], isComplete: boolean }))
---@field is_available fun(self: Source): boolean

---@class Link
---@field url string
---@field available boolean
---@field fetched boolean
---@field provider string

---@class LocalItem
---@field path string
---@field available boolean
---@field fetched boolean
---@field file_name string

---@class Externals
---@field cdn Link[]
---@field locals LocalItem[]

---@class Selector
---@field label string
---@field kind cmp.lsp.CompletionItemKind.Enum
---@field source string

---@class Selectors
---@field ids Selector[]?
---@field classes Selector[]?

---@class StoreItem
---@field externals Externals?
---@field file_name string?
---@field selectors Selectors?

---@class Config
---@field enable_on string[]
---@field spa Spa

---@class Spa
---@field enable boolean
---@field entry_file string
