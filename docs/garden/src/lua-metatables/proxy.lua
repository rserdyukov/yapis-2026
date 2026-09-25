-- Прокси, значения по умолчанию, таблица только для чтения.

-- --8<-- [start:proxy]
local function logged(target, name)
  -- прокси пуст, поэтому любое обращение к нему проходит через метаметоды
  return setmetatable({}, {
    __index = function(_, k)
      print("get " .. name .. "." .. tostring(k))
      return target[k]
    end,
    __newindex = function(_, k, v)
      print("set " .. name .. "." .. tostring(k) .. " = " .. tostring(v))
      target[k] = v
    end,
  })
end

local cfg = logged({port = 80}, "cfg")
cfg.port = cfg.port + 1
print(cfg.port, rawget(cfg, "port"))
-- --8<-- [end:proxy]

-- --8<-- [start:defaults]
local function withDefault(t, d)
  return setmetatable(t, {__index = function() return d end})
end

local counts = withDefault({}, 0)
for w in ("a b a c a"):gmatch("%a") do counts[w] = counts[w] + 1 end
print(counts.a, counts.b, counts.z, rawget(counts, "z"))
-- --8<-- [end:defaults]

-- --8<-- [start:readonly]
local function readonly(t)
  return setmetatable({}, {
    __index = t,
    __newindex = function(_, k) error("attempt to modify read-only field " .. tostring(k), 2) end,
    __len = function() return #t end,
  })
end

local days = readonly({"Mon", "Tue", "Wed"})
print(days[2], #days)
print(pcall(function() days[4] = "Thu" end))
rawset(days, 4, "Thu")                -- raw-доступ обходит метаметоды
print(days[4])
-- --8<-- [end:readonly]
