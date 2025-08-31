---@class Watchman.Environment
local M = {}

-- Cache Lua functions. (Why not.)
local type = type

--- Function for detecting variable type. Uses builtin `type` function by default.
M.type = type

--- Produces typecheck.
---@param v any
---@param typeof string
---@return boolean
function M.istype(v, typeof)
  return M.type(v) == typeof
end

return M
