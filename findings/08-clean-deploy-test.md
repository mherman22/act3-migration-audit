# Clean-deploy verification of PR #3

Server built and deployed from the PR head (`657600d0`) after `docker compose down -v`, so every
concept, form and metadata row below was loaded from scratch rather than inherited from an
earlier database.

## Load health

| check | result |
|---|---|
| RHD forms loaded | 18 / 18 |
| Duplicate concept names | 0 |
| Concepts | 4937 (4900 not retired) |
| Locations tagged `Login Location` | 8 |
| Locations tagged `Queue Location` | 8 |
| Form schema errors (`json.openmrs.org/form.schema.json`) | 0 |

### Rows that did not load

`rhd_conceptsets.csv`: 5 of 30 rows skipped. All five name members that do not exist in the
database, so Initializer refuses the parent row:

| set | member it could not resolve |
|---|---|
| `set_vital_signs_rhd_section` | `Height` |
| `set_echocardiogram_rhd_section` | `Summary of Last Echo (DD-Month-YYYY)` |
| `set_electrocardiogram_rhd_section` | `Electrocardigram` (spelling as written in the CSV) |
| `set_plan_and_follow_up_rhd_section` | `Next Consultation` |
| `set_anticoagulation_monitoring_consultation_visit_rhd_section` | `Date (Consultation Visit)`, `5085AAAA…` |

These are pre-existing on `main`. The only row this PR touches in that file is
`set_patient_information_rhd_section` (a label spelling fix), which loads. The sets are ConvSet
groupings used for reporting; no form references them, and all 18 forms render without them.

### Demo patients

The reference demo data generator aborts on this distro with
`APIException: Could not find identifier type OpenMRS ID`, so a from-scratch database contains
zero patients. The RHD `patientidentifiertypes` bind mount replaces the package folder rather than
nesting under it, so the package's own identifier types never load. Restoring them needs three
mounts, not one, and eight other mounts hide package content the same way; see
[09-shadowing-config-mounts.md](09-shadowing-config-mounts.md). Pre-existing on `main` and outside
this PR; three patients (living male, living female, deceased) and an open RHD Clinic Visit each
were created over REST to run the tests below.

## Acceptance suites

**New fields from ACT 2.0 parity — 18 / 18**

BPG Facility and Injection Tolerance present; anaphylaxis detail hidden until either trigger is
set, then revealed. Pregnancy LMP, Gravidity, Parity present; cesarean reason gated. Interventions
Primary Surgeon, Blood Group, RACHS Score and Follow-Up Required present; surgical block gated on
Procedure Type. Patient Information Date Diagnosed and Primary Diagnosis Details present; School
Name gated. Oral Adherence explanation gated.

**Conditional selects in the repeat group — per-row scoping correct**

| row | Procedure Type | recommendations offered |
|---|---|---|
| 1 | Surgery | 23 surgical |
| 2 | Catheterization | 19 catheter |

Row 1 still offers its 23 after row 2 is added and set differently. Under the previous
answer-level `hide`, row 2 showed row 1's answers.

**All 18 forms render — 18 / 18**

Every form opened on the live server and screenshotted. `RHD Anticoagulation Monitoring` reports
zero `<label>` elements because its single question is a date picker, which O3 renders without
one; the screenshot confirms it draws correctly.

## Screenshots

All 18 taken on this deploy, in `screenshots/deploy-test/`:

| form | file |
|---|---|
| Patient Information | `patient_information.png` |
| Consultation Visit | `consultation.png` |
| Consultation Update | `consultation_update.png` |
| BPG Delivery | `bpg.png` |
| Interventions and Outcomes | `interventions.png` |
| Interventional Recommendations | `recommendations.png` |
| Cardiac Intervention | `cardiac_intervention.png` |
| Hospital Admission | `hospital.png` |
| Echocardiogram | `echocardiogram.png` |
| Electrocardiogram | `electrocardiogram.png` |
| Anticoagulation | `anticoagulation.png` |
| Anticoagulation Monitoring | `anticoagulation_monitoring.png` |
| INR Monitoring | `inr_monitoring.png` |
| Oral Adherence | `oral_adherence.png` |
| Allergies | `allergies.png` |
| Chronic Health Conditions | `chronic_conditions.png` |
| Consent | `consent.png` |
| Pregnancy | `pregnancy.png` |

## Known and unchanged

- The pregnancy form is offered for male patients. ACT 2.0 does the same and O3 has no
  gender filter on form availability.
- The five ConvSet rows above.
- Demo patient generation, as described.
