#!/bin/bash
# Exports Nextcloud app data that has no new home into $OUT on kcfam:
#   db/<table>.csv    every non-empty app table (columns named *password* dropped)
#   contacts/*.vcf    one per address book
#   calendars/*.ics   one per calendar (an iCalendar stream, one VCALENDAR per object)
#   deck.json         occ deck:export maxtkc
#   shares.csv        oc_share with each share's file path
#   nextcloud.dump    pg_dump -Fc
#
# Run on kcfam as a file (docker exec -i reads stdin, so not via bash -s):
#   ssh kcfam 'cat > nc-export.sh' < migration/nc-export.sh && ssh kcfam bash nc-export.sh
set -euo pipefail
OUT=${OUT:-$HOME/nc-export}
mkdir -p "$OUT"/{db,contacts,calendars}
psql() { docker exec -i db psql -U nextcloud -d nextcloud -X -v ON_ERROR_STOP=1 "$@"; }

tables=$(psql -At <<'EOF'
SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename ~
  '^oc_(phonetrack|gpodder|talk|forms|polls|mail|deck|addressbooks|cards|calendars|calendarobjects|calendarsubscriptions)'
ORDER BY 1;
EOF
)
for t in $tables; do
  n=$(psql -Atc "SELECT count(*) FROM $t" < /dev/null)
  [ "$n" -gt 0 ] || continue
  cols=$(psql -At <<EOF
SELECT string_agg(quote_ident(column_name), ',' ORDER BY ordinal_position)
  FROM information_schema.columns
 WHERE table_name = '$t' AND column_name NOT ILIKE '%password%';
EOF
)
  psql -c "\copy (SELECT $cols FROM $t) TO STDOUT CSV HEADER" < /dev/null > "$OUT/db/$t.csv"
  echo "db/$t.csv $n"
done

# <id>|<file name>, names made filesystem-safe.
psql -At <<'EOF' | while IFS='|' read -r id name; do
SELECT a.id, regexp_replace(split_part(a.principaluri, '/', 3) || '-' || a.displayname, '[^A-Za-z0-9._@-]+', '_', 'g')
  FROM oc_addressbooks a WHERE EXISTS (SELECT 1 FROM oc_cards c WHERE c.addressbookid = a.id);
EOF
  psql -At -c "SELECT string_agg(rtrim(convert_from(carddata, 'UTF8'), E'\r\n'), E'\n' ORDER BY id) FROM oc_cards WHERE addressbookid = $id" \
    < /dev/null > "$OUT/contacts/$name.vcf"
  echo "contacts/$name.vcf $(grep -c '^BEGIN:VCARD' "$OUT/contacts/$name.vcf")"
done

psql -At <<'EOF' | while IFS='|' read -r id name; do
SELECT c.id, c.id || '-' || left(regexp_replace(split_part(c.principaluri, '/', 3) || '-' || c.displayname, '[^A-Za-z0-9._@-]+', '_', 'g'), 80)
  FROM oc_calendars c WHERE EXISTS (SELECT 1 FROM oc_calendarobjects o WHERE o.calendarid = c.id AND o.calendartype = 0);
EOF
  psql -At -c "SELECT string_agg(rtrim(convert_from(calendardata, 'UTF8'), E'\r\n'), E'\n' ORDER BY id) FROM oc_calendarobjects WHERE calendarid = $id AND calendartype = 0" \
    < /dev/null > "$OUT/calendars/$name.ics"
  echo "calendars/$name.ics $(grep -c '^BEGIN:VCALENDAR' "$OUT/calendars/$name.ics")"
done

docker exec -u www-data nextcloud php occ deck:export maxtkc < /dev/null > "$OUT/deck.json"
echo "deck.json $(wc -c < "$OUT/deck.json") bytes"

psql -c "\copy (SELECT s.id, s.share_type, s.uid_owner, s.share_with, f.path, s.item_type, s.permissions, s.token, s.expiration, s.label, to_timestamp(s.stime) AS created FROM oc_share s LEFT JOIN oc_filecache f ON f.fileid = s.file_source ORDER BY s.id) TO STDOUT CSV HEADER" \
  < /dev/null > "$OUT/shares.csv"
echo "shares.csv $(($(wc -l < "$OUT/shares.csv") - 1))"

docker exec db pg_dump -U nextcloud -Fc nextcloud > "$OUT/nextcloud.dump"
docker exec -i db pg_restore -l < "$OUT/nextcloud.dump" > /dev/null
echo "nextcloud.dump $(du -h "$OUT/nextcloud.dump" | cut -f1), pg_restore -l ok"
(cd "$OUT" && find . -type f ! -name SHA256SUMS -print0 | sort -z | xargs -0 sha256sum > SHA256SUMS)
