-- Мемоизация через __index-функцию и функтор через __call.

-- --8<-- [start:memo]
local calls = 0
local fib
fib = setmetatable({[0] = 0, [1] = 1}, {
  __index = function(t, n)
    calls = calls + 1
    local v = t[n - 1] + t[n - 2]
    rawset(t, n, v)                    -- следующий раз __index не сработает
    return v
  end,
})
print(fib[80], calls)
print(fib[80], calls)
-- --8<-- [end:memo]

-- --8<-- [start:call]
local Counter = setmetatable({}, {
  __call = function(cls, start)        -- Counter(10) — «конструктор»
    return setmetatable({n = start}, cls)
  end,
})
Counter.__index = Counter
Counter.__call = function(self, step)  -- c(5) — функтор
  self.n = self.n + (step or 1)
  return self.n
end

local c = Counter(10)
print(c(), c(5), c.n, type(c))
-- --8<-- [end:call]
