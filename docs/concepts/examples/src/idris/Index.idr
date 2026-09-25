module Index
import Data.Fin
import Data.Vect

%default total

export
lookup : Fin n -> Vect n a -> a
lookup FZ (x :: xs) = x
lookup (FS k) (x :: xs) = lookup k xs

example : Int
example = lookup (FS FZ) [10, 20, 30]

main : IO ()
main = printLn example
