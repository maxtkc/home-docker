# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

The `kcfam.us` home server (`kcfam`, `kcfam-deb`, 192.168.0.182). Almost
everything runs in the single-node k3s cluster, synced by the ArgoCD shared with
gtfs.zone (`../gtfs-zone-infra`) from this repo's `main` branch. Nothing runs
on Docker any more.

Routes (namespace `home` unless noted):
- `im.kcfam.us`: Immich (`home/immich`)
- `files.kcfam.us`: File Browser Quantum; Syncthing on host port 22000 (`home/files`)
- `sync.kcfam.us`: Syncthing GUI (`home/files`)
- `id.kcfam.us`: Keycloak, realm `kcfam`; `auth.kcfam.us`: oauth2-proxy (`home/auth`)
- `gramps.kcfam.us`: GrampsWeb (`home/grampsweb`)
- `gf.kcfam.us`: kube-prometheus-stack (`apps/home-monitoring.yaml`, `home/monitoring`)
- `status.kcfam.us`: Gatus (`home/gatus/config.yaml`)
- `cors.kcfam.us`: cors-anywhere (`home/cors-proxy`)
- `argocd.kcfam.us`: alias of the gtfs ArgoCD (`home/argocd-alias`)
- `max.kcfam.us`: GitHub Pages from `maxtkc/personal-site`, a CNAME to
  `maxtkc.github.io`, nothing on kcfam
- tgtg has no hostname (see "tgtg on k3s")

## Edge

k3s Traefik (`infra-traefik` in gtfs-zone-infra, values in
`infra/traefik/values.yaml`) owns host :80 (redirect to https) and :443 through
ServiceLB, for both kcfam.us and gtfs.zone. Certificates are cert-manager DNS-01
(ClusterIssuer `letsencrypt-porkbun`), one per host. `<name>.new.kcfam.us` routes
use the wildcard cert from `home/base`.

## Working on the cluster

- One `ssh kcfam kubectl --kubeconfig /etc/rancher/k3s/k3s.yaml ...` per call.
  `helm` is only on the laptop.
- `apps/home-root.yaml` is the app of apps (applied once by hand); every other
  file in `apps/` is an Application for one `home/<dir>`.
- Secrets are `home/**/*.enc.yaml`, encrypted to the age key in `.sops.yaml`.
  The private key is `age.key` (gitignored) and also sits in the `argocd/sops-age`
  Secret alongside the gtfs key. Render before committing:
  `PATH="$HOME/.local/bin:$PATH" SOPS_AGE_KEY_FILE=$PWD/age.key kustomize build --enable-alpha-plugins --enable-exec home/<dir>`
- DNS: `home-external-dns` (values in `home/external-dns`) manages `kcfam.us`
  records only. An IngressRoute gets a CNAME to the apex by carrying
  `external-dns.alpha.kubernetes.io/target: kcfam.us`. Records it did not
  create are left alone; never declare the apex.
- Gatus keeps keep-alive connections across a backend change and reports the
  old backend until restarted.
- k8s `command` replaces the image entrypoint (GrampsWeb's sets the secret key,
  so celery uses `args`).
- k3s's containerd store is `/srv/k3s/containerd`, bind-mounted over
  `/var/lib/rancher/k3s/agent/containerd` (fstab). `/var` is too small for it.
- Pin image versions; floating tags are never re-pulled.
- `home/intel-gpu` runs Intel's GPU device plugin, so the UHD 620 is the node
  resource `gpu.intel.com/i915` (one pod at a time); Immich requests it for
  VAAPI transcoding instead of running privileged.

## Login

Every app logs in through Keycloak (`home/auth`, realm `kcfam`); no app keeps a
password login. Status page and cors are public.

- Realm users are created by hand (admin console or API). The IdPs (Google,
  GitHub, LinkedIn) use the `link existing only` first-login flow: a login links
  to the realm user with the same verified email, anyone else is refused. A
  username needs at least 3 characters.
- Groups: `family` (Files, Immich, Grafana Viewer), `admins` (Grafana Admin,
  File Browser admin, Syncthing GUI), `gramps` (GrampsWeb, including relatives
  who have nothing else).
