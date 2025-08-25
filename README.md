# Watchman — Runtime Type Checking and Function Contracts for Lua
Watchman is a lightweight, flexible runtime type checker and function contract system for Lua. It helps you write safer, more predictable code by validating values, arguments, and custom conditions at runtime — with clear, descriptive error messages. Inspired by [C++26 contracts](https://en.cppreference.com/w/cpp/language/contracts.html) and [argcheck](https://github.com/torch/argcheck) library.

## Features
* ✅ Basic type checking: `number`, `string`, `table`, etc.
* 🔁 Type unions: `string|number`
* ❓ Optional types: `string?`, `(string|number)?`
* ⚠️ Nil exclusion: `!` (any type except nil)
* 🛠️ Custom user rules: e.g., `number; $ > 0`
* 🧩 Type-specific rules: apply logic only to certain types
* 📣 Assertions & argument checking: fail-fast with meaningful errors
* 🤖 Function contracts: validate function arguments by type and rule
* 🔧 Extensible: override `type` and `istype` for custom behavior (e.g., OOP systems)

##  Installation

0. Watchman distributes as single-file library.
1. Download `watchman.lua` from GitHub releases.
2. Move `watchman.lua` into your project or `moonloader/lib` (for MoonLoader users).
3. Then require it:
```lua
local watchman = require("watchman")
```

## Examples (Basic)
1. Type Checking with `watchman.test(value, rule)`. Returns true if the value matches the rule, false and error message otherwise.
```lua
print(watchman.test(1, "number"))           --> true
print(watchman.test(1, "string"))           --> false
print(watchman.test(nil, "?"))              --> true  (any type)
print(watchman.test(nil, "!"))              --> false (not nil)
print(watchman.test({}, "string|number"))   --> false (got table)
print(watchman.test({}, "(string|number)?"))--> false (still not string/number)
```
2. Custom Rules with `;`. Append conditions after a semicolon. `$` refers to the value being tested.
```lua
print(watchman.test(5, "number; $ > 0"))     --> true
print(watchman.test(-1, "number; $ > 0"))    --> false (failed '$ > 0')
print(watchman.test("", "string; #$ > 0"))   --> false (empty string)
```
3. Multiple rules:
```lua
watchman.test(0, "number; $ > 0; $ < 64") --> false (both checks fail)
```
4. Type-Specific Rules. Apply rules only to specific types using `<type>`:
```lua
-- Apply any type. For numbers -> check it is positive, for strings -> it is empty.
watchman.test("", "?; <number>: $ >= 0; <string>: #$ > 0")
-- fails because string is empty: '#$ > 0' fails
```

## Examples (advanced)
1. Assertions and Argument Validation.

`watchman.assert(value, rule)` acts like `watchman.test`, but throws an error on failure.

```lua
watchman.assert(1, "number")        -- OK
watchman.assert({}, "string")       -- Error: assertion failed: string expected, got table
```


`watchman.check(..., rule1, ..., rule2, ...)` checks multiple values in sequence.

```lua
watchman.check(1, "number", "hello", "string", {}, "table") -- OK
watchman.check(1, "string") -- Error: bad argument #1: string expected, got number
```

2. Function contracts.

`watchman.contract(...)` used inside functions to validate
parameters. Automatically detects argument names and function name. Requires debug information `debug.getinfo`. Does not work with varargs `...`.

```lua
local function divide(a, b)
  watchman.contract("number", "number; $ ~= 0")
  return a / b
end

divide(10, 2)  -- OK
divide("x", 2) -- ERROR: bad argument 'a' to function 'divide' (number expected, got string)
divide(10, 0) -- ERROR: bad argument 'b' to function 'divide' (failed check 'b ~= 0')
```

3. Custom Watchman's environment.

You can override how Watchman detects types using `watchman.env`.

```lua
local env = require("watchman.env")

-- Customize type detection
env.type = function(v)
  local t = type(v)
  if t == "table" and v.__typename then
    return v.__typename
  end
  return t
end

-- Optional: customize type comparison
env.istype = function(v, typename)
  return env.type(v) == typename
end

-- Now you can use custom types!
local Person = { __typename = "Person", age = 25 }
print(watchman.test(Person, "Person; $.age > 18")) --> true
```

Also see `tests/init.lua` for more examples.

# License

Watchman licensed under `MIT` license. See `LICENSE` for detailed information.
