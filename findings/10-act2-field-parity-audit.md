# ACT 2.0 to ACT 3.0 field parity: full audit

Method: ACT 2.0's field inventory is taken from `src/lib/formTypes.ts` in `is4r-rhd-ui-develop`,
which carries both the persisted TypeScript types and the `formsInfo` label map. That is the data
model, not a reading of the screens. Conditions are taken from the `<Collapse in={...}>` guards in
`src/components/Forms/*.tsx`. ACT 3.0 is read from the 18 form schemas in the distro.

**204 labelled ACT 2.0 fields across 11 forms. 241 questions across 18 ACT 3.0 forms.**

No ACT 2.0 form is missing. All 11 have a home:

| ACT 2.0 form | ACT 3.0 |
|---|---|
| Patient Information | RHD Patient Information (+ registration, + RHD Registry program) |
| Consultation Visit | RHD Consultation Visit (+ Allergies, Chronic Health Conditions, Interventional Recommendations, Cardiac Intervention, Consultation Update) |
| Procedures and Outcomes | RHD Interventions and Outcomes |
| BPG Delivery | RHD BPG Delivery |
| Pregnancy | RHD Pregnancy |
| Echocardiogram | RHD Echocardiogram |
| Electrocardiogram | RHD Electrocardiogram |
| Hospital Admission | RHD Hospital Admission |
| Oral Adherence | RHD Oral Adherence |
| INR Monitoring | RHD INR Monitoring (+ Anticoagulation, Anticoagulation Monitoring) |
| Research Participation | RHD Consent |

---

## A. Fields present in ACT 2.0 with nowhere to land in ACT 3.0

Each confirmed by searching the ACT 3.0 schema for the field and every plausible renaming.

### A second pass: is the ACT 2.0 field actually on screen?

A field can be declared in `formTypes.ts` and never rendered. Checking each candidate for a
`name={"..."}` binding in its component changes several verdicts, so the gaps below are only the
fields ACT 2.0 genuinely collects.

**Declared but never rendered in ACT 2.0, so not gaps at all:** `describe_perfusion_issues`,
`describe_site_infection`, `describe_bacterial_sepsis` (the three Yes/No complications have no
follow-up text on screen in ACT 2.0 either) and `bpg_entry_method`.

**Rendered somewhere other than the form:** `confirmatory_diagnosis_date`, `rhd_clinic_id` and
`community_clinic_id` are bound in `CreateOrUpdatePatient.tsx`, the registration screen, not on
Patient Information. Their ACT 3.0 home is registration and the program, not this form.

**Displayed read-only:** `secondary_diagnosis_date`, `secondary_category_at_diagnosis` and
`secondary_diagnosis_details` appear in a summary block on the Patient Information screen and are
submitted with the form, but have no input binding; `secondary_diagnosis_details` is commented out
at line 128. They are fed by the diagnosis-history mechanism. ACT 3.0 has no equivalent, but the
missing piece is patient-level diagnosis history, not three form fields, so adding three questions
would be the wrong answer.

**`bsa`** is displayed in ACT 2.0 and computed by `calculateBSA(height, weight)`; it is not stored,
and it returns as soon as height and weight do.

### Interventions and Outcomes (5 real)

| ACT 2.0 field | Note |
|---|---|
| `height`, `weight`, `oxygen_saturation` | Recorded per procedure, always shown, zero matches in `rhd_interventions.json`. |
| `mitral_valve_assessment` | Sits beside `mitral_valve_area` in the catheterization block. A two-option select. |
| `rehospitalization_date` | ACT 3.0 has the Yes/No, the procedure-related question and the free text, but no date. |

ACT 2.0 also has **two** date-of-death fields, `date_of_death` in outcomes and
`date_of_death_followup` in the 30-day follow-up. ACT 3.0 has one, which is defensible.

### Pregnancy (4 real)

`date_of_service`, `date_of_delivery` (ACT 3.0 had only Estimated Due Date), and both
"describe cause of death further" fields.

### Patient Information

`cause_of_death` is the one substantive gap: ACT 3.0 records Date of Death and "Details of events
leading up to death" but not cause. It is an OpenMRS person property set at registration, so it is
capturable, just not beside the rest of the death block. Absent on `main` too.

