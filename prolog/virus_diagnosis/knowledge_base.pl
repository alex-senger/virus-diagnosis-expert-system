:- module(knowledge_base,
          [ diagnosis/1,                % -Diagnosis
            rule_description/2          % ?Rule, ?Description
          ]).
:- use_module(library(aggregate)).
:- use_module(library(apply)).
:- use_module(library(lists)).
:- use_module(engine).
:- use_module(parameters).
:- use_module(questions).

/** <module> Knowledge base of the virus diagnosis expert system

Domain facts and diagnosis rules derived from the Virusland outbreak
scenario.  Patient data is obtained through holds/1 and value/2, which
ask the user only when a rule actually needs the information.
*/

                 /*******************************
                 *        DOMAIN FACTS          *
                 *******************************/

%!  symptom(?Symptom, ?Class) is nondet.
%
%   Class is `common`, `less_common` or `serious`.

symptom(fever, common).
symptom(dry_cough, common).
symptom(tiredness, common).
symptom(aches_pains, less_common).
symptom(sore_throat, less_common).
symptom(diarrhoea, less_common).
symptom(conjunctivitis, less_common).
symptom(headache, less_common).
symptom(anosmia, less_common).
symptom(running_nose, less_common).
symptom(breathing_difficulty, serious).
symptom(chest_pain, serious).
symptom(loss_of_speech_or_movement, serious).

%!  pre_existing_condition(?Condition) is nondet.
%
%   Conditions that raise the risk of severe illness.

pre_existing_condition(hypertension).
pre_existing_condition(diabetes).
pre_existing_condition(cardiovascular_disease).
pre_existing_condition(chronic_respiratory_disease).
pre_existing_condition(cancer).

                 /*******************************
                 *          DIAGNOSIS           *
                 *******************************/

%!  diagnosis(-Diagnosis:dict) is det.
%
%   Diagnose the current patient.  Diagnosis is a dict with the keys
%
%     - infection: `likely`, `possible` or `unlikely`
%     - rule: the infection rule that was applied (r1 .. r7)
%     - reasons: strings explaining the infection level
%     - severity: `serious`, `mild` or `none`
%     - risk_factors: strings describing the risk factors
%     - advice: strings with the recommended actions

diagnosis(diagnosis{infection: Infection, rule: Rule, reasons: Reasons,
                    severity: Severity, risk_factors: RiskFactors,
                    advice: Advice}) :-
    trying("the likelihood of a virus infection",
           infection(Rule, Infection, Reasons)),
    severity(Severity),
    trying("whether the patient is at risk of severe illness",
           risk_factors(RiskFactors)),
    advice(Infection, Severity, RiskFactors, Advice).

%!  infection(-Rule, -Level, -Reasons) is det.
%
%   Level is the conclusion of Rule, the first infection rule that is
%   proved.

infection(Rule, Level, Reasons) :-
    trying("which symptoms the patient shows", symptom_profile),
    once(infection_rule(Rule, Level, Reasons)).

symptom_profile :-
    forall(member(Class, [serious, common, less_common]),
           present_symptoms(Class, _)).

%!  rule_description(?Rule, ?Description:string) is nondet.

rule_description(r1, "recent exposure explaining characteristic symptoms").
rule_description(r2, "typical clinical picture").
rule_description(r3, "recent exposure with non-specific symptoms").
rule_description(r4, "recent exposure, possibly still incubating").
rule_description(r5, "outbreak-area stay with characteristic symptoms").
rule_description(r6, "suggestive symptoms without a recent exposure").
rule_description(r7, "no rule for a suspected infection applies").

%!  infection_rule(?Rule, ?Level, -Reasons) is nondet.
%
%   Rules are ordered from the strongest to the weakest conclusion.

infection_rule(r1, likely, [Exposure, Symptoms]) :-
    trying("whether the patient had a recent exposure to the virus",
           recent_exposure(symptomatic, Exposure)),
    characteristic_symptoms(Symptoms).
infection_rule(r2, likely, [Symptoms]) :-
    typical_clinical_picture(Symptoms).
infection_rule(r3, possible, [Exposure, Symptoms]) :-
    recent_exposure(symptomatic, Exposure),
    nonspecific_symptoms(Symptoms).
infection_rule(r4, possible, [Exposure, Note]) :-
    recent_exposure(incubating, Exposure),
    incubation_note(Note).
infection_rule(r5, possible, [Exposure, Symptoms]) :-
    characteristic_symptoms(Symptoms),
    trying("whether the patient was exposed in the outbreak area",
           holds(outbreak_area)),
    incubation_period(_, Max),
    format(string(Exposure),
           "stayed in the outbreak area (Virusville) in the last ~w days",
           [Max]).
infection_rule(r6, possible, [Symptoms, "no known exposure to the virus"]) :-
    suggestive_clinical_picture(Symptoms).
