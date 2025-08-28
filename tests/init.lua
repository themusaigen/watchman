-- Perform tests only in developers mode.
if MOONLY_ENVIRONMENT and not MOONLY_BUNDLED then
  local watchman = require("watchman")

  -- Basic typecheck.
  print("Basic typecheck:", watchman.test(1, "number")) -- Basic typecheck: true

  -- Failed basic typecheck.
  print("Failed typecheck:", watchman.test(1, "string")) -- Failed typecheck: false, string expected, got number

  -- Accept any type.
  print("Any type:", watchman.test(1, "?")) -- Any type: true

  -- Accept any but not nil.
  print("Not nil:", watchman.test(nil, "!")) -- Not nil: false, any not nil type expected, got nil

  -- Typeunions.
  print("Typeunions:", watchman.test({}, "string|number")) -- Typeunions: false string or number expected, got table

  -- Optional typeunions.
  print("Optional typeunions:", watchman.test({}, "(string|number)?")) -- Optional typeunions: false string or number or no value expected, got table

  -- Custom user-rules.
  -- User rules starts after first semicolon.
  -- $ means '0' in this case.
  print("Custom user-rule:", watchman.test(0, "number; $ > 0")) -- Custom user-rule: false failed check '$ > 0'

  -- Multiple user-rules.
  -- Or you can write it one rule using and, or, not keywords like basic Lua code.
  print("Multiple user-rules:", watchman.test(0, "number; $ > 0; $ < 64")) -- Multiple user-rules: false failed checks '$ > 0', '$ < 64'

  -- User rules for specific types.
  -- '<...>:' means 'perform this rule for this type'.
  print("Type-specific rules:", watchman.test("", "?; <number>: $ >= 0; <string>: #$ > 0")) -- Type-specific rules: false failed check '#$ > 0'

  --- Assertions.
  watchman.assert(1, "number") -- Same as all above, but throws error on fail, also adds 'assertion failed:' prefix to error message.

  --- Multiple args checks.
  watchman.check(1, "number", "", "string", {}, "table") -- Same as test, but throws error on fail, also adds 'bad argument #<arg number>:' prefix to error mesasge.

  --- Function contracts.
  local function sum(a, b)
    -- Same as test, but throws error on fail, automatically adds function arguments from stack using 'debug' builtin table, also formats message like 'bad argument '<argname>' to function '<funcname>' (<error>)'.
    -- Don't works on varargs.
    -- Rules count must match arguments count, otherwise error.

    -- Why it's named 'contract'?:
    -- Answer: https://en.cppreference.com/w/cpp/language/contracts.html
    -- Watchman's contract not that powerful like C++ contracts, but why not lol.
    watchman.contract("number", "number")
    return a + b
  end

  print("Sum:", sum(2, 4))                       -- 6
  -- nil because of pcall and we on main scope.
  print("Sum (must fail):", pcall(sum, "", nil)) -- false, bad argument 'a' to function 'nil' (number expected, got string)

  -- Custom checks.
  local env = require("watchman.env")

  -- You can spoof watchman's type function. By default it is builtin 'type' function.
  env.type = function(v)
    local typeof = type(v)
    if typeof == "table" then
      return v.__typename or typeof -- For your class system, other purposes...
    end
    return typeof
  end

  -- Also you can spoof watchman's 'istype' function.
  env.istype = function(v, typeof)
    return env.type(v) == typeof -- Default function.
  end

  -- Perform check on that bro.
  do
    local T = { __typename = "Person", age = 19 }

    print("Custom checks:", watchman.test(T, "Person; $.age > 18")) -- true
  end

  -- Watchman in methods.
  do
    local T = {}

    function T.foo(self, a, b)
      watchman.contract("number", "number")
    end

    function T:baz(a, b)
      watchman.contract("number", "number")

      -- Also can check self if needed.
      watchman.contract("table", "number", "number")
    end

    -- Handle boths variants.
    T.foo(T, 1, 2)
    T:baz(1, 2)
  end

  -- Don't perform code after.
  return
end

-- Little hack. Because moonly bundles `init.lua` files as their directory names.
package.preload["watchman.main"] = package.preload["watchman"]

-- Return watchman.
return require("watchman.main")
