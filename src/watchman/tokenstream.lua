---@class Watchman.Token
---@field type number
---@field data string?

---@class Watchman.Tokenstream
---@field private _tokens Watchman.Token[]
---@field private _offset number
---@field private _size number
local M = {}

-- Cache Lua functions.
local setmetatable = setmetatable

--- Returns new token stream.
---@param tokens Watchman.Token[]
---@return Watchman.Tokenstream
function M.new(tokens)
  return setmetatable({ _tokens = tokens, _offset = 1, _size = #tokens }, { __index = M })
end

--- Returns current token.
---@return Watchman.Token?
function M:peek()
  return self:eof() and nil or self._tokens[self._offset]
end

--- Returns current token and switches to next.
---@return Watchman.Token
function M:next()
  if self:eof() then
    return self._tokens[self._offset]
  end

  self._offset = self._offset + 1
  return self._tokens[self._offset - 1]
end

--- Returns previous token.
---@return Watchman.Token
function M:prev()
  if self:eof() then
    return self._tokens[self._size - 1]
  end

  return self._tokens[self._offset - 1]
end

--- Returns is stream reached end of the stream.
---@return boolean
function M:eof()
  return self._offset >= self._size
end

--- Checks is current token matches specified type
---@param type number
---@return boolean
function M:check(type)
  return self:eof() and false or self:peek().type == type
end

--- Checks is current token matches specified type and moves to next.
---@param type number
---@return boolean
function M:match(type)
  if self:check(type) then
    self:next()
    return true
  end
  return false
end

return M
