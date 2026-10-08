:- module(parameters,
          [ incubation_period/2,        % ?MinDays, ?MaxDays
            presymptomatic_days/1,      % ?Days
            elderly_age/1,              % ?Age
            survival_hours/2            % ?Material, ?Hours
          ]).

/** <module> Numeric parameters of the Virusland virus

Single source of the quantitative domain knowledge, shared by the
diagnosis rules and the question texts.
*/

%!  incubation_period(?MinDays, ?MaxDays) is det.
%
%   Days between exposure and the onset of symptoms.

incubation_period(1, 14).

%!  presymptomatic_days(?Days) is det.
%
%   An infected person may be contagious Days before the first symptoms.

presymptomatic_days(2).

%!  elderly_age(?Age) is det.
%
%   Patients older than Age are at higher risk.

elderly_age(70).

%!  survival_hours(?Material, ?Hours) is nondet.
%
%   The virus survives up to Hours on a surface made of Material.

survival_hours(copper, 4).
survival_hours(cardboard, 24).
survival_hours(plastic, 72).
survival_hours(stainless_steel, 72).
