# Review order for PR #3

Ranked by where a mistake costs most, and where the author is least able to vouch for the work.

## 1. Patient Information

**Why first.** It carried the worst defect: the form could not be saved for a living patient.
It is also the most restructured, and its death gate uses `patient.deceasedDateTime` /
`deceasedBoolean`, a mechanism used nowhere else here. Novel means most likely wrong.

**Check.** Open on a living patient, fill nothing, Save. It must save; before the fix it
returned `Field is mandatory`. Open on a deceased patient and confirm the Death section
appears. Set Case Detected By = School health screening and confirm School Name appears, and
only then.

**Red flag.** Death section visible for a living patient, or the form refusing to save.

## 2. BPG Delivery

**Why.** Most changed form, and the change is clinical: anaphylaxis surveillance.

**Check.** Tick Anaphylaxis on **Injection Tolerance**, the new field, and confirm the
six-field block appears. That path did not exist before. Confirm it still works from Adverse
Reaction too.

**Challenge this.** Anaphylaxis was kept on Adverse Reaction even though ACT 2.0 has it only
on Injection Tolerance. Removing it broke the trigger PR #3 already shipped, so a superset was
the safer call, but it is a deliberate divergence.

## 3. Interventions and Outcomes

**Why.** 19 new fields, the largest surface, and it holds three answer sets the author cannot
validate.

**Check.** Tick Procedure Type = Surgery; the form should go from 16 to about 73 labels.

**Needs a clinician, not a reviewer.** Blood Group, RACHS Score (1 to 6) and Degree of MR.
Wrong coded data looks correct forever. Do not merge these without clinical sign-off.

## 4. Echocardiogram, and it needs Reagan specifically

**Why.** PR #3 un-retires two concepts he deliberately retired as "fabricated". Everything
else in the PR is additive; this reverses someone's decision.

**Check.** Set Mitral Regurgitation to anything but None; the repair pair appears. They exist
in ACT 2.0 behind `Collapse in={mitralRegurgitation != "None"}`, which is why an inspection of
the live app missed them.

## 5. Consultation Visit

**Why.** The "add more" defect lived here: conditional selects in a repeat group showed row 1's
options on row 2.

**Status.** Fixed, if the fix is included in this PR. The single select carrying 40
answer-level hides is replaced by two selects with one field-level hide each, both bound to the
same concept. Answer-level hides are evaluated once per row at mount; field-level hides scope
per row correctly.

**Check.** Set Procedure Type in row 1, add a second row, set it differently. Row 2 should show
its own option set: 23 for Surgery, 19 for Catheterization.

## The rest

Hospital Admission (new Outcome and its two conditions), Pregnancy, Oral Adherence, Consent,
then the seven sub-entity forms. Smaller and lower risk.

## Four traps

- **Test on a clean `down -v`.** Two concepts verified as existing did not exist on a fresh
  database; they had been created by earlier duplicate rows. Only the clean redeploy caught it.
- **Hard-reload the browser.** A cached form schema will show you the old form while the server
  serves the new one. Automated tests open a clean profile and are blind to this.
- **Count database rows; a clean startup proves nothing.** Initializer skips unresolvable rows
  silently and still writes the checksum, so they are never retried. That is how one missing
  concept took out a workflow state and a consent question, and how ten demo forms vanished.
- **O3 date pickers render no `<label>`.** A missing "Date of ..." in a field list usually means
  the picker, not a missing field.

## The one change to scrutinise hardest

**`required` flags went 38 to 9.** ACT 2.0 marks exactly 2. The date on each form was kept and
the rest dropped, because mandatory fields block the partial data entry a registry depends on.
It is the largest behavioural change in the PR and deserves an explicit decision rather than
sliding through.
