-- Цена ленивости: foldl накапливает цепочку отложенных сложений (thunk),
-- foldl' из Data.List вычисляет аккумулятор на каждом шаге.
module Main where

import Data.List (foldl')

-- --8<-- [start:main]
sumLazy :: [Integer] -> Integer
sumLazy = foldl (+) 0        -- (((0 + 1) + 2) + 3) ... строится как thunk

sumStrict :: [Integer] -> Integer
sumStrict = foldl' (+) 0     -- аккумулятор приводится к WHNF на каждом шаге

-- Та же идея вручную: seq требует вычислить acc' до рекурсивного вызова.
sumSeq :: Integer -> [Integer] -> Integer
sumSeq acc []       = acc
sumSeq acc (x : xs) = let acc' = acc + x in acc' `seq` sumSeq acc' xs

main :: IO ()
main = do
  print (sumStrict [1 .. 1000000])
  print (sumSeq 0 [1 .. 1000000])
  print (sumLazy [1 .. 1000000])   -- тот же результат, но больше памяти без -O
-- --8<-- [end:main]
