---@class Watchman.Parser
local M           = {}

local token_type  = require("watchman.token_type")
local node_type   = require("watchman.node_type")
local tokenstream = require("watchman.tokenstream")

--- Parses primary constructions.
---@param stream Watchman.Tokenstream
---@return Watchman.Node
function M:parse_primary(stream)
  if stream:match(token_type.WORD) then
    local data = stream:prev().data
    return {
      data = data,
      type = node_type.TYPECHECK,
      optional = stream:match(token_type.QUESTION),
    }
  elseif stream:match(token_type.QUESTION) then
    return { type = node_type.ANYTYPE }
  elseif stream:match(token_type.EXCLAMATION) then
    return { type = node_type.NOTNIL }
  end

  error("watchman: primary node expected.")
end

--- Parses typeunion expression.
---@param stream Watchman.Tokenstream
---@return Watchman.Node
function M:parse_typeunion(stream)
  local lhs = self:parse_primary(stream)
  while stream:match(token_type.PIPE) do
    local rhs = self:parse_expression(stream)

    local message = "watchman: '?' flag is disallowed in union expression, use (...|...)? instead."

    ---@cast lhs Watchman.Node.Typecheck
    ---@cast rhs Watchman.Node.Typecheck

    if lhs.type == node_type.TYPECHECK then
      assert(not lhs.optional, message)
    end

    if rhs.type == node_type.TYPECHECK then
      assert(not rhs.optional, message)
    end

    local node = {
      type = node_type.TYPEUNION,
      lhs = lhs,
      rhs = rhs
    }

    lhs = node
  end
  return lhs
end

--- Parses expression.
---@param stream Watchman.Tokenstream
---@return Watchman.Node
function M:parse_expression(stream)
  local node
  if stream:match(token_type.LPAREN) then
    node = self:parse_typeunion(stream)

    ---@cast node Watchman.Node.Typeunion

    assert(stream:match(token_type.RPAREN), "watchman: ')' expected.")

    -- if found question mark.
    if stream:match(token_type.QUESTION) then
      if node.type == node_type.TYPEUNION then
        node.optional = true
      end
    end
  else
    node = self:parse_typeunion(stream)
  end
  return node
end

--- Parses program.
---@param stream Watchman.Tokenstream
---@return Watchman.Node.Program
function M:parse_program(stream)
  local program = { type = node_type.PROGRAM, data = {} }
  while not stream:eof() do
    program.data[#program.data + 1] = self:parse_expression(stream)
  end
  return program
end

--- Parses token list.
---@param tokens Watchman.Token[]
---@return Watchman.Node.Program
function M.parse(tokens)
  return M:parse_program(tokenstream.new(tokens))
end

return M
