---@class Watchman: table
local M           = {
  _NAME = "Watchman",
  _AUTHOR = "Musaigen",
  _VERSION = "1.0.2",
  _DESCRIPTION = "Powerful argument/type/rule checker."
}

-- Modules

local lexer       = require("watchman.lexer")
local parser      = require("watchman.parser")
local typechecker = require("watchman.typechecker")
local translator  = require("watchman.translator")
local memoizer    = require("watchman.memoizer")

--- Produces test on specified variable with concrete rule.
---@param var any
---@param rule string
---@return boolean
---@return string?
function M.test(var, rule)
  -- Try to use memoized AST and rule code.
  local cache = memoizer:ast(rule)
  if not cache then
    local tokens, code = lexer.lex(rule)

    cache = {
      program  = parser.parse(tokens),
      rulecode = code
    }

    memoizer:memoize_ast(rule, cache)
  end

  -- Run typechecker for that variable.
  do
    local passed, error = typechecker:run(var, cache.program)
    if not passed then
      return false, error
    end
  end

  -- Run checker for that variable if needed.
  do
    if cache.rulecode then
      local checker, error = translator.translate(cache.rulecode, var)
      if not checker(var) then
        return false, error
      end
    end
  end

  -- All succesfull
  return true
end

--- Produces assertion on specified variable with concrete rule.
---@param var any
---@param rule string
function M.assert(var, rule)
  local passed, err = M.test(var, rule)
  if not passed then
    error(("assertion failed: %s"):format(err))
  end
end

--- Produces checks on multiple variables.
---@param ... any
function M.check(...)
  -- Pack args.
  local args = table.pack(...)

  -- Count of rules must match count of params.
  assert(args.n % 2 == 0, "watchman.check: arguments count mismatch.")

  -- Traverse around all arguments.
  for i = 1, args.n, 2 do
    local passed, err = M.test(args[i], args[i + 1])
    if not passed and err then
      -- Compute argument number.
      local argn = i > 1 and i - 1 or i

      -- Beautify error message.
      local message = err:gsub("%$", "#" .. argn)

      -- Error!
      error(("bad argument #%d: %s"):format(argn, message))
    end
  end
end

--- Applies a 'contract' to caller function.
---@param ... string
function M.contract(...)
  -- Get information about caller.
  local caller = debug.getinfo(2)

  -- Pack rules.
  local rules = table.pack(...)

  -- Handle Lua methods. Catch `object:method()` and 'object.method(object, ...)' calls.
  local arg1n = debug.getlocal(2, 1)
  if caller.namewhat == "method" or arg1n == "self" then
    if rules.n < caller.nparams then
      table.insert(rules, 1, "?")

      -- Increment count of rules.
      rules.n = rules.n + 1
    end
  end

  -- Count of rules must match nparams in caller.
  assert(rules.n == caller.nparams, "watchman.contract: arguments count mismatch.")

  -- Traverse around all params.
  for argn = 1, caller.nparams do
    local argname, argvalue = debug.getlocal(2, argn)

    -- Do test.
    local passed, err = M.test(argvalue, rules[argn])
    if not passed and err then
      -- Beautify error message.
      local message = err:gsub("%$", argname)

      -- Error!
      error(("bad argument '%s' to function '%s' (%s)"):format(argname, caller.name, message))
    end
  end
end

return M
