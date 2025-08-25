---@class Watchman.Memoizer
---@field private _ast table
---@field private _rule table
local M = {
  _ast = {},
  _rule = {}
}

--- Returns memoized AST cache.
---@param str string
---@return table?
function M:ast(str)
  return self._ast[str]
end

--- Memoizes AST cache.
---@param str string
---@param cache table
function M:memoize_ast(str, cache)
  self._ast[str] = cache
end

--- Returns memoized rulechecker cache.
---@param str string
---@return table?
function M:rule(str)
  return self._rule[str]
end

--- Memoizes rulechecker cache.
---@param str string
---@param cache table
function M:memoize_rule(str, cache)
  self._rule[str] = cache
end

return M
