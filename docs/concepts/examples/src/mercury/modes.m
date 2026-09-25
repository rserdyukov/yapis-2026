:- module modes.
:- interface.
:- import_module io.
:- pred main(io::di, io::uo) is det.
:- implementation.
:- import_module list, solutions.

:- pred append_demo(list(T), list(T), list(T)).
:- mode append_demo(in, in, out) is det.
:- mode append_demo(out, out, in) is multi.
append_demo([], Ys, Ys).
append_demo([X | Xs], Ys, [X | Zs]) :- append_demo(Xs, Ys, Zs).

:- type split ---> split(list(int), list(int)).

main(!IO) :-
    append_demo([1], [2], Joined),
    io.write(Joined, !IO), io.nl(!IO),
    solutions((pred(S::out) is multi :-
        append_demo(L, R, [1, 2]), S = split(L, R)), Splits),
    io.write_int(list.length(Splits), !IO), io.nl(!IO).
