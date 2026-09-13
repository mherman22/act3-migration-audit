# Field parity re-verification, ACT 2.0 against ACT 3.0

A second, source-level pass over form parity, run after the fixes in
`DIGI-UW/openmrs-distro-referenceapplication` PR #3 landed on its branch.

| | |
|---|---|
| ACT 2.0 | `is4r-rhd-ui`, all 12 form components read directly from source |
| ACT 3.0 | the 18 RHD form JSON schemas at PR #3 head `f008b869` |
| Captured | 14 September 2026 |
| Fields compared | 148 distinct in ACT 2.0, 185 in ACT 3.0 |

This supersedes the field counts in [01-form-parity.md](01-form-parity.md), which matched
field names **globally** across all 18 schemas. That absorbed real gaps into similarly named
fields in unrelated forms and undercounted. Matching here is constrained to the ACT 3.0
form(s) that should carry each ACT 2.0 form's fields, then every claimed gap was checked by
hand against the actual field list.

## Summary

**About 37 ACT 2.0 fields have no ACT 3.0 counterpart**, concentrated in four forms. The
conditional-display and concept work in PR #3 is complete and unrelated to this; parity is
form *content*, and it is the larger remaining body of work.

| ACT 3.0 form | Missing | Character of the gap |
|---|---|---|
| `rhd_interventions` | **19** | the entire surgical and post-procedure record |
| `rhd_patient_information` | 6 | diagnosis detail and location of care |
| `rhd_pregnancy` | 6 | obstetric history and free-text detail |
| `rhd_bpg` | 4 | second reaction field, plus answer-list drift |
| `rhd_consultation` | 1 | contraindications |
| `rhd_adherence` | 1 | explanation below 80% |

## Interventions and Outcomes, 19 fields

The largest gap. ACT 2.0's `InterventionsAndOutcomesForms.tsx` carries a full operative and
30-day outcome record; ACT 3.0 has the procedure-type branching but little of the content.

| Block | Missing fields |
|---|---|
| Surgical detail | Primary Surgeon/Cardiologist, With Visiting Team, Blood Group, RACHS Score, Pre-Surgical Diagnosis, Post-Surgical Diagnosis, Key Findings/Surgical Notes, Cardiopulmonary Bypass Time, Reoperation Required, Describe Reason for Reoperation |
| Post-procedure | Degree of MR, Pericardial Effusion |
| Death | Date of Death, Describe Events Around Patient's Death |
| 30-day rehospitalisation | Rehospitalized past 30 days, Procedure-related?, Describe Rehospitalization |
| Follow-up | Follow-Up Required, Follow-Up Arranged |

RACHS Score is gated in ACT 2.0 on `patient.category_at_diagnosis === "Congenital Heart
Disease"`, so it carries the same patient-context problem recorded in PR #3.

## Patient Information, 6 fields

Primary Diagnosis Details, Date Diagnosed, School Name, District/Area of Residence,
Cardiac Clinic, Primary Care Clinic.

The last two are references to a treating site, so they may belong as location or person
attributes rather than observations.

## Pregnancy, 6 fields

Date of Last Menstrual Period, Gravidity, Parity, Reason for cesarean section,
Describe Postpartum Complications Further, Describe Neonatal Outcomes Further.

## BPG Delivery, 4 fields plus answer drift

Missing: **Injection Tolerance**, Facility, Describe anaphylaxis events, Approximate time
between injection and symptoms.

Injection Tolerance matters beyond its own value. ACT 2.0 reveals the six anaphylaxis
fields when *either* Injection Tolerance **or** Adverse Reaction contains `Anaphylaxis`, and
`Anaphylaxis` is an option on Injection Tolerance, not on Adverse Reaction. ACT 3.0 moved
`Anaphylaxis` onto Adverse Reaction and dropped the tolerance field, so one of the two
documented triggers cannot be recorded at all.

The Adverse Reaction answer list has also drifted from ACT 2.0's:

| ACT 2.0 | ACT 3.0 |
|---|---|
| Pain **>48 hours post-injection** | Pain |
| Limp **>48 hours post-injection** | Limp |
| Leg **swelling** >48 hours post-injection | Leg **numbness** |
| Rash **thought to be from injection** | Rash |
| Injection site infection | Injection site infection |
| None | None |
| | Anaphylaxis, Local redness, Other non-coded |

`Leg numbness` is not `Leg swelling`; it is an option from ACT 2.0's *Injection Tolerance*
list, which suggests a row taken from the wrong source. Dropping the `>48 hours` qualifier
also changes the question, since the threshold is what separates a sore leg on the day from
a reaction worth recording.

Two further differences, neither a missing field:

- ACT 2.0 has `required={false}` on Adverse Reaction and all six anaphylaxis fields.
  ACT 3.0 marks all seven `required: true`.
- `None` sits in the same multi-select as real reactions, so `None + Rash` is enterable.
  ACT 2.0 shares this flaw, so fixing it would be an improvement rather than parity.

## Consultation and Oral Adherence, 1 each

Contraindications for placing a mechanical valve; Explanation if Adherence is Below 80%.

## Correctly absent, not counted as gaps

These appear as ACT 2.0 fields but should not be form questions in ACT 3.0:

| ACT 2.0 field | Where it belongs in ACT 3.0 |
|---|---|
| First Name, Family Name, Sex, Alternate ID | OpenMRS patient registration |
| Status, Reason Inactive, Date of Status Change | the RHD Registry Status program workflow, which is better modelling than ACT 2.0's |
| Height, Weight, Oxygen Saturation, Systolic/Diastolic BP | present, in `rhd_consultation` rather than `rhd_interventions` |

## Residual risk in this count

Renames judged as matches rather than gaps: `neonatal_weight_kg` for Birth Weight,
`location_of_delivery` for Delivery Location, `details_hospital_admission` for Details. If
any is semantically different the count rises. Every other claimed gap was confirmed by
reading both field lists.

Each missing field needs a concept. Check CIEL first for each, as was done for `Outcome`
(no CIEL discharge-disposition question exists, so it stayed local) and for the `Deceased`
answer (CIEL 159, reused).
