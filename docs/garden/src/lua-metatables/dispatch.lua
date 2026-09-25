-- Как интерпретатор выбирает метаметод: модель правил §2.4 на самом Lua.
-- Быстрый путь — встроенная операция; медленный — поиск метаметода
-- raw-доступом в метатаблице сначала левого, потом правого операнда.

-- --8<-- [start:model]
local function metamethod(v, event)
  local mt = getmetatable(v)
  return mt and rawget(mt, event)
end

local function add(a, b)
  if math.type(a) and math.type(b) then return a + b end   -- быстрый путь
  local h = metamethod(a, "__add") or metamethod(b, "__add")
  if h then return (h(a, b)) end                           -- одно значение
  error("attempt to perform arithmetic on a " .. type(a) .. " value", 2)
end

local function index(t, k)
  for _ = 1, 100 do                        -- в эталонной реализации тоже есть предел цепочки
    if type(t) == "table" then
      local v = rawget(t, k)
      if v ~= nil then return v end
    end
    local h = metamethod(t, "__index")
    if h == nil then
      if type(t) == "table" then return nil end
      error("attempt to index a " .. type(t) .. " value", 2)
    end
    if type(h) == "function" then return (h(t, k)) end
    t = h                                  -- таблица: повторить поиск в ней
  end
  error("'__index' chain too long; possible loop", 2)
end
-- --8<-- [end:model]

local Base = {greet = function() return "hi" end}
local Mid = setmetatable({}, {__index = Base})
local obj = setmetatable({}, {__index = Mid})
local V = {__add = function(a, b) return "V+" .. tostring(b) end}
local v = setmetatable({}, V)

print(add(1, 2), add(v, 3), add(3, v) == (3 + v))
print(index(obj, "greet")(), index(obj, "greet") == obj.greet, index(obj, "nope"))
print(pcall(add, {}, 1))
