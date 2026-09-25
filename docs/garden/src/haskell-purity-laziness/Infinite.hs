-- Бесконечные структуры: при нестрогой семантике вычисляется только
-- та часть списка, которую действительно потребовали.
module Main where

-- --8<-- [start:main]
nats :: [Integer]
nats = [0 ..]                               -- бесконечный список

fibs :: [Integer]
fibs = 0 : 1 : zipWith (+) fibs (tail fibs) -- список определён через себя

primes :: [Integer]
primes = sieve [2 ..]
  where
    sieve (p : xs) = p : sieve [x | x <- xs, x `mod` p /= 0]

main :: IO ()
main = do
  print (take 5 nats)
  print (take 10 fibs)
  print (take 10 primes)
  print (takeWhile (< 100) (map (^ 2) nats))
-- --8<-- [end:main]
