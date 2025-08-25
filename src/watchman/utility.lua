---@class Watchman.Utility
local M = {}

--- Splits string by separator.
---@param str string
---@param delim string
---@param plain string?
---@return string[]
function M.split(str, delim, plain)
  local tokens, pos, plain = {}, 1, not (plain == false) --[[ delimiter is plain text by default ]]
  repeat
    local npos, epos = string.find(str, delim, pos, plain)
    table.insert(tokens, string.sub(str, pos, npos and npos - 1))
    ---@diagnostic disable-next-line: cast-local-type
    pos = epos and epos + 1
  until not pos
  return tokens
end

--- Trims string.
---@param s string
---@return string
function M.trim(s)
  return select(1, string.gsub(s, "^%s*(.-)%s*$", "%1"))
end

return M
