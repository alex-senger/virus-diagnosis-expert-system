:- module(test_virus_diagnosis, []).
:- use_module(library(plunit)).
:- use_module(library(lists)).
:- use_module(library(readutil)).
:- use_module('../prolog/virus_diagnosis').
:- use_module('../prolog/virus_diagnosis/cases').

/** <module> Tests for the virus diagnosis expert system

Run with: swipl -g run_tests -t halt test/test_virus_diagnosis.pl
*/

:- begin_tests(sample_cases).

%   expected(?CaseId, ?Infection, ?Rule, ?Severity, ?RiskFactorCount)
expected(elderly_serious,           likely,   r1, serious,      3).
expected(young_mild,                likely,   r1, mild,         0).
expected(nonspecific_after_contact, possible, r3, mild,         0).
expected(exposed_no_symptoms,       possible, r4, none,         0).
expected(copper_surface,            unlikely, r7, none,         0).
expected(old_exposure,              unlikely, r7, none,         0).
expected(old_contact_with_symptoms, possible, r6, mild,         0).
expected(symptoms_before_contact,   possible, r4, mild,         0).
expected(outbreak_area_diabetic,    possible, r5, mild,         1).
expected(typical_no_contact,        likely,   r2, mild,         0).
expected(common_cold,               unlikely, r7, mild,         0).
expected(chest_pain_no_contact,     unlikely, r7, serious,      2).
expected(unknown_answers,           unlikely, r7, undetermined, 0).

test(case, [ forall(expected(Id, Infection, Rule, Severity, Risks)),
             Actual == [Infection, Rule, Severity, Risks] ]) :-
    diagnose_case(Id, Diagnosis),
    length(Diagnosis.risk_factors, Count),
    Actual = [Diagnosis.infection, Diagnosis.rule, Diagnosis.severity, Count].
test(every_case_tested) :-
    forall(case(Id, _, _), expected(Id, _, _, _, _)).
test(serious_advice, forall(member(Id, [elderly_serious,
                                        chest_pain_no_contact]))) :-
    diagnose_case(Id, Diagnosis),
    Diagnosis.advice = [Advice],
    once(sub_string(Advice, _, _, _, "phone the doctor")).
test(unknown_case, [error(existence_error(case, nobody))]) :-
    diagnose_case(nobody, _).

:- end_tests(sample_cases).

:- begin_tests(boundaries).

test(exposure_today, Rule == r4) :-
    rule_for([contact_infected=yes, days_since_exposure=0], Rule).
test(exposure_14_days_ago, Rule == r4) :-
    rule_for([contact_infected=yes, days_since_exposure=14], Rule).
test(exposure_15_days_ago, Rule == r7) :-
    rule_for([contact_infected=yes, days_since_exposure=15], Rule).
test(incubation_0_days, Rule == r4) :-
    rule_for([ contact_infected=yes, days_since_exposure=3,
               days_since_onset=3, symptom(fever)=yes ], Rule).
test(incubation_1_day, Rule == r1) :-
    rule_for([ contact_infected=yes, days_since_exposure=1,
               days_since_onset=0, symptom(fever)=yes ], Rule).
test(incubation_14_days, Rule == r1) :-
    rule_for([ contact_infected=yes, days_since_exposure=14,
               days_since_onset=0, symptom(fever)=yes ], Rule).
test(incubation_15_days, Rule == r7) :-
    rule_for([ contact_infected=yes, days_since_exposure=15,
               days_since_onset=0, symptom(fever)=yes ], Rule).
test(age_70, Risks == []) :-
    diagnose_facts([age=70], Diagnosis),
    Risks = Diagnosis.risk_factors.
test(age_71, Count == 1) :-
    diagnose_facts([age=71, sex=female], Diagnosis),
    length(Diagnosis.risk_factors, Count).
test(copper_at_limit, Rule == r4) :-
    rule_for([ surface_contact=yes, surface_material=copper,
               surface_age_hours=4, days_since_exposure=1 ], Rule).
test(copper_past_limit, Rule == r7) :-
    rule_for([ surface_contact=yes, surface_material=copper,
               surface_age_hours=5, days_since_exposure=1 ], Rule).

:- end_tests(boundaries).

:- begin_tests(symptom_onset).

test(onset_fits_old_exposure, Rule == r1) :-
    rule_for([ contact_infected=yes, days_since_exposure=20,
               days_since_onset=10, symptom(fever)=yes ], Rule).
test(symptoms_before_exposure, Rule == r4) :-
    rule_for([ contact_infected=yes, days_since_exposure=3,
               days_since_onset=5, symptom(fever)=yes ], Rule).
test(unknown_onset_falls_back, Rule == r1) :-
    rule_for([ contact_infected=yes, days_since_exposure=5,
               days_since_onset=unknown, symptom(fever)=yes ], Rule).

test(old_exposure_explained_in_r6) :-
    diagnose_facts([ contact_infected=yes, days_since_exposure=20,
                     days_since_onset=2, symptom(fever)=yes,
                     symptom(dry_cough)=yes ], Diagnosis),
    assertion(Diagnosis.rule == r6),
    Diagnosis.reasons = [_, Exposure],
    once(sub_string(Exposure, _, _, _, "does not fit")).

:- end_tests(symptom_onset).

:- begin_tests(unknown_answers).

test(unknown_serious_symptoms) :-
    diagnose_facts([ symptom(breathing_difficulty)=unknown,
                     symptom(chest_pain)=unknown, age=unknown ],
                   Diagnosis),
    assertion(Diagnosis.severity == undetermined),
    assertion(length(Diagnosis.unknown, 3)),
    Diagnosis.advice = [Advice],
    once(sub_string(Advice, _, _, _, "phone the doctor")).

:- end_tests(unknown_answers).

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
test(choice_with_space) :-
    engine:reply_response("stainless steel", choice([copper, stainless_steel]),
                          answer(stainless_steel)).
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
                "1",                                % days since onset
                "30",                               % age
                "n", "n", "n", "n", "n"             % conditions
              ],
    consult_with(Answers, Diagnosis, Rest),
    assertion(Rest == end_of_file),
    assertion(Diagnosis.risk_factors == []),
    Infection = Diagnosis.infection,
    Severity = Diagnosis.severity.
test(quit_aborts, throws(consultation_aborted)) :-
    consult_with(["quit"], _, _).

:- end_tests(interactive).

rule_for(Facts, Rule) :-
    diagnose_facts(Facts, Diagnosis),
    Rule = Diagnosis.rule.

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
