---@class CSS_Data
---@field class Selector[]
---@field id Selector[]
---@field imports table<string>

---@class Selector
---@field label string
---@field block string
---@field media? string
---@field kind integer
---@field range Range
---@field source_name string
---@field source_type string

---@class HTML_Data
---@field cdn table<string>
---@field raw_text string

---@class Config
---@field enable_on table<string>
---@field handlers? Handlers
---@field peek? Peek
---@field notify? boolean
---@field style_sheets? table<string>
---@field documentation? Documentation

---@class Documentation
---@field auto_show boolean

---@class Handlers
---@field definition? Definition
---@field hover? Hover

---@class Peek
---@field enabled boolean
---@field border "rounded"|"single"|"double"|"shadow"|"none"
---@field width number
---@field height number
---@field style string
---@field position "cursor"|"center"
---@field focus boolean

---@class Definition
---@field bind string

---@class Hover
---@field bind string
---@field wrap boolean
---@field border string
---@field position string

---@class Range
---@field start { line: integer, character: integer }
---@field ["end"] { line: integer, character: integer }
