-- Детерминированная очистка: переменная <close> и метаметод __close (Lua 5.4+).

local function resource(name)
  print("open " .. name)
  return setmetatable({name = name}, {
    __close = function(self, err)
      print("close " .. self.name .. (err and (" after error: " .. tostring(err)) or ""))
    end,
  })
end

do
  local a <close> = resource("A")
  local b <close> = resource("B")
  print("work")
end                                    -- закрываются в обратном порядке: B, A

print(pcall(function()
  local f <close> = resource("F")
  error("boom", 0)
end))

-- __gc вызывается сборщиком мусора, момент не гарантирован;
-- здесь сборка запускается явно, чтобы вывод был воспроизводим.
do
  setmetatable({}, {__gc = function() print("gc finalizer") end})
end
collectgarbage()
print("end")