- `kcfam-realm.json` (clients, groups, the first-login flow, IdPs) is applied
  to the live realm by the `keycloak-config-cli` PostSync Job on every sync of
  `home-auth`, so console edits to those are reverted; change the file. Users
  are not in it: they and their IdP links are database state, created in the
  console or API. It defines no `clientScopes` (that would skip the built-in
  email/profile scopes). The config-cli image is built per Keycloak version;
  bump its tag with Keycloak (6.5.1-26.5.5 runs fine against 26.7.5).
- Break-glass: master-realm `admin`, password `KEYCLOAK_ADMIN_PASSWORD` in
  `home/auth/auth.enc.yaml`. App-side: File Browser local `admin` (enable the
  password method), Immich `passwordLogin` in `home/immich/immich-config.enc.yaml`,
  Grafana `grafana cli admin reset-admin-password`.
- Immich: system settings come from `immich-config.enc.yaml`
  (`IMMICH_CONFIG_FILE`), read-only in the UI; bump `config-revision` in
  `server.yaml` after editing. Users link by email. Since v3.3.0 Immich syncs
  quota, role and a non-default storage label claim on every login; Keycloak
  sends none of `immich_quota`, `immich_role` or a custom label claim, and the
  default `preferred_username` label applies only at registration, so login
  changes nothing. Adding one of those claims in Keycloak would.
- File Browser: matches `preferred_username` to its user, which must have login
  method `oidc`.
- GrampsWeb: native OIDC, bound by Keycloak user ID in the `oidc_accounts` table
  of `/app/users/users.sqlite`, never by email. A new person needs a Keycloak
  user in `gramps` plus that row (`create_oidc_account(guid, "custom", sub)`),
  or their first login makes a fresh disabled account.
- Syncthing GUI has no login of its own; oauth2-proxy (`admins`) and a
  NetworkPolicy (Traefik only on :8384) guard it.

## Storage

- Bulk data is static hostPath on `/srv`: `/srv/photos` (Immich external
  libraries), `/srv/immich/upload`, `/srv/immich/model-cache`,
  `/srv/files/{maxtkc,stkchristy,shared}` (uid 1000).
