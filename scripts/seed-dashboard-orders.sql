-- Seed N in-progress orders for the Home dashboard tile.
--
-- Creates one sample + one sample_item + one analysis per order, with the
-- analysis in the status the ORDERS_IN_PROGRESS tile selects on ("Not Tested",
-- AnalysisStatus.NotStarted). Tests are assigned round-robin across every
-- active test so the rows spread over test sections and the tab filter has
-- something to bite on.
--
-- Accession numbers are PAG0000001 upward, so everything seeded here can be
-- found and removed again by that prefix.
--
--   docker exec -i openelisglobal-database \
--     psql -U clinlims -d clinlims -v n=400 < seed-dashboard-orders.sql

\set n 400

SET search_path TO clinlims;

BEGIN;

-- Fixture loads insert explicit ids, which leaves these sequences behind the
-- real max and makes nextval collide on the primary key.
SELECT setval('sample_seq',
              GREATEST((SELECT COALESCE(MAX(id), 0)::bigint FROM sample), 1));
SELECT setval('sample_item_seq',
              GREATEST((SELECT COALESCE(MAX(id), 0)::bigint FROM sample_item), 1));
SELECT setval('analysis_seq',
              GREATEST((SELECT COALESCE(MAX(id), 0)::bigint FROM analysis), 1));

CREATE TEMP TABLE pag_tests ON COMMIT DROP AS
SELECT row_number() OVER (ORDER BY id) - 1 AS rn, id, test_section_id
FROM test
WHERE is_active = 'Y';

CREATE TEMP TABLE pag_samples ON COMMIT DROP AS
WITH ins AS (
  INSERT INTO sample (id, accession_number, fhir_uuid, domain, status_id,
                      entered_date, received_date, sys_user_id, lastupdated,
                      is_confirmation)
  SELECT nextval('sample_seq'),
         'PAG' || lpad(g::text, 7, '0'),
         gen_random_uuid(),
         'H',
         (SELECT id FROM status_of_sample WHERE name = 'Entered' LIMIT 1),
         now(), now(), 1, now(), FALSE
  FROM generate_series(1, :n) AS g
  RETURNING id
)
SELECT row_number() OVER (ORDER BY id) - 1 AS rn, id FROM ins;

CREATE TEMP TABLE pag_items ON COMMIT DROP AS
WITH ins AS (
  INSERT INTO sample_item (id, samp_id, sort_order, typeosamp_id,
                           collection_date, collector, quantity, status_id,
                           voided, rejected, lastupdated)
  SELECT nextval('sample_item_seq'), s.id, 1,
         (SELECT id FROM type_of_sample ORDER BY id LIMIT 1),
         now(), 'seed', 5.0,
         (SELECT id FROM status_of_sample WHERE name = 'Entered' LIMIT 1),
         FALSE, FALSE, now()
  FROM pag_samples s
  RETURNING id
)
SELECT row_number() OVER (ORDER BY id) - 1 AS rn, id FROM ins;

INSERT INTO analysis (id, sampitem_id, test_id, test_sect_id, status_id,
                      analysis_type, entry_date, started_date, is_reportable,
                      revision, lastupdated)
SELECT nextval('analysis_seq'), i.id, t.id, t.test_section_id,
       (SELECT id FROM status_of_sample WHERE name = 'Not Tested' LIMIT 1),
       'MANUAL', now(), now(), 'N', 0, now()
FROM pag_items i
JOIN pag_tests t ON t.rn = i.rn % (SELECT count(*) FROM pag_tests);

COMMIT;

SELECT count(*) AS in_progress_rows
FROM analysis a
JOIN sample_item si ON si.id = a.sampitem_id
WHERE a.status_id = (SELECT id FROM status_of_sample WHERE name = 'Not Tested');

-- Teardown, in this order because of the foreign keys:
--
--   DELETE FROM analysis WHERE sampitem_id IN (
--     SELECT si.id FROM sample_item si JOIN sample s ON s.id = si.samp_id
--     WHERE s.accession_number LIKE 'PAG%');
--   DELETE FROM sample_item WHERE samp_id IN (
--     SELECT id FROM sample WHERE accession_number LIKE 'PAG%');
--   DELETE FROM sample WHERE accession_number LIKE 'PAG%';
