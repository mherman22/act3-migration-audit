# The RHD config mounts shadow package content

`docker-compose.yml` binds each RHD config folder over the same folder in the image. A mount
whose target ends in the bare domain name **replaces** the folder; one that ends in `/rhd`
**adds to** it. Nine RHD mounts currently replace, and the image ships content under every one
of them, so nine folders of package configuration never load.

| mount target | package content hidden | observed consequence |
|---|---|---|
| `patientidentifiertypes` | OpenMRS ID, Legacy ID, ID Card, SSN | demo patient generation aborts |
| `idgen` | the OpenMRS ID sequential generator | as above |
| `autogenerationoptions` | auto-assignment of OpenMRS ID | as above |
| `encountertypes` | 18 demo encounter types | demo forms load but their encounter types do not resolve |
| `locations` | 59 demo locations | none, and nesting this one is harmful |
| `addresshierarchy` | a 344-row demo hierarchy and `addressConfiguration.xml` | none; RHD ships both, at 122,083 rows |
| `visittypes` | 5 demo visit types | none; RHD defines one visit type |
| `attributetypes` | 5 demo attribute types | none observed |
| `conceptsources` | 24 concept sources | none observed; CIEL arrives through OCL |

`locationtags` was a tenth. PR #3 nests it, because the `Login Location` tag lives in the package
folder and without it the login picker is empty.

## Demo patients

A from-scratch database contains zero patients:

```
ERROR - ReferenceDemoDataActivator.started(245)
org.openmrs.api.APIException: Could not find identifier type OpenMRS ID
  at DemoPatientGenerator.createDemoPatients(DemoPatientGenerator.java:67)
```

`OpenMRS ID` is defined in `patientidentifiertypes/referenceapplication-demo/patientidentifiertypes-core_demo.csv`,
which the RHD mount hides. Restoring it takes three mounts, not one: the identifier type, the
generator in `idgen`, and the assignment rule in `autogenerationoptions`. The type alone would
be created without a source, so the generator would still have nothing to draw from.

The two uuids that `frontend/config-core_demo.json` pointed at before PR #3
(`b4143563-…`, `a71403f3-…`) are the package's **ID Card** and **SSN**. They were never wrong
references; they were references to types this mount hides. Repointing them at National ID and
Alternate ID is still the right call for this registry, which is what PR #3 does.

## What to nest and what to leave

Nesting is not automatically correct. `locations` was nested once during this work and it added
57 reference-application locations to the login picker, burying Gulu, Lira and Uganda. The
question for each folder is whether the package rows are wanted, not whether they are hidden.

- **Nest** `patientidentifiertypes`, `idgen`, `autogenerationoptions` together, if demo patients
  are wanted on a fresh database. Registration is unaffected: `defaultPatientIdentifierTypes` is
  set explicitly.
- **Nest** `encountertypes` if the packaged demo forms should work.
- **Leave replacing** `locations`, `addresshierarchy`, `visittypes`: RHD supplies its own and the
  package rows are unwanted.
- **Undecided** `attributetypes`, `conceptsources`: nothing observed either way.

None of this is in PR #3, which touches `docker-compose.yml` on one line only.
