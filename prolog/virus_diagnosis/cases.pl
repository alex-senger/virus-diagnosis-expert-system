:- module(cases,
          [ case/3                      % ?Id, ?Description, ?Facts
          ]).

/** <module> Sample patients for demonstrating the expert system

Each case lists the known facts as Attribute=Value pairs.  Unlisted
yes/no questions count as `no`, other questions as `unknown`.
*/

%!  case(?Id, ?Description:string, ?Facts:list) is nondet.

case(elderly_serious,
     "78-year-old man with hypertension and breathing difficulty, 5 days \c
      after contact with an infected person",
     [ age=78, sex=male, condition(hypertension)=yes,
       contact_infected=yes, days_since_exposure=5,
       symptom(fever)=yes, symptom(dry_cough)=yes,
       symptom(breathing_difficulty)=yes
     ]).
case(young_mild,
     "25-year-old woman with fever, tiredness and headache, 4 days after \c
      meeting a friend who fell ill 2 days later",
     [ age=25, sex=female,
       contact_presymptomatic=yes, days_since_exposure=4,
       symptom(fever)=yes, symptom(tiredness)=yes, symptom(headache)=yes
     ]).
case(exposed_no_symptoms,
     "40-year-old woman without symptoms who touched a contaminated \c
      plastic parcel 3 days ago",
     [ age=40, sex=female,
       surface_contact=yes, surface_material=plastic, surface_age_hours=24,
       days_since_exposure=3
     ]).
case(copper_surface,
     "33-year-old man without symptoms who touched a copper door handle \c
      10 hours after it was contaminated",
     [ age=33, sex=male,
       surface_contact=yes, surface_material=copper, surface_age_hours=10,
       days_since_exposure=2
     ]).
case(old_exposure,
     "35-year-old man without symptoms whose contact with an infected \c
      person was 20 days ago",
     [ age=35, sex=male,
       contact_infected=yes, days_since_exposure=20
     ]).
case(outbreak_area_diabetic,
     "55-year-old woman with diabetes and a fever who stayed in Virusville",
     [ age=55, sex=female, condition(diabetes)=yes,
       outbreak_area=yes, symptom(fever)=yes
     ]).
case(typical_no_contact,
     "45-year-old man with fever, dry cough and loss of smell, no known \c
      contact",
     [ age=45, sex=male,
       symptom(fever)=yes, symptom(dry_cough)=yes, symptom(anosmia)=yes
     ]).
case(common_cold,
     "30-year-old man with a running nose and sore throat, no contact",
     [ age=30, sex=male,
       symptom(running_nose)=yes, symptom(sore_throat)=yes
     ]).
