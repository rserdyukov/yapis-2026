signature TOKEN = sig
  type t
  val make : int -> t
  val read : t -> int
end;

functor Fresh () :> TOKEN = struct
  type t = int
  fun make x = x
  fun read x = x
end;

structure A = Fresh ();
structure B = Fresh ();
val _ = print (Int.toString (A.read (A.make 7)) ^ "\n");
