# What ACT 2.0 reports, and what Common Reports covers

Read from `is4r-rhd-ui-develop` (the React app) and `is4r-rhd-cdk-develop`
(`resources/app/query_handlers/dashboard_query.py`, `resources/app/models.py`), which hold the
indicator definitions.

**ACT 2.0 reports in three separate ways. Common Reports covers one of them.**

---

## 1. Ad-hoc CSV download

`src/routes/download.tsx`. The user picks forms from `formsInfo`, ticks individual fields, applies
clinic/status/date filters, and the server returns paginated JSON (25 per page) that the browser
joins into a CSV. There are no canned definitions; the single preset that existed,
*"Screen+ Patients without Diagnosis"*, is commented out.

**Common Reports replaces this, and improves on it.** Its CSV extracts for encounters,
observations, patients, programs, visits, conditions, diagnoses, orders and appointments are
concept-level and evaluated server-side, where ACT 2.0 assembled CSV in the browser.

## 2. The dashboard: cascades and cross-sections

Four endpoints: `stats`, `demographics`, `screening`, `runchart`.

**RHD Care Cascade.** Every step is scoped to `status = Active` **and**
`category_at_diagnosis ILIKE '%Rheumatic Heart Disease%'`:

| Step | ACT 2.0 rule |
|---|---|
| Active | `Patient.status == "Active"` |
| Prescribed Prophylaxis | `secondary_prophylaxis IS NOT NULL` |
| Oral count / BPG count | `secondary_prophylaxis IN` the oral set / the injection set |
| Initiated BPG | injection set **and** `secondary_prophylaxis_last IS NOT NULL` |
| Adherent | injection set **and** `adherence >= 0.8` |

**Screening Cascade.** Active, then `confirmatory_diagnosis == "Yes"`, then a category is set, then
the category is RHD/RF, Congenital or Other heart disease.

Also: status pie, procedural waitlist by urgency, medication optimisation over a 365-day window,
demographics by disease category, and a screening section splitting positive/negative, age bands
(0-9, 10-19, 20+) and community vs facility.

## 3. Runcharts, which are pre-aggregated

Eight metrics, and they are **not computed on demand**. A `runchart_record` table is written daily
per clinic with exactly these columns; the charts `SUM()` over a date range.

```
total_registrants                                  interventions_completed
active_registrants                                 consultation_visit_total   <- denominator
active_registrants_seen_last_7_months
active_registrants_prescribed_prophylaxis
active_registrants_adherent
consultation_visits_with_echocardiogram_resulted
consultation_visits_with_intervention
```

Percentages divide by `active_registrants` or by `consultation_visit_total`. Default window is the
last 365 days.

This is the architectural difference that matters: ACT 2.0 pre-aggregates nightly, the Reporting
module evaluates on request.

---

## Mapping each input to ACT 3.0

| ACT 2.0 field | ACT 3.0 equivalent | Note |
|---|---|---|
| `Patient.status == "Active"` | **RHD Registry Status** workflow, state `Active` `de743df6-7404-51d9-97be-0d988a4759a1` | now a program state, not a column |
| `category_at_diagnosis` | Category at Diagnosis `1a5aa050-661d-5e89-95d7-c1eba476df22` on RHD Patient Information | answers below |
| `confirmatory_diagnosis == "Yes"` | the answer **Screen + pending confirmatory echo** `27f33ebe-77fb-575f-b737-00aa47dae6d8` | modelled as a category answer, not a flag |
| `secondary_prophylaxis` | Secondary Antibiotic Prophylaxis `668e0221-8b41-5669-9ad8-78e193d42494` on Consultation Visit | answers below |
| `secondary_prophylaxis_last` | Date Started `5bcc7d12-b279-5955-815c-090a1f392071` | ACT 2.0 held a rollup; O3 has per-encounter dates |
| `adherence` | Adherence Estimate `8edff8dc-4af6-5d0f-bf1d-8e349c7a1b15` on RHD Oral Adherence | **rollup with no O3 equivalent**, see below |
| `most_recent_rhd_consultation` | latest Date of Consultation Visit `c3edefd2-5777-5084-b01e-fd4ca0e40162` | derive from encounters |
| echocardiogram resulted | Date of Echocardiogram `911be530-9457-54be-8515-4bbcdb832ccb` | |
| procedural recommendation | Urgency `7b8eda07-34b6-55f2-ab6c-1b295f41918b`, Completed `1632f8dc-195d-5d67-a52e-6c7a057cb536` | |
| procedures completed | Procedure Date `6cbb5176-144a-576b-9b3d-c9e9d6bc5f5a`, Procedure Type `3a576b80-744a-59ee-9515-d9fdca06f3d7` | |

**Category at Diagnosis answers:** Acute rheumatic fever, RHD A, RHD B, RHD C, RHD D,
Screen + pending confirmatory echo, Congenital heart disease, Other heart disease.

**Prophylaxis split**, which the cascade depends on:

- injection: `Q28 day BPG`, `Q21 day BPG`, `Q14 day BPG`
- oral: `Oral penicillin V`, `Oral sulfadiazine`, `Oral erythromycin`, `Oral clarithromycin`,
  `Oral azithromycin`

ACT 2.0's oral list has four entries; ACT 3.0 added azithromycin. Any cascade built here must
decide whether azithromycin counts.

---

## Two definitions that do not carry over cleanly

**`adherence` was a patient-level rollup.** ACT 2.0 stored a single number per patient and compared
it to 0.8. ACT 3.0 records Adherence Estimate per Oral Adherence encounter and maintains no rollup,
so "adherent" has to be redefined: latest estimate, or mean over a window, or estimate at a given
date. Pick one before building the indicator, because the three give different numbers.

**`category_at_diagnosis ILIKE '%Rheumatic Heart Disease%'`** matched RHD A-D by substring. In
ACT 3.0 those are five discrete coded answers, so the filter becomes an explicit answer list, and
whether Acute rheumatic fever belongs in it is a clinical decision rather than a string match.

---

## What this means for Common Reports

| ACT 2.0 capability | Common Reports 1.6.0 |
|---|---|
| Ad-hoc field-picked CSV | **covered**, and better |
| Patient-level printable summary | **covered** (Patient History PDF) |
| Care and screening cascades | **not covered** |
| Demographics and screening cross-sections | **not covered** |
| Runcharts over time | **not covered**, and needs a daily aggregation job |

Common Reports ships general extracts plus optional Cambodia and Haiti MSPP report sets. Nothing in
it resembles an RHD cascade, so items 2 and 3 are custom work: cohort definitions and indicators in
the Reporting module, and for the runcharts either a scheduled task writing a snapshot table or
report definitions evaluated per period and cached.

Verified on the running instance: both modules start on platform 2.8.10 with reporting
2.2.0-SNAPSHOT (`commonreports.started=true`, `patientsummary.started=true`), which was the main
risk in adding them.