Deliberate drops, unchanged: the five `textit_*` fields (SMS integration) and the patient-level
rollups (`secondary_prophylaxis*`, `adherence`, `most_recent_rhd_consultation`,
`next_rhd_consulation`, `inr_target`, `status`, `date_of_status_change`), which ACT 3.0 derives
from encounters and the RHD Registry program. Identity fields are OpenMRS core.

---

## B. Conditions ACT 2.0 applies that ACT 3.0 does not

These change what a user sees, so they matter as much as missing fields.

| # | ACT 2.0 guard | ACT 3.0 |
|---|---|---|
| 1 | **Post-procedure outcome and 30-day follow-up** hang off `procedural_outcome`, which applies to any procedure | Both whole sections gated `procedure_type == Surgery`. A **catheterization patient cannot record outcome, ICU stay, ventilation time, perfusion issues, site infection, sepsis, complications, follow-up contact or whether they are alive.** |
| 2 | **Catheterization block** gated `procedureType == "Catheterization"` (line 711) | Indication, pre/post-catheterization diagnosis, brief summary and anaesthesia are shown **always**, including for a surgery-only procedure. The mirror image of #1. |
| 3 | `date_of_death` and `describe_events_around_patient_death` gated `procedural_outcome == "In-hospital death"` (line 998) | Shown always. |
| 4 | `rachs_score` gated `patient.category_at_diagnosis === "Congenital Heart Disease"` (line 547) | Shown always. Category at Diagnosis lives on RHD Patient Information, a different encounter type, so `HD.getObject('prevEnc')` cannot reach it. Same limitation already documented for the SAP duration fields. |
| 5 | Pregnancy: describe-postpartum gated on postpartum complications being set and not "None"; `maternal_cause_of_death` gated on complications including "Death"; describe-neonatal gated on `neonatalOutcomes != "Alive out of hospital"` | All three shown always. |

Conditions that **do** match, verified: the BPG anaphylaxis block on either Adverse Reaction or
Injection Tolerance (ACT 2.0 line 343, an explicit `||`); echocardiogram mitral valve repair on
`mitral_regurgitation != None` and the BAV/Wilkins trio on `mitral_stenosis != None`; Hospital
Admission discharge date on outcome; School Name on Case Detected By; the rehospitalization,
bacterial-sepsis-to-organism and patient-alive follow-ups.

Accepted deviations already on the record: `relocation_area` (ACT 2.0 gates it on Reason Inactive
= Physical relocation, which is a program workflow value the expression scope cannot read) and the
SAP block (gated on Category at Diagnosis, cross-encounter).

---

## C. Spelling defects carried in ACT 3.0 concept names

These are in the concept fully-specified names and the reference codes, not only the labels, so
correcting them renames a concept.

