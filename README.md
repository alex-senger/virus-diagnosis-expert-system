# Virus Diagnosis Expert System

A rule-based expert system in SWI-Prolog that diagnoses the possible
presence or absence of the Virusland virus infection. It takes a patient's
symptoms, bio data and recent history of events, and works out:

- the **likelihood of infection** (`likely`, `possible` or `unlikely`),
  with the rule applied and the facts behind it,
- the **symptom severity** (`serious`, `mild`, `none`, or `undetermined`
  when a serious symptom is unknown),
- the **risk factors** for severe illness (age above 70, pre-existing
  conditions, and male sex within a risk group),
- **advice**: call a doctor immediately, manage symptoms at home,
  self-isolate and monitor, or no action.

The conclusions come from Prolog's built-in backward chaining. Questions
are asked only when a rule needs the answer. For example, the system asks
about surface material only after a surface contact, and asks the
patient's sex only when the patient is in a risk group. Each answer is
asked once and remembered. Answers given as `unknown` are listed under
"Could not be established".

## Requirements

[SWI-Prolog](https://www.swi-prolog.org) 9 or later.

## Usage

Interactive consultation:

```bash
swipl run.pl
```

Answer with `yes`/`no`, a number, or an option name or number. You can
also type:

- `unknown` if the answer is not known,
- `why` to see the line of reasoning behind the current question,
- `quit` to stop.

Diagnose the sample patients:

```bash
swipl run.pl demo
```

```bash
swipl run.pl demo elderly_serious
```

From the Prolog toplevel:

```prolog
?- [prolog/virus_diagnosis].
?- start.
?- demo(young_mild).
?- demo_all.
```

### Example

```text
Was the patient recently in close contact (within sneezing or coughing distance) with a person infected with the virus? [yes/no/unknown/why]
> y
...
How many days ago did the patient's first symptoms start? [0-365/unknown/why]
> why
  I am trying to establish whether the incubation period fits the symptoms,
    which is needed to establish whether the patient had a recent exposure to the virus,
    which is needed to establish the likelihood of a virus infection.
...
--- Diagnosis ---
Virus infection: LIKELY
Rule applied: R1 (recent exposure explaining characteristic symptoms)
Because:
  - close contact with an infected person, 6 day(s) ago; symptoms started 3 day(s) later, within the 1-14 day incubation period
  - characteristic symptoms: a fever, a persistent dry cough
Symptom severity: mild
Risk factors:
  - age above 70 (82 years)
  - pre-existing condition: hypertension
  - male within a risk group (slightly higher risk)
Advice:
  - Manage the symptoms at home and self-isolate; mild symptoms need no doctor assessment.
  - As the patient is at risk of severe illness, monitor closely and phone the doctor at the first sign of worsening.
```

## Tests

```bash
swipl -g run_tests -t halt test/test_virus_diagnosis.pl
```

## Structure

| File | Purpose |
| --- | --- |
| `prolog/virus_diagnosis.pl` | Entry points (`start/0`, `demo/1`, `demo_all/0`) and output |
| `prolog/virus_diagnosis/knowledge_base.pl` | Domain facts and diagnosis rules |
| `prolog/virus_diagnosis/engine.pl` | Fact store, question dialogue, `why` explanations |
| `prolog/virus_diagnosis/parameters.pl` | Incubation period, survival times and other numeric parameters |
| `prolog/virus_diagnosis/questions.pl` | Questions and labels of domain terms |
| `prolog/virus_diagnosis/cases.pl` | Sample patients |
| `test/test_virus_diagnosis.pl` | plunit tests |
| `run.pl` | Command-line launcher |

## Diagnosis rules

The infection rules are tried in order, and the first rule that can be
proved gives the result:

| Rule | Conditions | Result |
| --- | --- | --- |
| R1 | Symptoms started 1–14 days after a direct exposure, and they are characteristic | likely |
| R2 | At least two common symptoms and loss of smell or taste | likely |
| R3 | Symptoms started 1–14 days after a direct exposure, but only less common ones | possible |
| R4 | Direct exposure 0–14 days ago that does not explain any symptoms (may still be incubating) | possible |
| R5 | Stay in the outbreak area and characteristic symptoms | possible |
| R6 | Two common symptoms, or one common symptom and loss of smell, without a fitting exposure | possible |
| R7 | None of the above | unlikely |

What the rules count as each kind of exposure or symptom:

- **Direct exposure** means one of:
  - close contact with an infected person;
  - close contact with someone who developed symptoms up to 2 days
    later, since the virus can spread before symptoms appear;
  - touching a contaminated surface while the virus could still survive
    on it: up to 4 hours on copper, 24 hours on cardboard, and 72 hours
    on plastic or stainless steel.
- **Characteristic symptoms** are any common or serious symptom, or a
  loss of smell or taste.
- **Unknown answers about exposure timing or surface material** are
  treated as the worst case, as a precaution. If the symptom onset is
  unknown, the exposure must be 1–14 days ago.
- **An unknown serious symptom** makes the severity `undetermined` and
  leads to the advice to phone a doctor.

## Disclaimer

This program is a demonstration for an assignment, not a medical diagnostic tool.