infection_rule(r7, unlikely, Reasons) :-
    findall(Reason, unlikely_reason(Reason), Reasons).

incubation_note(Note) :-
    presymptomatic_days(Days),
    (   no_symptoms
    ->  format(string(Note),
               "no symptoms yet: the patient may be incubating or \c
                asymptomatic and can be contagious up to ~w days before \c
                symptoms appear", [Days])
    ;   Note = "the symptoms started too early to be caused by this \c
                exposure, but the patient may still be incubating"
    ).

unlikely_reason(Reason) :-
    exposure_sources(Sources),
    value(days_since_exposure, Days),
    integer(Days),
    (   no_symptoms
    ->  Phase = incubating
    ;   Phase = symptomatic
    ),
    exposure_window(Phase, Min, Max),
    \+ between(Min, Max, Days),
    atomic_list_concat(Sources, "; ", Text),
    format(string(Reason),
           "~w ~w day(s) ago lies outside the ~w-~w day incubation window",
           [Text, Days, Min, Max]).
unlikely_reason(Reason) :-
    holds(surface_contact),
    value(surface_material, Material),
    value(surface_age_hours, Hours),
    survival_hours(Material, Limit),
    integer(Hours),
    Hours > Limit,
    label(Material, Name),
    format(string(Reason),
           "the ~w surface was touched ~w h after contamination, but the \c
            virus survives there only up to ~w h", [Name, Hours, Limit]).
unlikely_reason("no exposure to the virus could be established") :-
    \+ exposure_sources(_).
unlikely_reason(Reason) :-
    (   no_symptoms
    ->  Reason = "no symptoms (an asymptomatic infection cannot be fully \c
                  ruled out)"
    ;   present_symptoms(_, Symptoms),
        maplist(label, Symptoms, Labels),
        atomic_list_concat(Labels, ", ", Text),
        format(string(Reason),
               "the symptoms (~w) do not indicate the virus without a \c
                recent exposure", [Text])
    ).

                 /*******************************
                 *          SYMPTOMS            *
                 *******************************/

%!  present_symptoms(?Class, -Symptoms) is nondet.
%
%   Symptoms are the patient's symptoms of Class.  With unbound Class
%   all symptoms are returned.

present_symptoms(Class, Symptoms) :-
    var(Class),
    !,
    findall(Symptom,
            ( symptom(Symptom, _), holds(symptom(Symptom)) ),
            Symptoms).
present_symptoms(Class, Symptoms) :-
    findall(Symptom,
            ( symptom(Symptom, Class), holds(symptom(Symptom)) ),
            Symptoms).

no_symptoms :-
    present_symptoms(_, []).

%   Serious or common symptoms, or a loss of smell or taste.
characteristic_symptoms(Reason) :-
    present_symptoms(serious, Serious),
    present_symptoms(common, Common),
    (   holds(symptom(anosmia))
    ->  Smell = [anosmia]
    ;   Smell = []
    ),
    append([Serious, Common, Smell], Symptoms),
    Symptoms \== [],
    describe_symptoms("characteristic symptoms", Symptoms, Reason).

%   Only less common symptoms, none of them characteristic.
nonspecific_symptoms(Reason) :-
    present_symptoms(less_common, Symptoms),
    Symptoms \== [],
    describe_symptoms("only less common, non-specific symptoms",
                      Symptoms, Reason).

%   At least two common symptoms plus a loss of smell or taste.
typical_clinical_picture(Reason) :-
    present_symptoms(common, Common),
    length(Common, N),
    N >= 2,
    holds(symptom(anosmia)),
    append(Common, [anosmia], Symptoms),
    describe_symptoms("the typical combination of", Symptoms, Reason).

%   At least two common symptoms, or one with a loss of smell or taste.
suggestive_clinical_picture(Reason) :-
    present_symptoms(common, Common),
    length(Common, N),
    (   N >= 2
    ->  Symptoms = Common
    ;   N >= 1,
        holds(symptom(anosmia)),
        append(Common, [anosmia], Symptoms)
    ),
    describe_symptoms("symptoms suggestive of the virus", Symptoms, Reason).

describe_symptoms(Intro, Symptoms, Reason) :-
    maplist(label, Symptoms, Labels),
    atomic_list_concat(Labels, ", ", Text),
    format(string(Reason), "~w: ~w", [Intro, Text]).

                 /*******************************
                 *          EXPOSURE            *
                 *******************************/

%!  recent_exposure(+Phase, -Reason) is semidet.
%
%   The patient had a direct exposure inside the window of Phase:
%   `symptomatic` (exposure can explain current symptoms) or
%   `incubating` (the patient may still develop symptoms).  Unknown
%   timing is assumed to be inside the window as a precaution.

recent_exposure(Phase, Reason) :-
    exposure_sources(Sources),
    trying("when the exposure happened",
           value(days_since_exposure, Days)),
    exposure_window(Phase, Min, Max),
    within_window(Days, Min, Max),
    atomic_list_concat(Sources, "; ", Text),
    (   Days == unknown
    ->  format(string(Reason),
               "~w (timing unknown, assumed recent as a precaution)", [Text])
    ;   format(string(Reason),
               "~w, ~w day(s) ago (within the ~w-~w day window)",
               [Text, Days, Min, Max])
    ).

exposure_window(symptomatic, Min, Max) :-
    incubation_period(Min, Max).
exposure_window(incubating, 0, Max) :-
    incubation_period(_, Max).

within_window(unknown, _, _) :- !.
within_window(Days, Min, Max) :-
    between(Min, Max, Days).

exposure_sources(Sources) :-
    findall(Source, direct_exposure(Source), Sources),
    Sources \== [].

%!  direct_exposure(-Source:string) is nondet.
%
%   The patient was exposed to the virus through Source.

direct_exposure("close contact with an infected person") :-
    holds(contact_infected).
direct_exposure(Source) :-
    holds(contact_presymptomatic),
    presymptomatic_days(Days),
    format(string(Source),
           "close contact with a person who developed symptoms up to ~w \c
            days later (pre-symptomatic transmission)", [Days]).
direct_exposure(Source) :-
    holds(surface_contact),
    trying("whether the virus could have survived on the touched surface",
           surviving_on_surface(Material, Hours, Limit)),
    (   Material == unknown
    ->  Name = "an unknown"
    ;   label(Material, Name)
    ),
    format(string(Source),
           "touched ~w surface ~w h after contamination (the virus survives \c
            there up to ~w h)", [Name, Hours, Limit]).

%   Unknown material or timing is assumed the worst case as a precaution.
surviving_on_surface(Material, Hours, Limit) :-
    value(surface_material, Material),
    survival_limit(Material, Limit),
    value(surface_age_hours, Hours),
    (   Hours == unknown
    ->  true
    ;   Hours =< Limit
    ).

survival_limit(unknown, Limit) :-
    !,
    aggregate_all(max(Hours), survival_hours(_, Hours), Limit).
survival_limit(Material, Limit) :-
    survival_hours(Material, Limit).

                 /*******************************
                 *       SEVERITY AND RISK      *
                 *******************************/

%!  severity(-Severity) is det.

severity(serious) :-
    present_symptoms(serious, [_|_]),
    !.
severity(mild) :-
    \+ no_symptoms,
    !.
severity(none).

%!  risk_factors(-Factors:list(string)) is det.
%
%   Factors raising the risk of severe illness.  Sex only matters
%   within a risk group, so it is asked only then.

risk_factors(Factors) :-
    findall(Factor, risk_factor(Factor), Base),
    (   Base \== [],
        trying("whether male sex further raises the risk",
               value(sex, male))
    ->  append(Base, ["male within a risk group (slightly higher risk)"],
               Factors)
    ;   Factors = Base
    ).

risk_factor(Factor) :-
    value(age, Age),
    integer(Age),
    elderly_age(Limit),
    Age > Limit,
    format(string(Factor), "age above ~w (~w years)", [Limit, Age]).
risk_factor(Factor) :-
    pre_existing_condition(Condition),
    holds(condition(Condition)),
    label(Condition, Label),
    format(string(Factor), "pre-existing condition: ~w", [Label]).

                 /*******************************
                 *            ADVICE            *
                 *******************************/

%!  advice(+Infection, +Severity, +RiskFactors, -Advice) is det.

advice(Infection, Severity, RiskFactors, Advice) :-
    findall(Text,
            advice_rule(Infection, Severity, RiskFactors, Text),
            Advice).

advice_rule(_, serious, _,
            "Seek immediate medical attention: phone the doctor or health \c
             facility for an initial assessment first and do not visit in \c
             person.").
advice_rule(Infection, mild, _,
            "Manage the symptoms at home and self-isolate; mild symptoms \c
             need no doctor assessment.") :-
    suspected(Infection).
advice_rule(Infection, none, _, Text) :-
    suspected(Infection),
    incubation_period(_, Max),
    format(string(Text),
           "Self-isolate and watch for symptoms until ~w days after the \c
            contact; the patient may already be contagious.", [Max]).
advice_rule(Infection, Severity, [_|_],
            "As the patient is at risk of severe illness, monitor closely and \c
             phone the doctor at the first sign of worsening.") :-
    suspected(Infection),
    Severity \== serious.
advice_rule(unlikely, mild, _,
            "Infection is unlikely: treat the symptoms as usual and consult \c
             again if new symptoms or contacts occur.").
advice_rule(unlikely, none, _,
            "No action needed; keep following hygiene measures such as hand \c
             washing and distancing.").

suspected(likely).
suspected(possible).
