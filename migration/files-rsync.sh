#!/bin/sh
# Copies the Nextcloud user files into /srv/files, then compares sha256
# manifests of both sides. Extra arguments go to every rsync (e.g. --delete);
# top-level entries that exist only in /srv/files are never deleted or compared.
#
# Runs as root in a throwaway container on kcfam:
#   docker -H ssh://kcfam run --rm -i \
#     -v /srv/docker/volumes/nextcloud_nextcloud/_data/data:/nc:ro \
#     -v /srv/files:/srv/files alpine:3.23 sh -s -- [--delete] < migration/files-rsync.sh
set -euf
apk add -q --no-cache rsync coreutils

# Nextcloud's stock sample files, at the top of each user's tree.
STOCK='--exclude=/Photos/ --exclude=/Templates/ --exclude=/Nextcloud?Manual.pdf
  --exclude=/Nextcloud?intro.mp4 --exclude=/Reasons?to?use?Nextcloud.pdf
  --exclude=/Nextcloud.png --exclude=/Readme.md'

# Top-level entries of dst with no counterpart in src (Syncthing folders,
# nextcloud-export) as rsync protect rules, so --delete never touches them.
protect() { # src dst
  find "$2" -mindepth 1 -maxdepth 1 -exec basename {} \; | while IFS= read -r name; do
    [ -e "$1/$name" ] || printf 'P /%s\n' "$(printf '%s' "$name" | sed 's/[][*?\\]/\\&/g')"
  done
}

copy() { # src dst [extra excludes]
  src=$1 dst=$2; shift 2
  mkdir -p "$dst"
  protect "$src" "$dst" > /tmp/protect
  # shellcheck disable=SC2086
  rsync -a --chown=1000:1000 --filter='merge /tmp/protect' $STOCK "$@" "$src/" "$dst/"
}

copy /nc/maxtkc/files /srv/files/maxtkc --exclude=/Documents/Taxes/ "$@"
copy /nc/stkchristy/files /srv/files/stkchristy "$@"
mkdir -p /srv/files/shared
rsync -a --chown=1000:1000 "$@" /nc/maxtkc/files/Documents/Taxes/ /srv/files/shared/Taxes/
chown 1000:1000 /srv/files/shared

# sha256 of every file, by path relative to the copy root. Same excludes.
manifest() { # dir [extra find args]
  (cd "$1" && shift && find . -type f "$@" -print0 | sort -z | xargs -0r sha256sum)
}
nostock='-not -path ./Photos/* -not -path ./Templates/* -not -path ./Nextcloud?Manual.pdf
  -not -path ./Nextcloud?intro.mp4 -not -path ./Reasons?to?use?Nextcloud.pdf
  -not -path ./Nextcloud.png -not -path ./Readme.md'
fail=0
check() { # label src dst [extra find args for src]
  label=$1 src=$2 dst=$3; shift 3
  # shellcheck disable=SC2086
  manifest "$src" $nostock "$@" > "/tmp/$label.src"
  # Skip dst's protected top-level entries.
  manifest "$dst" | while read -r sum path; do
    top=${path#./}; top=${top%%/*}
    [ ! -e "$src/$top" ] || printf '%s  %s\n' "$sum" "$path"
  done > "/tmp/$label.dst"
  if cmp -s "/tmp/$label.src" "/tmp/$label.dst"; then
    echo "$label: $(wc -l < "/tmp/$label.src") files, manifests identical"
  else
    echo "$label: MANIFESTS DIFFER"; diff "/tmp/$label.src" "/tmp/$label.dst" | head -20; fail=1
  fi
}
check maxtkc /nc/maxtkc/files /srv/files/maxtkc -not -path ./Documents/Taxes/*
check stkchristy /nc/stkchristy/files /srv/files/stkchristy
check taxes /nc/maxtkc/files/Documents/Taxes /srv/files/shared/Taxes
exit $fail
