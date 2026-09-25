-- Перегрузка операторов метаметодами.

local V = {}
V.__index = V

local function vec(x, y) return setmetatable({x = x, y = y}, V) end

V.__add = function(a, b)
  if type(a) == "number" then a, b = b, a end   -- 2 + v и v + 2
  if type(b) == "number" then return vec(a.x + b, a.y + b) end
  return vec(a.x + b.x, a.y + b.y)
end
V.__eq = function(a, b) return a.x == b.x and a.y == b.y end
V.__lt = function(a, b) return a:len2() < b:len2() end
V.__len = function(a) return 2 end                 -- «размерность»
V.__tostring = function(a) return "(" .. a.x .. ", " .. a.y .. ")" end
function V:len2() return self.x * self.x + self.y * self.y end

local p, q = vec(1, 2), vec(3, 4)
print(tostring(p + q), tostring(p + 10), tostring(10 + p))
print(p == vec(1, 2), rawequal(p, vec(1, 2)))     -- __eq против идентичности
print(p < q, q < p, #p)
print(pcall(function() return p .. q end))        -- __concat не задан
print(pcall(function() return p <= q end))        -- __le не задан
