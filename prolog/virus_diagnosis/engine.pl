:- module(engine,
          [ reset_consultation/1,       % +Mode
            assume/2,                   % +Attribute, +Value
            holds/1,                    % +Attribute
            value/2,                    % +Attribute, ?Value
            trying/2                    % +Description, :Goal
          ]).
:- use_module(library(error)).
:- use_module(library(lists)).
:- use_module(library(readutil)).
:- use_module(questions).

/** <module> Inference support for the virus diagnosis expert system

Keeps the facts known about the current patient and obtains missing
facts on demand.  Rules only call holds/1 and value/2, so Prolog's own
backward chaining decides which questions are asked and in which order.

In `interactive` mode a missing fact is asked from the user, who may
also reply `why` to see the current line of reasoning.  In `case` mode
only recorded facts are used: unanswered yes/no questions count as `no`
and other questions as `unknown`.
*/

:- meta_predicate
    trying(+, 0).

:- dynamic
    known/2,                            % Attribute, Value
    consultation_mode/1.                % interactive | case

%!  reset_consultation(+Mode) is det.
%
%   Forget everything about the previous patient and start a new
%   consultation in Mode, either `interactive` or `case`.

reset_consultation(Mode) :-
    must_be(oneof([interactive, case]), Mode),
    retractall(known(_, _)),
    retractall(consultation_mode(_)),
    assertz(consultation_mode(Mode)),
    nb_setval(why_stack, []).

%!  assume(+Attribute, +Value) is det.
%
%   Record Value as the answer for Attribute.

assume(Attribute, Value) :-
    must_be(ground, Attribute-Value),
    retractall(known(Attribute, _)),
    assertz(known(Attribute, Value)).

%!  holds(+Attribute) is semidet.
%
%   True if the yes/no question Attribute is answered `yes`.

holds(Attribute) :-
    value(Attribute, yes).

%!  value(+Attribute, ?Value) is semidet.
%
%   Value is the answer for Attribute.  A missing answer is obtained
%   once and memoised, so each question is asked at most once.

value(Attribute, Value) :-
    (   known(Attribute, Known)
    ->  true
    ;   acquire(Attribute, Known),
        assertz(known(Attribute, Known))
    ),
    Value = Known.

acquire(Attribute, Value) :-
    (   question(Attribute, Prompt, Type)
    ->  true
    ;   existence_error(question, Attribute)
    ),
    (   consultation_mode(interactive)
    ->  ask(Prompt, Type, Value)
    ;   default_answer(Type, Value)
    ).

default_answer(yes_no, no) :- !.
default_answer(_, unknown).

%!  trying(+Description:string, :Goal) is nondet.
%
%   Call Goal while Description is the current line of reasoning.  The
%   stack of descriptions answers the user's `why` questions.

trying(Description, Goal) :-
    why_stack(Stack),
    b_setval(why_stack, [Description|Stack]),
    call(Goal),
    b_setval(why_stack, Stack).

why_stack(Stack) :-
    (   nb_current(why_stack, Current)
    ->  Stack = Current
    ;   Stack = []
    ).

%   User dialogue

ask(Prompt, Type, Value) :-
    options_hint(Type, Hint),
    repeat,
    format("~n~w ~w~n> ", [Prompt, Hint]),
    flush_output,
    read_reply(Reply),
    reply_response(Reply, Type, Response),
    respond(Response, Value),
    !.

respond(answer(Value), Value).
respond(why, _) :-
    explain_why,
    fail.
respond(invalid(Message), _) :-
    format("  ~w~n", [Message]),
    fail.

read_reply(Reply) :-
    read_line_to_string(user_input, Line),
    (   Line == end_of_file
    ->  throw(consultation_aborted)
    ;   normalize_space(string(Trimmed), Line),
        string_lower(Trimmed, Reply)
    ),
    (   Reply == "quit"
    ->  throw(consultation_aborted)
    ;   true
    ).

%!  reply_response(+Reply:string, +Type, -Response) is det.
%
%   Response is answer(Value), `why` or invalid(Message).

reply_response("why", _, why) :- !.
reply_response(Reply, _, answer(unknown)) :-
    memberchk(Reply, ["u", "unknown"]),
    !.
reply_response(Reply, Type, Response) :-
    (   typed_answer(Type, Reply, Value)
    ->  Response = answer(Value)
    ;   invalid_message(Type, Message),
        Response = invalid(Message)
    ).

typed_answer(yes_no, Reply, Answer) :-
    yes_no(Reply, Answer).
typed_answer(number(Min, Max), Reply, Number) :-
    whole_number(Reply, Number),
    between(Min, Max, Number).
typed_answer(choice(Options), Reply, Option) :-
    (   whole_number(Reply, Index)
    ->  nth1(Index, Options, Option)
    ;   atom_string(Option, Reply),
        memberchk(Option, Options)
    ).

yes_no("y", yes).
yes_no("yes", yes).
yes_no("n", no).
yes_no("no", no).

whole_number(Reply, Number) :-
    catch(number_string(Number, Reply), _, fail),
    integer(Number).

options_hint(yes_no, "[yes/no/unknown/why]").
options_hint(number(Min, Max), Hint) :-
    format(string(Hint), "[~w-~w/unknown/why]", [Min, Max]).
options_hint(choice(Options), Hint) :-
    findall(Option,
            ( nth1(Index, Options, Name),
              format(string(Option), "~w=~w", [Index, Name])
            ),
            Numbered),
    atomic_list_concat(Numbered, ", ", Text),
    format(string(Hint), "[~w/unknown/why]", [Text]).

invalid_message(yes_no, "Please answer yes, no, unknown or why.").
invalid_message(number(Min, Max), Message) :-
    format(string(Message),
           "Please enter a whole number from ~w to ~w, unknown or why.",
           [Min, Max]).
invalid_message(choice(_),
                "Please enter an option name or number, unknown or why.").

explain_why :-
    why_stack(Stack),
    (   Stack = [Goal|Outer]
    ->  format("  I am trying to establish ~w", [Goal]),
        forall(member(Reason, Outer),
               format(",~n    which is needed to establish ~w", [Reason])),
        format(".~n")
    ;   format("  This information is needed for the diagnosis.~n")
    ).
