-- Нестрогость: аргумент, который не нужен результату, не вычисляется.
module Main where

-- --8<-- [start:main]
constOne :: a -> Integer
constOne _ = 1

main :: IO ()
main = do
  print (constOne undefined)              -- 1: аргумент не нужен
  print (fst (42, undefined :: Integer))  -- 42: вторую компоненту не трогаем
  print (length [undefined, undefined :: Integer]) -- 2: элементы не вычисляются
  let xs = [1, 2, error "третий элемент"] :: [Integer]
  print (take 2 xs)                       -- [1,2]
  print (undefined `seq` (0 :: Integer))  -- seq ⊥ b = ⊥: печать не начнётся
-- --8<-- [end:main]