| Where | Reads | Should read |
|---|---|---|
| `rhd_adherence.json` / `ACT-RHD:q_adherence_estimage` | Adherence **Estimage** | Estimate |
| `rhd_pregnancy.json` / `ACT-RHD:q_neontal_cause_of_death` | **Neontal** Cause of Death | Neonatal |
| `rhd_interventions.json` / `ACT-RHD:q_other_major_complications_assiciated_with_surgery` | **Assiciated** with Surgery | Associated |
| `rhd_consent.json` / `ACT-RHD:q_reason_for_completiong` | Reason for **completiong** | completion |
| `rhd_patient_information.json` | id `tertiary_phone_ownder` | owner (the label was corrected in PR #3; the id was not) |

---

## D. Structural observations

**`RHD Anticoagulation Monitoring` holds one question, a date.** It records nothing. ACT 2.0 has
no anticoagulation form; anticoagulation lives in INR Monitoring. Either this form should carry the
monitoring values or it should not exist.

**ACT 3.0 is not a straight copy; it was expanded.** Additions with no ACT 2.0 origin, which is
fine but should be a conscious record rather than a surprise: the whole consent/assent block on RHD
Consent (7 questions, where ACT 2.0's research form had opt-in and project list); Weeks in
Reporting Period, Dosing and Tablets Given on Oral Adherence; the CIEL anaphylaxis criteria set on
BPG (neurological, abdominal/pelvic, risk factors); start/stop/reason-stopped dates on the
consultation repeat groups; Indication for Surgery, Reason for Surgery, Open Chest After Surgery,
Required Additional Surgery for Bleeding and "Is the patient OK?" on Interventions; Pregnancy
Number.

**Label drift, same meaning, no action needed:** `cardiovascular_compromise` to Cardiovascular
Signs or Symptoms; `severe_gi_symptoms` to Abdominal/Pelvic Signs or Symptoms; `birth_weight` to
Neonatal weight (kg); `maternal_complications_postpartum` to Maternal Complications Within 30 Days
After Pregnancy; `gestational_age` to Estimated Gestational Age at Delivery; `anesthesia_type` to
Anaesthesia; `medications` to Cardiac Medication; `site_infection` to Surgical Site Infection.

---

## What was changed

Applied to the PR. Nothing here needs a new encounter type or touches stored data shape.

**`rhd_interventions.json`**

- Post-procedure outcome and 30-day follow-up no longer gate on Surgery: `surgery_outcome`
  (relabelled **Procedural Outcome**), `icu_stay`, `ventilation_time`, `perfusion_issues`,
  `surgical_site_infection`, `bacterial_sepsis`, the complications question,
  `date_of_patient_follow_up_contact` and `is_patient_alive` now apply to any procedure, as ACT 2.0
  does. Nine hides removed.
- The catheterization detail is gated on Catheterization: the type group, indication group,
  pre/post-catheterization diagnosis, brief summary and anaesthesia. `surgery_type_s_group` gets the
  matching Surgery gate for symmetry. Seven hides added.
- `date_of_death` and `describe_events_around_patient_death` follow the procedural outcome, shown
  only when it is Death, matching ACT 2.0's `In-hospital death` guard.
- Added `Height (cm)`, `Weight (kg)` and `Oxygen Saturation (%)` (CIEL 5090, 5089, 5092, the same
  concepts the consultation form uses), `Date of Rehospitalization` gated like the rest of that
  block, and `Mitral Valve Assessment` gated on the BAV catheterization type as ACT 2.0 gates it.

**`rhd_pregnancy.json`**

- Three ACT 2.0 guards restored: `describe_postpartum_complications` and `maternal_cause_of_death`
  appear once postpartum complications are recorded; `describe_neonatal_outcomes` appears unless the
  neonatal outcome is "Alive out of hospital".
- Added `Date (Pregnancy)`, `Date of Delivery`, and the two "describe cause of death further"
  fields, each carrying the same gate as the cause-of-death question it follows.
- `neontal_cause_of_death` keeps its existing guard, which is stricter than ACT 2.0's and correct:
  live birth **and** neonatal outcome Deceased.

**Spelling.** The four concept fully-specified names and the five question ids are corrected in the
form schemas, the question CSVs and the conceptset member lists together. The `ACT-RHD:` mapping
codes keep their original spelling on purpose: they are identifiers, and renaming one would break
anything referencing the concept by code.

**Seven new concepts**, uuid5-derived from `uuid5(NAMESPACE_URL, "https://actregistry.org/openmrs/act3")`
over `ACT-RHD:<code>`: Mitral Valve Assessment and its "Sufficient" answer (reusing the existing
`Insufficient`), Date of Rehospitalization, Date (Pregnancy), Date of Delivery, and the two
describe-cause-of-death fields.

**Not changed, and why:** the secondary-diagnosis history, `cause_of_death`, the clinic assignment
and `confirmatory_diagnosis_date` all need a decision about where they live in O3 rather than a
form field; the RACHS guard needs a value from another encounter type, which the expression scope
cannot reach.

---

## Still open

1. **Secondary diagnosis history.** ACT 2.0 keeps a diagnosis history per patient and shows a
   secondary diagnosis summary. O3 has no equivalent here. This is a modelling decision, not a
   field.
2. **`cause_of_death`** on the patient, beside Date of Death.
3. **Cardiac Clinic and Primary Care Clinic** assignment at the patient level.
4. **RACHS score** should only show for congenital heart disease; the value is on another
   encounter type.
5. **`RHD Anticoagulation Monitoring`** still holds one date and records nothing.
6. The `ACT-RHD:` mapping codes still carry four original misspellings, by choice.

## Priority

1. **B1 and B2** are the most serious: between them, half the Interventions form is unreachable for
   a catheterization and the catheterization half is always on. This is a behaviour defect, not a
   missing field.
2. **A, Interventions**: height, weight, oxygen saturation and the three describe fields.
3. **A, Patient Information**: the secondary-diagnosis trio and Date of Positive Screen.
4. **B5 and B3**: pregnancy and death gating.
5. **C**: the four concept-name typos, which need a rename decision.
