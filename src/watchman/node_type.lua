---@class Watchman.Node
---@field type string
---@field data any?

---@class Watchman.Node.Typecheck: Watchman.Node
---@field optional boolean

---@class Watchman.Node.Anytype: Watchman.Node
---@class Watchman.Node.Notnil: Watchman.Node

---@class Watchman.Node.Typeunion: Watchman.Node
---@field lhs Watchman.Node
---@field rhs Watchman.Node
---@field optional boolean

---@class Watchman.Node.Program: Watchman.Node

return {
  PROGRAM   = "program",
  ANYTYPE   = "anytype",
  NOTNIL    = "notnil",
  TYPECHECK = "typecheck",
  TYPEUNION = "typeunion"
}
