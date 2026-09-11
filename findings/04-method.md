# Method, and how to reproduce

## Environments

Both systems were run locally and driven through their real interfaces. Nothing here is read off
source alone unless stated.

| | |
|---|---|
| ACT 2.0 | `is4r-rhd-cdk` + `is4r-rhd-ui`. Docker Postgres, API under AWS SAM, Vite UI on :5173. Auth mocked locally. Patient `rhd00000`, all 10 form types populated |
| ACT 3.0 | `openmrs-distro-referenceapplication` at `407740b`. Gateway remapped to :8081. Patient `rhd00001`, active visit |
| Browser | Playwright, bundled Chromium |

## Two measurement errors worth recording

Both produced large numbers of false findings. They are documented so nobody repeats them.

### Exact label matching produced 64 false gaps

Labels differ legitimately between the two systems:

- renamed: `Mitral Stenosis` to `Mitral stenosis severity`
- unit suffixes added: `Mitral Valve Annulus Diameter` to `... (cm)`
- unit fragments picked up as if they were fields: `mmHg`, `cm`, `days`, `hours`

### Scraping rendered labels produced about 10 more

**The O3 form engine renders date pickers without a `<label>` element.** Every `Date of ...` field
appeared to be missing. `Date of Echocardiogram` is in the schema and visible on screen, but a
label scrape cannot see it.

### What the audit actually uses

Field coverage is measured against the **18 form JSON schemas** on disk, not the rendered DOM.
Comparison is tolerant of parenthetical suffixes and does substring matching in both directions,
then every remaining gap is checked by hand against the schemas.

Result: 204 questions across 18 ACT 3.0 forms, against 109 ACT 2.0 fields, 23 flagged, of which
**6 were renames and 17 genuine**.

## Reproducing

```bash
# ACT 2.0
cd is4r-rhd-cdk
AUTO_INSTALL=1 ./scripts/local_setup.sh --seed --serve   # terminal 1
cd is4r-rhd-ui && pnpm dev --port 5173 --strictPort      # terminal 2

# ACT 3.0
cd openmrs-distro-referenceapplication
docker compose up -d      # apply the mount fix in findings/02 first, or login will not work
```

Two traps when scripting the ACT 2.0 UI:

- The UI route parameter `:patientId` takes the **ACT ID** (`rhd00000`), not the numeric id. The
  loader calls `/patients/{patientId}` and that endpoint looks up by `patient_base_id`.
  `/patients/1` returns 404.
- `ProtectedRoute` only checks for a token in `localStorage`, so seed `rhdIdToken` before
  navigating or every page redirects to login.

In the O3 chart, clinical forms are launched from the **"Clinical forms"** control in the
right-hand action rail, not from the left navigation.

## Raw data

- `report.json` — per-form label and question inventories for both systems
- `final.json` — the classification of flagged fields into renames versus genuine gaps
