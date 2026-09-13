# ACT 3.0 migration audit

Evidence and findings from comparing the **ACT 2.0** registry against the **ACT 3.0** OpenMRS
distro, with both systems running locally and driven through their real interfaces.

Captured 11 September 2026, against `DIGI-UW/openmrs-distro-referenceapplication` at `407740b`.

This repository holds only screenshots and findings. No application code.

## Start here

| Document | What it covers |
|---|---|
| [findings/01-form-parity.md](findings/01-form-parity.md) | Form-by-form comparison, 10 ACT 2.0 forms against 18 ACT 3.0 forms, with field coverage |
| [findings/02-distro-setup-defects.md](findings/02-distro-setup-defects.md) | Problems that stop the distro being usable from a clean clone |
| [findings/03-form-defects-fixed.md](findings/03-form-defects-fixed.md) | Two form defects found, fixed and verified before/after |
| [findings/04-method.md](findings/04-method.md) | How this was measured, two methods that gave false results, and how to reproduce |
| [findings/05-field-parity-reverify.md](findings/05-field-parity-reverify.md) | Source-level field parity re-run after PR #3; ~37 ACT 2.0 fields still have no counterpart |

## Headline findings

**1. A clean clone of the distro cannot be logged into.** Eight Initializer domains are mounted at
the top level in `docker-compose.yml`, which replaces the reference application's own metadata
instead of adding to it. No location ends up tagged `Login Location`, so O3 has nothing to sign in
against. The app starts and the forms load, which makes it hard to spot. Fix is eight one-word path
changes. Details in [02](findings/02-distro-setup-defects.md).

**2. Two form defects, both fixed and verified on a running system.**

- **Electrocardiogram Result** was a single select where ACT 2.0 is a multi-select, silently
  dropping all but one finding per ECG.
- **Two echocardiogram concepts** were retired as "fabricated" after a live inspection. They are
  real; they sit inside a conditional block that only renders when mitral regurgitation is set.
  One of them feeds the **"Suitable for Repair"** column on the surgical waitlist.

Details in [03](findings/03-form-defects-fixed.md).

**3. At least 18 ACT 2.0 fields have no home in any of the 18 ACT 3.0 schemas.** Three forms reached
full parity; six have real gaps. The three most consequential:

| Missing field | Form | Why it matters |
|---|---|---|
| Procedural Outcome | Interventions and Outcomes | Two ACT 2.0 critical-flag rules depend on it |
| Date of Injection | BPG Delivery | The adherence calculation counts days covered from it |
| Gravidity, Parity, LMP, Date of Delivery | Pregnancy | Standard obstetric fields; delivery date drives the overdue flag |

Full table in [01](findings/01-form-parity.md).

## Parity at a glance

| ACT 2.0 form | Fields | Covered | Gaps |
|---|---|---|---|
| Echocardiogram | 15 | 15 | 0 |
| Electrocardiogram | 2 | 2 | 0 |
| INR Monitoring | 2 | 2 | 0 |
| Hospital Admission | 5 | 4 | 1 |
| Consultation Visit | 33 | 31 | 2 renames |
| BPG Delivery | 5 | 2 | 2 |
| Oral Adherence | 5 | 2 | 2 |
| Pregnancy | 15 | 10 | 4 |
| Interventions and Outcomes | 26 | 17 | 8 |
| Research Participation | 1 | 0 | 1 |

The two forms showing zero gaps at the top reached parity **because of** the fixes in
[03](findings/03-form-defects-fixed.md).

## Screenshots

```
screenshots/
├── form-comparisons/   ACT 2.0 (left) beside its ACT 3.0 counterpart(s) (right), one per ACT 2.0 form
├── fixes/              before and after for the two defects that were fixed
├── act2-source/        all 10 ACT 2.0 forms, full page
└── act3-target/        all 18 ACT 3.0 forms, plus the patient chart and clinical forms list
```

## Two things to read before trusting any of this

**Field coverage is measured against the form schemas, not the rendered page.** Two earlier
approaches produced roughly 74 false findings between them. Most notably, the O3 form engine
renders date pickers with no `<label>` element, so every `Date of ...` field looks absent to a DOM
scrape when it is present in the schema. See [04](findings/04-method.md).

**Gaps are identified by label, and the count is a floor.** Coverage was checked globally across
all 18 schemas, because ACT 2.0's consultation was split into several ACT 3.0 forms. That means a
field present in the *wrong* form can satisfy the check. This actually happened: Hospital
Admission's **Outcome** was scored as covered because `Surgery Outcome` exists in
`rhd_interventions.json`. Corrected on 11 September. Other gaps may be hidden the same way.

## Cross-cutting observations

- **Conditional display is not implemented anywhere.** Several forms carry `_specBranching`, which
  is a comment, not logic. ACT 2.0 hides fields behind `Collapse` conditions; the distro renders
  them unconditionally.
- **ACT 2.0's consultation embeds other forms inline** (last ECG, last echo, INR, each editable in
  place). The O3 form engine renders one form as one encounter and cannot do this. It is chart
  composition rather than form definition.
- **Renames need a migration mapping.** Where labels or coded answers were renamed, production data
  holds the old strings.
- **Splitting was a good call.** ACT 2.0's single 65-field consultation became five ACT 3.0 forms,
  which suits O3's one-form-one-encounter model. It does mean parity must be judged field by field.
