:- module(questions,
          [ question/3,                 % ?Attribute, ?Prompt, ?Type
            label/2,                    % ?Term, ?Text
            attribute_label/2           % +Attribute, -Text
          ]).
:- use_module(parameters).

/** <module> Questions and vocabulary of the virus diagnosis expert system

Defines every question the system may ask about a patient and the
human-readable labels of domain terms.  Question types are:

  - `yes_no`
  - number(Min, Max): a whole number in Min..Max
  - choice(Options): one atom from Options
*/

%!  question(?Attribute, ?Prompt:string, ?Type) is nondet.
%
%   Prompt is the question that obtains the value of Attribute.

question(age, "How old is the patient (years)?", number(0, 120)).
question(sex, "What is the patient's sex?", choice([male, female])).
question(symptom(Symptom), Prompt, yes_no) :-
    label(Symptom, Label),
    format(string(Prompt), "Does the patient have ~w?", [Label]).
question(condition(Condition), Prompt, yes_no) :-
    label(Condition, Label),
    format(string(Prompt), "Does the patient suffer from ~w?", [Label]).
question(contact_infected,
         "Was the patient recently in close contact (within sneezing or \c
          coughing distance) with a person infected with the virus?",
         yes_no).
question(contact_presymptomatic, Prompt, yes_no) :-
    presymptomatic_days(Days),
    format(string(Prompt),
           "Was the patient recently in close contact with a person who \c
            developed symptoms of the virus up to ~w days later?", [Days]).
question(surface_contact,
         "Did the patient recently touch a surface (e.g. door handle, \c
          parcel) that an infected person had likely contaminated?",
         yes_no).
question(surface_material, "What was the surface made of?",
         choice([copper, cardboard, plastic, stainless_steel])).
question(surface_age_hours,
         "How many hours after the contamination did the patient touch it?",
         number(0, 720)).
question(days_since_exposure,
         "How many days ago was the most recent of these contacts?",
         number(0, 365)).
question(outbreak_area, Prompt, yes_no) :-
    incubation_period(_, Days),
    format(string(Prompt),
           "Has the patient stayed in Virusville, the outbreak area, in the \c
            last ~w days?", [Days]).

%!  attribute_label(+Attribute, -Text:string) is det.
%
%   Text briefly names the question Attribute.

attribute_label(symptom(Symptom), Text) :-
    !,
    label(Symptom, Text).
attribute_label(condition(Condition), Text) :-
    !,
    label(Condition, Text).
attribute_label(Attribute, Text) :-
    attribute_name(Attribute, Text).

attribute_name(age, "age").
attribute_name(sex, "sex").
attribute_name(contact_infected, "contact with an infected person").
attribute_name(contact_presymptomatic, "contact with a pre-symptomatic person").
attribute_name(surface_contact, "contact with a contaminated surface").
attribute_name(surface_material, "surface material").
attribute_name(surface_age_hours, "hours from contamination to touch").
attribute_name(days_since_exposure, "days since the contact").
attribute_name(outbreak_area, "stay in the outbreak area").

%!  label(?Term, ?Text:string) is nondet.
%
%   Text describes the symptom, condition or material Term.

label(fever, "a fever").
label(dry_cough, "a persistent dry cough").
label(tiredness, "tiredness").
label(aches_pains, "aches and pains").
label(sore_throat, "a sore throat").
label(diarrhoea, "diarrhoea").
label(conjunctivitis, "conjunctivitis").
label(headache, "a headache").
label(anosmia, "a loss of smell or taste (anosmia/hyposmia)").
label(running_nose, "a running nose").
label(breathing_difficulty, "difficulty breathing or shortness of breath").
label(chest_pain, "chest pain or a feeling of chest pressure").
label(loss_of_speech_or_movement, "a loss of speech or movement").
label(hypertension, "hypertension").
label(diabetes, "diabetes").
label(cardiovascular_disease, "a cardiovascular disease").
label(chronic_respiratory_disease, "a chronic respiratory disease").
label(cancer, "cancer").
label(copper, "copper").
label(cardboard, "cardboard").
label(plastic, "plastic").
label(stainless_steel, "stainless steel").
