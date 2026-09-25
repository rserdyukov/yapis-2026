-- Класс, конструктор и одиночное наследование на таблицах и метатаблицах.

-- --8<-- [start:class]
local Account = {}
Account.__index = Account          -- экземпляры ищут методы в Account

function Account.new(owner, balance)
  local self = setmetatable({}, Account)
  self.owner = owner
  self.balance = balance or 0
  return self
end

function Account:deposit(v)        -- то же, что Account.deposit(self, v)
  self.balance = self.balance + v
end

function Account:report()
  return self.owner .. ": " .. self.balance
end

local a = Account.new("Ann", 100)
a:deposit(50)                      -- то же, что a.deposit(a, 50)
print(a:report())
print(rawget(a, "deposit"), rawget(Account, "deposit") ~= nil)
-- --8<-- [end:class]

-- --8<-- [start:inherit]
local Savings = setmetatable({}, {__index = Account})  -- родитель
Savings.__index = Savings

function Savings.new(owner, balance, rate)
  local self = Account.new(owner, balance)
  self.rate = rate
  return setmetatable(self, Savings)                   -- смена «класса»
end

function Savings:addInterest()
  self:deposit(self.balance * self.rate)               -- метод родителя
end

function Savings:report()                              -- переопределение
  return "[savings] " .. Account.report(self)          -- вызов «super»
end

local s = Savings.new("Bob", 200, 0.5)
s:addInterest()
print(s:report())
-- поиск s.deposit: s -> Savings -> Account
print(rawget(s, "deposit"), rawget(Savings, "deposit"), Account.deposit == s.deposit)
print(getmetatable(s) == Savings, getmetatable(Savings).__index == Account)
-- --8<-- [end:inherit]
