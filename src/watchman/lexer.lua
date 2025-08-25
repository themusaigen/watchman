---@class Watchman.Lexer
local M          = {}

local charstream = require("watchman.charstream")
local token_type = require("watchman.token_type")
local utility    = require("watchman.utility")

--- Returns is character matches alpha character.
---@param char string
---@return boolean
local function isalpha(char)
  local code = string.byte(char)
  return (code >= 65 and code <= 90)
      or (code >= 97 and code <= 122)
end

--- Returns is character matches blank character.
---@param char string
---@return boolean
local function isblank(char)
  local code = string.byte(char)
  return (code == 32) or (code == 13) or (code == 9) or (code == 10)
end

--- Produces string lexing.
---@param str string
---@return Watchman.Token[]
---@return string?
function M.lex(str)
  assert(type(str) == "string", ("bad argument #1 to `lex` (expected string, got %s)"):format(type(str)))

  local tokens = {}
  local function new(type, data)
    tokens[#tokens + 1] = { type = type, data = data }
  end

  local punctuation = {
    ["?"] = token_type.QUESTION,
    ["!"] = token_type.EXCLAMATION,
    ["|"] = token_type.PIPE,
    ["("] = token_type.LPAREN,
    [")"] = token_type.RPAREN,
  }

  local rules = nil
  local stream = charstream.new(str)
  while not stream:eof() do
    local char = stream:peek()
    if not char then
      break
    end

    if isblank(char) then
      stream:next()
    elseif char == ";" then
      -- Skip semicolon.
      stream:next()

      -- Read until end.
      rules = utility.trim(stream:tostring())
      break
    elseif isalpha(char) then
      new(token_type.WORD, stream:collect_while(isalpha))
    elseif punctuation[char] then
      new(punctuation[char])

      stream:next()
    end
  end

  new(token_type.EOF)

  return tokens, rules
end

return M
