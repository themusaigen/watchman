---@class Watchman.Translator
local M                      = {}

local node_type              = require("watchman.node_type")
local env                    = require("watchman.env")

-- Cache Lua functions.
local ipairs, format, concat = ipairs, string.format, table.concat

--- Helper for producing typechecks.
---@param value any
---@param type string
---@param optional boolean
---@return boolean
---@return string?
local function produce_typecheck(value, type, optional)
  if optional and value == nil then
    return true
  end

  if env.istype(value, type) then
    return true
  end

  return false, format("%s%s expected, got %s", type, optional and " or no value" or "", env.type(value))
end

--- Any types node. Allowes anything.
---@param _ any
---@return boolean
function M:anytype(_, _)
  return true
end

--- Any not nil variable is allowed.
---@param value any
---@param _ any
---@return boolean
---@return string
function M:notnil(value, _)
  return not env.istype(value, "nil"), "any not nil type expected, got nil"
end

--- Produces typecheck. Uses `produce_typecheck` helper.
---@param value any
---@param node Watchman.Node.Typecheck
---@return boolean
function M:typecheck(value, node)
  return produce_typecheck(value, node.data, node.optional)
end

--- Produces typechecks for union.
---@param value any
---@param union Watchman.Node.Typeunion
---@return boolean
---@return string?
function M:typeunion(value, union)
  --- Collects types recursively from nested nodes.
  ---@param result string[]
  ---@param node Watchman.Node
  ---@return table
  local function collect_types(result, node)
    if node.type == node_type.TYPEUNION then
      ---@cast node Watchman.Node.Typeunion
      collect_types(result, node.lhs)
      collect_types(result, node.rhs)

      if node.optional then
        ---@diagnostic disable-next-line: inject-field
        result.optional = true
      end
    else
      result[#result + 1] = node.data
    end
    return result
  end

  -- Collect types from children nodes.
  local types = collect_types({}, union)

  -- Optional check.
  if types.optional and value == nil then
    return true
  end

  -- Check all collected types.
  local state = false
  for i = 1, #types do
    state = env.istype(value, types[i])
    if state then
      break
    end
  end

  -- Got an error.
  if not state then
    -- Add additional type if optional union.
    if types.optional then
      types[#types + 1] = "no value"
    end

    -- Return state and error message.
    return false, format("%s expected, got %s", concat(types, " or "), env.type(value))
  end

  return true
end

--- Executes program.
---@param value any
---@param node Watchman.Node.Program
---@return boolean
---@return string?
function M:program(value, node)
  for _, subnode in ipairs(node.data) do
    local state, err = self:run(value, subnode)
    if not state then
      return false, err
    end
  end
  return true
end

--- Runs node.
---@param value any
---@param node Watchman.Node
---@return boolean, string?
function M:run(value, node)
  local method = self[node.type]
  return method(self, value, node)
end

return M
