-- Эффекты как значения: действие типа IO () можно хранить, передавать
-- и комбинировать; выполняется только то, что встроено в main.
module Main where

-- --8<-- [start:main]
greet :: String -> IO ()
greet name = putStrLn ("hello, " ++ name)

twice :: IO () -> IO ()
twice act = act >> act            -- обычная функция над действиями

square :: Integer -> Integer
square x = x * x                  -- чистая: тип не допускает ввода-вывода

main :: IO ()
main = do
  let hello   = greet "Ada"       -- значение типа IO (), ничего не напечатано
      actions = [hello, greet "Alan"]
      unused  = greet "nobody"    -- не встроено в main, поэтому не выполнится
  twice hello
  sequence_ (reverse actions)
  print (square 7 + square 7)     -- то же, что let y = square 7 in y + y
-- --8<-- [end:main]
