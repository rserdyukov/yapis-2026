signature TOKEN = sig
  type t
  val make : int -> t
  val read : t -> int
end;

functor Visible () : TOKEN = struct
  type t = int
  fun make x = x
  fun read x = x
end;

structure A = Visible ();
structure B = Visible ();
val _ = print (Int.toString (B.read (A.make 7)) ^ "\n");
