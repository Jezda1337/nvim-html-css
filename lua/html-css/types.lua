---@class CSS_Data
---@field class Selector[]
---@field id Selector[]
---@field imports table<string>

---@class Selector
---@field label string
---@field block string
---@field kind integer
---@field range Range
---@field source_name string
---@field source_type string

---@class HTML_Data
---@field cdn table<string>
---@field raw_text string

---@class Config
---@field enable_on table<string>
---@field handlers Handlers
---@field notify boolean
---@field style_sheets table<string>
---@field documentation _config_documentation

---@class _config_documentation
---@field auto_show boolean

---@class Handlers
---@field definition Definition
---@field hover Hover

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
