---@class Watchman.Translator.Inner.Rule
---@field type string?
---@field code string

---@class Watchman.Translator.Inner.Rules
---@field with Watchman.Translator.Inner.Rule[]
---@field without Watchman.Translator.Inner.Rule[]

---@class Watchman.Translator
local M        = {}

local utility  = require("watchman.utility")
local memoizer = require("watchman.memoizer")
local env      = require("watchman.env")

--- Generates error message.
---@param rules Watchman.Translator.Inner.Rules
---@param argument any
---@return string
local function generate_error_message(rules, argument)
  local checks = {}
  for _, rule in ipairs(rules.with) do
    if env.istype(argument, rule.type) then
      checks[#checks + 1] = "'" .. rule.code .. "'"
      break
    end
  end

  if #checks == 0 then
    for _, rule in ipairs(rules.without) do
      checks[#checks + 1] = "'" .. rule.code .. "'"
    end
  end

  if #checks > 1 then
    return ("failed checks %s"):format(table.concat(checks, ", "))
  end

  return ("failed check %s"):format(checks[1])
end

--- Returns translated pseudocode to executable Lua code.
---@param str string
---@return (fun(var: any): boolean), string
function M.translate(str, var)
  local cache = memoizer:rule(str)
  if cache then
    return cache.checker, generate_error_message(cache.rules, var)
  else
    -- `with` means with type requirements.
    -- `without` means without type requirements.
    local rules = { with = {}, without = {} }
    for _, rule in ipairs(utility.split(str, ";")) do
      local type_requirement = rule:match("<(%S+)>:")

      -- This rule is specified for concrete variable type.
      if type_requirement then
        -- Remove type requirement from the rule.
        rule = utility.trim(rule:gsub(("<%s+>:"):format(type_requirement), ""))

        -- Add new requirement.
        rules.with[#rules.with + 1] = {
          type = type_requirement,
          code = rule
        }
      else -- No requirement for concrete type.
        rules.without[#rules.without + 1] = {
          code = utility.trim(rule)
        }
      end
    end

    -- Now generate executable Lua code.
    local luac = { "return function(v)" }
    local function new_line(line, ...)
      luac[#luac + 1] = line:format(...)
    end

    -- Traverse for rules with type requirements and add them first.
    local with_count = #rules.with
    for index, rule in ipairs(rules.with) do
      if index == 1 then
        new_line("if env.istype(v, \"%s\") then", rule.type)
        new_line("\treturn %s", rule.code)
      elseif index < with_count then
        new_line("elseif env.istype(v, \"%s\") then", rule.type)
        new_line("\treturn %s", rule.code)
      else
        new_line("end")
      end
    end

    -- Traverse for rules without type requirements.
    local without_count = #rules.without
    local without_code = without_count > 0 and "return " or ""
    for index, rule in ipairs(rules.without) do
      without_code = without_code .. rule.code

      if index < without_count then
        without_code = without_code .. " and "
      end
    end

    new_line(without_code)
    new_line("end")

    -- Format code. Replacing all $-markers to 'v'.
    local code = table.concat(luac, "\n"):gsub("%$", "v")

    -- Generate function...
    local generator, err = loadstring(code)
    if generator then
      local checker = generator()

      -- Add watchman's environment to checker environment.
      local context = debug.getfenv(checker)
      context.env = env
      debug.setfenv(checker, context)

      -- Append new cache.
      cache = {
        checker = checker,
        rules = rules
      }

      -- Memoize generated checker and rule.
      memoizer:memoize_rule(str, cache)

      -- Return to the user.
      return checker, generate_error_message(cache.rules, var)
    else
      error(("watchman: got error '%s' while generating Lua code for '%s'"):format(err, str))
    end
  end
end

return M
