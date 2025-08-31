---@class Watchman.Charstream
---@field private _content string[]
---@field private _size number
---@field private _offset number
local M = {}

-- Cache Lua functions
local setmetatable, concat, sub = setmetatable, table.concat, string.sub

--- Contstructs new charstream.
---@param str string
---@return Watchman.Charstream
function M.new(str)
  local content = {}
  for i = 1, #str do
    content[i] = sub(str, i, i)
  end

  return setmetatable({
    _content = content,
    _size = #content,
    _offset = 1
  }, { __index = M })
end

--- Returns current character.
---@return string?
function M:peek()
  return self:eof() and nil or self._content[self._offset]
end

--- Returns current character and switches to the next.
---@return string
function M:next()
  if self:eof() then
    return self._content[self._offset]
  end

  self._offset = self._offset + 1
  return self._content[self._offset - 1]
end

--- Returns is stream reached end of the stream.
---@return boolean
function M:eof()
  return self._offset > self._size
end

--- Collects characters into one string until predicate fails.
---@param predicate fun(character: string): boolean
---@return string
function M:collect_while(predicate)
  local str = ""
  ---@diagnostic disable-next-line: param-type-mismatch
  while not self:eof() and predicate(self:peek()) do
    str = str .. self:next()
  end
  return str
end

--- Returns string starting from stream's offset.
---@return string
function M:tostring()
  return concat(self._content, "", self._offset)
end

return M