- Small state is Longhorn PVCs (Postgres, GrampsWeb, Grafana, tgtg tokens,
  Syncthing/File Browser config, Keycloak's CNPG `keycloak-pg`).
- Immich mounts `/srv/photos` read-write, so a delete in Immich removes the file.
- External-library assets were rehashed to content SHA-1 on 2026-10-08 (Immich
  scans store `sha1-path`), so phone backup skips photos already there. A scan
  of a new or changed file stores `sha1-path` again for that file.
- File Browser users and source access live in its database (PVC), not the
  ConfigMap.

## Backups

- `restic-backup` (`home/backup`, daily 03:30) writes `/mnt/backups/restic` as
  host `home-k8s`: `/srv/photos`, `/srv/immich` (minus model cache and
  Immich's own gzipped DB dumps in `upload/backups`),
  `/srv/files` and `pg_dump`s of the Immich and Keycloak DBs to
  `/srv/backup-dumps` first. GrampsWeb's SQLite files are copied there too
  (`/dumps/grampsweb`), and the `grampsweb-data`, `filebrowser-data`,
  `syncthing-config` and `tgtg-tokens` PVCs are mounted read-only under `/pvc`.
  7 daily / 4 weekly / 6 monthly. `restic-check`
  reads 5% Saturdays at 05:00. Immich's integrity checks run at 01:00 to stay
  clear of it.
- `restic-offsite` (daily 06:00) copies the `home-k8s` snapshots to B2,
  `s3:s3.us-east-005.backblazeb2.com/kcfam-restic`, and forgets with the same
  policy as `restic-backup` (a different policy makes `copy` re-upload snapshots
  B2 already forgot). Upload capped at 3000 KiB/s. Same passphrase as the local repo; key in
  `home/backup/restic-b2.enc.yaml`. The bucket must keep only the last file
  version, or pruned data stays billed. `restic-offsite-check` reads 2% on the
  1st. `copy` locks the source repo, so it is mounted read-write.
- Docker-era snapshots stay local and are never forgotten: `d3add526`
  (`pre-migration`, host `dbedfab23807`) and `e214dddd` (`nextcloud-final`,
  host `docker-final`, 2026-10-08: every Nextcloud, Immich, GrampsWeb, Grafana,
  Uptime Kuma and tgtg volume at decommission) and `326609cb` (`ha-ma-final`,
  host `ha-ma-final`, 2026-10-08: the Home Assistant and Music Assistant volumes
  when they were removed).
- Passphrase, B2 key and `age.key` are in the password manager and on paper.

## tgtg on k3s

`home/tgtg` runs `ghcr.io/maxtkc/tgtg:main-<sha>`, built by
`.github/workflows/ghcr.yml` on the fork's `main` branch
(github.com/maxtkc/tgtg) on every push; bump the tag in `home/tgtg/tgtg.yaml`.
Tokens, including the parked `datadome.bak-*` cookies, are on the `tgtg-tokens`
PVC. `gluetun` is a separate Deployment and Service (proxy `:8888`, control
server `:8000`), not a sidecar, so only TGTG API requests use the tunnel and
Telegram stays direct. Keys are in `home/tgtg/*.enc.yaml`; the NordVPN access
token is also in `~/tfstate/home-tf/nordvpn.secrets` on kcfam. Never run two
scanners on one token.

tgtg exports price and scan-health metrics on `tgtg:8000`. With
`PRICE_MONITORING`, the bot notifies when a bag is in stock at its price floor,
the lowest price/value ratio seen for it (kept in `price_floors.json` on the
tokens PVC, reset to the current price if not reached for 7 days). Fixed-price
bags notify on restock; a dynamic bag stays silent at 1/2 of value and notifies
when it steps down to its floor. Prometheus alerts with `TgtgScanStale` when no
scan has succeeded for an hour. The bot posts a notice after three failed scans
in a row (e.g. DataDome 403s), with buttons to move the VPN exit or try direct;
`/vpn`, `/vpn new` and `/vpn <country>[, city]` do the same by command.
`/vpn off` sends TGTG traffic direct from the home IP and `/vpn on` back through
gluetun; the mode is kept in `vpn.json` on the tokens PVC and wins over
`HTTPS_PROXY` in `env.yaml`.

Why tgtg goes through gluetun: TGTG's DataDome anti-bot layer returned 403
captcha interstitials to the home IP from 2026-09-25 on. A custom
`TGTG_USER_AGENT`, `TGTG_APK_VERSION=26.2.10`, a fresh DataDome cookie and a
four-day cool-off (still 403 on 2026-10-05) did not help. Through the NordVPN exit
on 2026-10-07, with a fresh cookie, scanning worked on the first try. If the VPN IP
gets blocked too, the bot says so and offers buttons; `/vpn new` (same country) or
`/vpn Germany` moves the exit through the gluetun control server and parks the
`datadome` file. A country change made this way lasts until gluetun restarts;
`SERVER_COUNTRIES` in `home/tgtg/tgtg.yaml` is the persistent default. Don't rotate on a schedule:
DataDome binds its cookie to the IP.

On 2026-10-08 a bogus-token probe from the home IP (no proxy) with 26.2.10 got
401, so DataDome lets home through again after the fork fixes in `main-763bed7`
(SDK `ddvc` matching the APK version, blocked cookies replaced). `/vpn off`
switches to direct without a redeploy; a mode change resets the DataDome cookie.
`/vpn new` or `/vpn <country>` while direct switches back to the VPN first.

On 2026-10-08 every exit got 403 because the APK version, scraped from the Play
Store when `TGTG_APK_VERSION` is unset, became `26.10.0`, which DataDome
blocks; `26.2.10` passes. It is pinned in `home/tgtg/env.yaml`. To tell a
blocked version from a blocked IP, run a throwaway pod from the tgtg image with
`HTTPS_PROXY=http://gluetun:8888` that POSTs `token/v1/refresh` with a bogus
token: 401 means DataDome passed, 403 means it did not. Never use the real
tokens for this; a refresh rotates them. A few 403s burn the exit within
seconds (even for a good version afterwards), so after probing, park
`/tokens/datadome`, move the exit, and restart tgtg.
