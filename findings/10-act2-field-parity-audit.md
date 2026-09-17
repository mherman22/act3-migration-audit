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

### Interventions and Outcomes (9)

| ACT 2.0 field | Note |
|---|---|
| `height`, `weight`, `oxygen_saturation` | Recorded per procedure in ACT 2.0, always shown. Zero matches in `rhd_interventions.json`. The consultation form's height/weight are a different encounter. |
| `bsa` | Displayed in ACT 2.0, computed by `calculateBSA(height, weight)` and never stored. Only reproducible if height and weight come back. |
| `mitral_valve_assessment` | Sits in the catheterization block beside `mitral_valve_area`, which ACT 3.0 does have. |
| `describe_perfusion_issues` | ACT 3.0 has the Yes/No `perfusion_issues` with no follow-up text. |
| `describe_site_infection` | ACT 3.0 has `surgical_site_infection` Yes/No with no follow-up text. |
| `describe_bacterial_sepsis` | ACT 3.0 has `bacterial_sepsis` Yes/No, then jumps to `organism_identified_if_known`. |
| `rehospitalization_date` | ACT 3.0 has the Yes/No, the procedure-related question and the free text, but no date. |

Also: ACT 2.0 has **two** date-of-death fields, `date_of_death` in outcomes and
`date_of_death_followup` in the 30-day follow-up. ACT 3.0 has one.

### Pregnancy (4)

| ACT 2.0 field | Note |
|---|---|
| `date_of_service` | Every other ACT 2.0 form's service date has an ACT 3.0 counterpart; this one does not. |
| `date_of_delivery` | ACT 3.0 has Estimated Due Date but no actual delivery date. |
| `maternal_cause_of_death_description` | ACT 3.0 has `maternal_cause_of_death` with no "describe further". |
| `neonatal_cause_of_death_description` | Same shape, same omission. |

### Patient Information (7 substantive)

| ACT 2.0 field | Note |
|---|---|
| `confirmatory_diagnosis_date` (Date of Positive Screen) | The flag itself survives as the `Screen + pending confirmatory echo` answer under Category at Diagnosis. The date has no home. |
| `secondary_diagnosis_date` | The whole secondary-diagnosis trio is absent. A patient with two diagnoses can record only the first. |
| `secondary_category_at_diagnosis` | as above |
| `secondary_diagnosis_details` | as above |
| `cause_of_death` | ACT 3.0 records Date of Death and "Details of events leading up to death". Cause is an OpenMRS person property set at registration, so it is capturable, but not on this form and not in the same place as the rest of the death block. Absent on `main` too; not introduced by PR #3. |
| `rhd_clinic_id` (Cardiac Clinic), `community_clinic_id` (Primary Care Clinic) | The patient's assigned clinics. ACT 3.0 records the visit location per consultation, which is not the same thing. |
| `bpg_entry_method` | No equivalent anywhere in the distro. |

Deliberate drops, worth confirming rather than assuming: `textit_phone_number`, `textit_id`,
`textit_opt_in`, `textit_language`, `textit_facility` are the SMS integration. Rollups
(`secondary_prophylaxis*`, `adherence`, `most_recent_rhd_consultation`, `next_rhd_consulation`,
`inr_target`, `status`, `date_of_status_change`) are derived from encounters or the program
workflow. Identity fields (`patient_id`, names, `birthdate`, `sex`, `external_patient_id`,
`alternate_id`, `created_at`, `updated_at`) are OpenMRS core.

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

## Priority

1. **B1 and B2** are the most serious: between them, half the Interventions form is unreachable for
   a catheterization and the catheterization half is always on. This is a behaviour defect, not a
   missing field.
2. **A, Interventions**: height, weight, oxygen saturation and the three describe fields.
3. **A, Patient Information**: the secondary-diagnosis trio and Date of Positive Screen.
4. **B5 and B3**: pregnancy and death gating.
5. **C**: the four concept-name typos, which need a rename decision.
