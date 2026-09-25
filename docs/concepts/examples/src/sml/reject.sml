use "opaque.sml";
(* A.t and B.t have distinct abstract identities. *)
val bad = B.read (A.make 7);
