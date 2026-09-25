module BadIndex
import Data.Fin
import Data.Vect
import Index

%default total

bad : Int
bad = Index.lookup (FS (FS (FS FZ))) [10, 20, 30]
