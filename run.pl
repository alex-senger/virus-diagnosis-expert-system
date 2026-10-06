:- use_module(library(main)).
:- use_module('prolog/virus_diagnosis').

:- initialization(main, main).

%!  main(+Argv) is det.
%
%   Usage: swipl run.pl [demo [CaseId]]

main([]) :-
    !,
    start.
main([demo]) :-
    !,
    demo_all.
main([demo, CaseId]) :-
    !,
    demo(CaseId).
main(_) :-
    format(user_error, "Usage: swipl run.pl [demo [CaseId]]~n", []),
    halt(1).
