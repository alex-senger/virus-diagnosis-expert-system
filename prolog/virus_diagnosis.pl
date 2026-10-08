:- module(virus_diagnosis,
          [ start/0,
            demo/1,                     % +CaseId
            demo_all/0,
            run_consultation/1,         % -Diagnosis
            diagnose_case/2,            % +CaseId, -Diagnosis
            diagnose_facts/2            % +Facts, -Diagnosis
          ]).
:- use_module(library(error)).
:- use_module(library(lists)).
:- use_module(virus_diagnosis/engine).
:- use_module(virus_diagnosis/knowledge_base).
:- use_module(virus_diagnosis/cases).
:- use_module(virus_diagnosis/questions, [label/2, attribute_label/2]).

/** <module> Expert system diagnosing the Virusland virus infection

Entry points of the expert system:

  - start/0 runs an interactive consultation.
  - demo/1 and demo_all/0 diagnose the sample patients of cases.pl.
*/

%!  start is det.
%
%   Interview the user about a patient and print the diagnosis.

start :-
    banner,
    catch(( run_consultation(Diagnosis),
            print_diagnosis(Diagnosis)
          ),
          consultation_aborted,
          format("~nConsultation aborted.~n")).

%!  run_consultation(-Diagnosis) is det.
%
%   Diagnose a patient by asking the user.

run_consultation(Diagnosis) :-
    reset_consultation(interactive),
    diagnosis(Diagnosis).

%!  diagnose_case(+CaseId, -Diagnosis) is det.
%
%   Diagnose the sample patient CaseId without asking questions.

diagnose_case(CaseId, Diagnosis) :-
    must_be(atom, CaseId),
    (   case(CaseId, _, Facts)
    ->  true
    ;   existence_error(case, CaseId)
    ),
    diagnose_facts(Facts, Diagnosis).

%!  diagnose_facts(+Facts:list, -Diagnosis) is det.
%
%   Diagnose a patient described by Attribute=Value pairs without asking
%   questions.

diagnose_facts(Facts, Diagnosis) :-
    must_be(list, Facts),
    reset_consultation(case),
    forall(member(Attribute=Value, Facts), assume(Attribute, Value)),
    diagnosis(Diagnosis).

%!  demo(+CaseId) is det.
%
%   Print the facts and diagnosis of the sample patient CaseId.

demo(CaseId) :-
    diagnose_case(CaseId, Diagnosis),
    case(CaseId, Description, Facts),
    format("~n=== Case ~w ===~n~w~n", [CaseId, Description]),
    print_patient(Facts),
    print_diagnosis(Diagnosis).

%!  demo_all is det.
%
%   Run demo/1 for every sample patient.

demo_all :-
    forall(case(CaseId, _, _), demo(CaseId)).

print_patient(Facts) :-
    format("Patient data:~n"),
    forall(member(Group-Title, [ bio-"Bio data", condition-"Conditions",
                                 symptom-"Symptoms", history-"History" ]),
           ( findall(Text,
                     ( member(Fact, Facts), fact_text(Fact, Group, Text) ),
                     Texts),
             (   Texts == []
             ->  Joined = "none"
             ;   atomic_list_concat(Texts, "; ", Joined)
             ),
             format("  ~w: ~w~n", [Title, Joined])
           )).

fact_text(age=Age, bio, Text) :-
    format(string(Text), "age ~w", [Age]).
fact_text(sex=Sex, bio, Text) :-
    format(string(Text), "~w", [Sex]).
fact_text(condition(Condition)=Answer, condition, Text) :-
    answer_text(Condition, Answer, Text).
fact_text(symptom(Symptom)=Answer, symptom, Text) :-
    answer_text(Symptom, Answer, Text).
fact_text(Attribute=Value, history, Text) :-
    \+ memberchk(Attribute, [age, sex, condition(_), symptom(_)]),
    attribute_label(Attribute, Label),
    format(string(Text), "~w: ~w", [Label, Value]).

answer_text(Term, Answer, Text) :-
    label(Term, Label),
    (   Answer == yes
    ->  Text = Label
    ;   format(string(Text), "~w (~w)", [Label, Answer])
    ).

banner :-
    format("~nVirusland virus diagnosis expert system~n\c
            =======================================~n\c
            Answer each question with yes/no, a number or an option.~n\c
            Type 'unknown' if you do not know, 'why' to see why a question~n\c
            is asked and 'quit' to stop.~n").

print_diagnosis(Diagnosis) :-
    upcase_atom(Diagnosis.infection, Level),
    upcase_atom(Diagnosis.rule, Rule),
    rule_description(Diagnosis.rule, Description),
    format("~n--- Diagnosis ---~n"),
    format("Virus infection: ~w~n", [Level]),
    format("Rule applied: ~w (~w)~n", [Rule, Description]),
    print_list("Because", Diagnosis.reasons),
    format("Symptom severity: ~w~n", [Diagnosis.severity]),
    print_list("Risk factors", Diagnosis.risk_factors),
    print_list("Advice", Diagnosis.advice),
    (   Diagnosis.unknown == []
    ->  true
    ;   print_list("Could not be established", Diagnosis.unknown)
    ),
    format("(Decision support only; not a substitute for a medical \c
            diagnosis.)~n").

print_list(Title, []) :-
    !,
    format("~w: none~n", [Title]).
print_list(Title, Items) :-
    format("~w:~n", [Title]),
    forall(member(Item, Items), format("  - ~w~n", [Item])).
