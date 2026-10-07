-- Rewrites the restored Docker Immich DB for the k8s instance: originals move from
-- the Nextcloud volume (/mnt/nextcloud) to /srv/photos (/mnt/photos), and the
-- library scan is turned off. Run with psql -v ON_ERROR_STOP=1 against the k8s DB only.
BEGIN;
UPDATE asset SET "originalPath" =
  replace("originalPath", '/mnt/nextcloud/data/maxtkc/files/Photos/', '/mnt/photos/maxtkc/');
UPDATE asset SET "originalPath" =
  replace("originalPath", '/mnt/nextcloud/data/stkchristy/files/Photos/', '/mnt/photos/stkchristy/');
UPDATE library SET "importPaths" = ARRAY['/mnt/photos/maxtkc']     WHERE name = 'maxtkc';
UPDATE library SET "importPaths" = ARRAY['/mnt/photos/stkchristy'] WHERE name = 'stkchristy';
UPDATE system_metadata
   SET value = jsonb_set(value, '{library}', '{"scan": {"enabled": false}}')
 WHERE key = 'system-config';

-- Fails the transaction if any path still points at the old mount.
DO $$
DECLARE
  r record;
  n bigint;
BEGIN
  FOR r IN
    SELECT table_name, column_name FROM information_schema.columns
     WHERE table_schema = 'public' AND data_type IN ('text', 'character varying', 'ARRAY', 'jsonb')
  LOOP
    EXECUTE format('SELECT count(*) FROM %I WHERE %I::text LIKE %L', r.table_name, r.column_name, '%/mnt/nextcloud%') INTO n;
    IF n > 0 THEN
      RAISE EXCEPTION '% rows in %.% still reference /mnt/nextcloud', n, r.table_name, r.column_name;
    END IF;
  END LOOP;
  SELECT count(*) INTO n FROM asset
   WHERE "originalPath" NOT LIKE '/mnt/photos/%' AND "originalPath" NOT LIKE '/usr/src/app/%';
  IF n > 0 THEN RAISE EXCEPTION '% assets outside /mnt/photos and /usr/src/app', n; END IF;
END $$;
COMMIT;
