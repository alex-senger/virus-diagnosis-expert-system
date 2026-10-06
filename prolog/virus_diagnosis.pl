:- module(virus_diagnosis,
          [ start/0,
            demo/1,                     % +CaseId
            demo_all/0,
            run_consultation/1,         % -Diagnosis
            diagnose_case/2             % +CaseId, -Diagnosis
          ]).
:- use_module(library(error)).
:- use_module(library(lists)).
:- use_module(virus_diagnosis/engine).
:- use_module(virus_diagnosis/knowledge_base).
:- use_module(virus_diagnosis/cases).

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
    reset_consultation(case),
    forall(member(Attribute=Value, Facts), assume(Attribute, Value)),
    diagnosis(Diagnosis).

%!  demo(+CaseId) is det.
%
%   Print the facts and diagnosis of the sample patient CaseId.

demo(CaseId) :-
    diagnose_case(CaseId, Diagnosis),
    case(CaseId, Description, Facts),
    format("~n=== Case ~w ===~n~w~nPatient data:~n", [CaseId, Description]),
    forall(member(Attribute=Value, Facts),
           format("  ~w = ~w~n", [Attribute, Value])),
    print_diagnosis(Diagnosis).

%!  demo_all is det.
%
%   Run demo/1 for every sample patient.

demo_all :-
    forall(case(CaseId, _, _), demo(CaseId)).

banner :-
    format("~nVirusland virus diagnosis expert system~n\c
            =======================================~n\c
            Answer each question with yes/no, a number or an option.~n\c
            Type 'unknown' if you do not know, 'why' to see why a question~n\c
            is asked and 'quit' to stop.~n").

print_diagnosis(diagnosis(Infection, Reasons, Severity, RiskFactors,
                          Advice)) :-
    upcase_atom(Infection, Level),
    format("~n--- Diagnosis ---~n"),
    format("Virus infection: ~w~n", [Level]),
    print_list("Because", Reasons),
    format("Symptom severity: ~w~n", [Severity]),
    print_list("Risk factors", RiskFactors),
    print_list("Advice", Advice),
    format("(Decision support only; not a substitute for a medical \c
            diagnosis.)~n").

print_list(Title, []) :-
    !,
    format("~w: none~n", [Title]).
print_list(Title, Items) :-
    format("~w:~n", [Title]),
    forall(member(Item, Items), format("  - ~w~n", [Item])).
