# Distro setup defects

Found while standing the distro up from a clean clone to verify form changes. These are not form
problems; they stop the distro being usable at all.

## 1. Config mounts shadow the reference application's own metadata

**Severity: blocks a fresh clone. Fix: eight one-word path changes.**

`docker-compose.yml` bind-mounts Initializer domains into the backend. Most are mounted into an
`/rhd` subfolder, which is **additive**:

```yaml
- ./distro/configuration/concepts:/openmrs/distribution/openmrs_config/concepts/rhd:ro
```

Eight are mounted at the **top level**, which replaces the reference application's own folder for
that domain rather than adding to it:

```yaml
- ./distro/configuration/locationtags:/openmrs/distribution/openmrs_config/locationtags:ro
```

The image ships `locationtags/referenceapplication/locationtags.csv`. The mount hides it, so those
tags are never created.

Affected: `locationtags`, `visittypes`, `encountertypes`, `locations`, `patientidentifiertypes`,
`idgen`, `attributetypes`, `autogenerationoptions`.

The compose file's own comment shows the intent was correct:

> "Mounted per-domain rather than mounting the whole configuration/ directory, so the demo content
> package's own domain folders are left intact."

### What it breaks

`Login Location` and `Visit Location` tags are never created. `rhd_locationtagmaps.csv` has columns
for both, so **every row fails**:

```
java.lang.IllegalArgumentException: No matching location tag found: Login Location
```

O3 requires a login location. The app starts, the forms load, and then nobody can sign in. The
symptom is confusing because nothing obviously fails.

### Measured effect of the fix

| | Before | After |
|---|---|---|
| locations | 12 | 70 |
| location tags | 8 | 13 |
| location tag maps | 11 | 132 |
| **login locations** | **0** | **57** |
| visit types | 1 | 6 |
| encounter types | 10 | 28 |

### Fix

Nest all eight under `/rhd`, matching the pattern already used elsewhere:

```yaml
- ./distro/configuration/locationtags:/openmrs/distribution/openmrs_config/locationtags/rhd:ro
```

## 2. `RHD ID` is a required identifier type, which blocks non-RHD patients

**Severity: correctness. Decision required, not obviously a bug.**

`patientidentifiertypes/rhd_identifiertypes.csv` sets `required=true` on `RHD ID`. In OpenMRS this
is a **global** constraint enforced in `PatientServiceImpl.checkForMissingRequiredIdentifiers`:
*every* patient must have one.

Observed: the reference demo data module cannot create patients at all.

```
org.openmrs.api.MissingRequiredIdentifierException:
  Patient is missing the following required identifier(s): RHD ID
```

Consequences beyond demo data:

- Any patient registered outside the RHD flow fails to save. OpenMRS holds the whole facility's
  patients, not just the RHD programme.
- Auto-generation does not rescue it. `manual entry enabled=false, auto generation enabled=true`
  only applies inside the registration app; programmatic saves, imports and other modules bypass
  idgen and hit the exception.
- It differs from the ACT 2.0 model, where registry membership is what the ACT ID denotes. In
  OpenMRS membership belongs to the **RHD Registry program enrolment**, which already exists in
  `programs/rhd_programs.csv`.

Note `OpenMRS ID` is also required, so every patient needs both.

**Status: intentionally kept.** The team wants the constraint. Recorded here so the consequence is
known rather than discovered later. Registration through the O3 registration app works correctly
and produces the expected `rhd00001` format.

## 3. Demo patients are not generated on a fresh install

`referencedemodata.createDemoPatientsOnNextStartup` defaults to `0`, so a fresh clone comes up with
zero patients and no chart to open. Setting it to a positive number generates patients, but only if
defect 2 is resolved, because the generator cannot satisfy the required RHD ID.

A `globalproperties` Initializer file would fix this for fresh clones. Not added, since it depends
on the decision above.

## 4. Not a repo defect: stale `authentication.scheme` in the local volume

Recorded to save the next person the debugging time. Every request returned HTTP 500:

```
java.lang.RuntimeException: Unable to load class:
  org.openmrs.module.smartonfhir.web.smart.SmartBearerTokenAuthenticationScheme
```

Source was `/openmrs/data/openmrs-runtime.properties` inside the `openmrs-data` Docker volume,
left over from unrelated SMART-on-FHIR work on the same machine:

```properties
authentication.scheme=smartbearer
authentication.scheme.smartbearer.type=org.openmrs.module.smartonfhir.web.smart.SmartBearerTokenAuthenticationScheme
```

The `authentication` module honoured it and tried to load a class from a module this distro does
not install. Nothing to do with this repository. Removing the two lines fixed it. If you reuse
Docker volumes across OpenMRS projects, check this first.
