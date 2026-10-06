:- module(test_virus_diagnosis, []).
:- use_module(library(plunit)).
:- use_module(library(lists)).
:- use_module(library(readutil)).
:- use_module('../prolog/virus_diagnosis').

/** <module> Tests for the virus diagnosis expert system

Run with: swipl -g run_tests -t halt test/test_virus_diagnosis.pl
*/

:- begin_tests(sample_cases).

test(elderly_serious, [Infection, Severity, Risks] ==
     [likely, serious, 3]) :-
    diagnose(elderly_serious, Infection, Severity, Risks).
test(young_mild, [Infection, Severity, Risks] == [likely, mild, 0]) :-
    diagnose(young_mild, Infection, Severity, Risks).
test(exposed_no_symptoms, [Infection, Severity] == [possible, none]) :-
    diagnose(exposed_no_symptoms, Infection, Severity, _).
test(copper_surface, Infection == unlikely) :-
    diagnose(copper_surface, Infection, _, _).
test(old_exposure, Infection == unlikely) :-
    diagnose(old_exposure, Infection, _, _).
test(outbreak_area_diabetic, [Infection, Risks] == [possible, 1]) :-
    diagnose(outbreak_area_diabetic, Infection, _, Risks).
test(typical_no_contact, Infection == likely) :-
    diagnose(typical_no_contact, Infection, _, _).
test(common_cold, [Infection, Severity] == [unlikely, mild]) :-
    diagnose(common_cold, Infection, Severity, _).
test(serious_advice) :-
    diagnose_case(elderly_serious, diagnosis(_, _, _, _, [Advice])),
    once(sub_string(Advice, _, _, _, "phone the doctor")).
test(unknown_case, [error(existence_error(case, nobody))]) :-
    diagnose_case(nobody, _).

:- end_tests(sample_cases).

:- begin_tests(reply_parsing).

test(yes) :-
    engine:reply_response("y", yes_no, answer(yes)).
test(unknown) :-
    engine:reply_response("unknown", number(0, 120), answer(unknown)).
test(why) :-
    engine:reply_response("why", yes_no, why).
test(number_in_range) :-
    engine:reply_response("42", number(0, 120), answer(42)).
test(number_out_of_range) :-
    engine:reply_response("130", number(0, 120), invalid(_)).
test(not_a_number) :-
    engine:reply_response("old", number(0, 120), invalid(_)).
test(choice_by_name) :-
    engine:reply_response("plastic", choice([copper, plastic]),
                          answer(plastic)).
test(choice_by_index) :-
    engine:reply_response("2", choice([copper, plastic]), answer(plastic)).

:- end_tests(reply_parsing).

:- begin_tests(interactive).

% Questions not needed by the rules (outbreak area, sex) are never asked,
% so the scripted answers are consumed exactly.
test(only_needed_questions, Infection-Severity == likely-mild) :-
    Answers = [ "n", "n", "n",                      % serious symptoms
                "yes", "why", "y", "n",             % common symptoms
                "maybe", "n", "n", "n", "n", "n", "n", "n", % less common
                "y", "n", "n",                      % contacts, surface
                "3",                                % days since exposure
                "30",                               % age
                "n", "n", "n", "n", "n"             % conditions
              ],
    consult_with(Answers, diagnosis(Infection, _, Severity, [], _), Rest),
    assertion(Rest == end_of_file).
test(quit_aborts, throws(consultation_aborted)) :-
    consult_with(["quit"], _, _).

:- end_tests(interactive).

diagnose(CaseId, Infection, Severity, RiskCount) :-
    diagnose_case(CaseId, diagnosis(Infection, _, Severity, Risks, _)),
    length(Risks, RiskCount).

%   Run an interactive consultation reading Answers as user input.  Rest
%   is the next line left unread afterwards.
consult_with(Answers, Diagnosis, Rest) :-
    atomic_list_concat(Answers, "\n", Text),
    setup_call_cleanup(
        open_string(Text, In),
        ( with_user_input(In,
                          with_output_to(string(_),
                                         run_consultation(Diagnosis))),
          read_line_to_string(In, Rest)
        ),
        close(In)).

with_user_input(In, Goal) :-
    stream_property(Old, alias(user_input)),
    !,
    setup_call_cleanup(set_stream(In, alias(user_input)),
                       once(Goal),
                       set_stream(Old, alias(user_input))).
