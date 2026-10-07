# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

This is a home server stack managed with **OpenTofu (Terraform)** deploying Docker containers to a remote SSH host (`ssh://kcfam`). All infrastructure is defined as code in the `tf/` directory. A separate `tf-monitors/` module manages Uptime Kuma health checks.

Services and their routes:
- `nc.kcfam.us` → Nextcloud (custom-built with ffmpeg, exiftool, imagemagick)
- `im.kcfam.us` → Immich (photo management with AI/ML)
- `gramps.kcfam.us` → GrampsWeb (genealogy)
- `gf.kcfam.us` → Grafana (metrics dashboards)
- `uptime.kcfam.us` → Uptime Kuma (status monitoring, public status page at status.kcfam.us)
- `git.kcfam.us` → Forgejo (git hosting with CI/CD runner)
- `op.kcfam.us` → OpenProject (project management, toggleable via `var.run_openproject`)
- `tgtg.kcfam.us` → Too Good To Go notifier

`gluetun` (internal only, `tf/compute_vpn.tf`) is a NordVPN tunnel exposed as an HTTP proxy on `gluetun:8888`. It exists only when `var.nordvpn_wireguard_private_key` is set, and tgtg uses it when `var.tgtg_use_vpn` is true. tgtg exports price and scan-health metrics on `tgtg:8000`. Prometheus alerts with `TgtgPriceAtLow` when an in-stock dynamic-price bag drops to about 1/3 of its value, and with `TgtgScanStale` when no scan has succeeded for an hour. The tgtg bot itself posts a notice after three failed scans in a row (e.g. DataDome 403s), with buttons to move the VPN exit; `/vpn`, `/vpn new` and `/vpn <country>[, city]` do the same by command.

**Traefik v3** handles reverse proxying and Let's Encrypt SSL. **Sablier** manages auto-scaling for GrampsWeb: containers spin down after 1 minute of inactivity and wake on request. **OpenProject** is not Sablier-managed — it is entirely toggled on/off via `var.run_openproject` (Terraform `count`).

## Terraform Modules

### `tf/` — Main infrastructure
- **providers.tf / terraform.tf**: Docker provider (kreuzwerker/docker v3.9.0) connecting via SSH to remote host; Porkbun provider for DNS management
- **variables.tf / secrets.auto.tfvars**: Sensitive values (passwords, API keys) — gitignored
- **locals.tf**: Shared local values
- **networks.tf / volumes.tf**: Docker networks and named volumes (all volumes have `prevent_destroy = true`)
- **dns.tf**: DNS records managed via Porkbun API (A records, CNAMEs for all subdomains)
- **images.tf**: Custom Docker image builds; rebuild is triggered by SHA1 hash of the source directory
- **compute_*.tf**: Service definitions grouped by function

### `tf-monitors/` — Uptime Kuma monitors
Uses the `breml/uptimekuma` provider to declaratively manage HTTP, TCP, and Docker container monitors plus a public status page at `status.kcfam.us`. Requires `secrets.auto.tfvars` with Uptime Kuma credentials.

### Custom Docker images
Configuration files are **baked into images** (not volume-mounted) because we use a remote Docker host. Edit the relevant directory and rebuild:
- `my_nc/` — Nextcloud with media tools
- `web/` — nginx serving Nextcloud
- `traefik/` — Traefik with static config and dynamic routing rules
- `prometheus/` — Prometheus with scrape config
- `grafana/` — Grafana with provisioning and dashboards
- `forgejo_runner/` — Forgejo CI/CD runner
- `static-sites/` — nginx serving static sites
- `kcfam/tgtg:local` - built from a local checkout of the tgtg fork
  (github.com/maxtkc/tgtg, branch `travel-mode`) when `var.tgtg_fork_path` is set;
  otherwise tgtg runs `derhenning/tgtg:${var.tgtg_version}`. The provider's buildx
  path fails over an ssh host, so the build block leaves `builder` unset.

## Common Commands

All Terraform commands run from within the module directory.

**Deploy / update infrastructure:**
```bash
cd tf
tofu plan
tofu apply
```

**Update monitors:**
```bash
cd tf-monitors
tofu plan
tofu apply
```

**Rebuild a custom image and redeploy:**
```bash
cd tf
tofu apply -replace=docker_image.nextcloud   # or grafana, traefik, etc.
```

**View container logs (on remote host, assumes remote docker context set):**
```bash
docker logs -f <container_name>
```

**Initialize a module (first time or after provider changes):**
```bash
cd tf          # or tf-monitors
tofu init
```

## Secrets Management

Sensitive values live in `secrets.auto.tfvars` (gitignored) in each module directory. Variable declarations are in `variables.tf`. The `.env` file holds non-sensitive configuration referenced by some containers.

## Backup and Restore

File data and databases are backed up separately.

- **restic** (`restic-data`) backs up the `nextcloud` and `immich_upload` volumes
  to a deduplicated, encrypted repository at `/mnt/backups/restic`, daily at
  02:00, keeping 7 daily / 4 weekly / 6 monthly. `restic-check` verifies the
  repository Sundays at 05:00. The passphrase is `var.restic_password` and has no
  recovery path.
  Snapshot `d3add526` (2026-10-06) is tagged `pre-migration`. On 2026-10-07
  `restic-data` was recreated by hand with `--keep-tag pre-migration` appended to
  `RESTIC_FORGET_ARGS` so retention keeps it; `tf/` does not have the flag. The
  recreate kept hostname `dbedfab23807`, since restic groups snapshots by host.
- **offen tarballs** still cover the databases and the small volumes, because
  resticker has no equivalent of `BACKUP_STOP_DURING_BACKUP_LABEL` and a Postgres
  data directory copied while the server is writing to it is not a backup:
  `backup-daily` (databases only, 01:30, `homeserver-db-*`), `backup-weekly`
  (Sunday 03:00) and `backup-monthly` (1st at 04:00), all under `/mnt/backups`.

`restic-data` and `restic-check` must not share a cron: resticker treats
`BACKUP_CRON` and `CHECK_CRON` as mutually exclusive and exits if both are set in
one container. Both cron values are **six-field with seconds first**; the
five-field form the offen containers use is accepted and silently schedules the
wrong time.

Each offen tier sets `BACKUP_PRUNING_PREFIX`. Without it, a tier applies its
retention window to every file in its `/archive` directory regardless of
filename, so anything parked there for safekeeping disappears on that tier's
clock.

**Lessons learned:**
- Use the backup container's tar (GNU tar), not Alpine's BusyBox tar — Alpine fails with exit code 125 on large files
- Verify backup file size; empty backups mean the volume was empty at backup time
- Always stop services using a volume before restoring it
- Check timestamps after restore to confirm data was replaced

### Never run `docker container prune` on this host

It deletes every *stopped* container, and on this host "stopped" does not mean
"unwanted". Three groups are routinely stopped and still load-bearing:

- containers offen has stopped mid-run via `backup.stop` (`immich_postgres`,
  `immich_server`, `nextcloud`, ...), which stay stopped if the backup dies
- everything sablier has scaled to zero (`grampsweb`, `grampsweb_celery`,
  `grampsweb_redis`)
- `backup-daily` and `backup-weekly`, which sit `Exited (0)` between runs

On 2026-09-07 a prune during the disk-full recovery removed `immich_postgres`
while offen had it stopped. Its volume survived (`prevent_destroy`), but
`im.kcfam.us` served 500s (`getaddrinfo ENOTFOUND immich_postgres`) for five
hours. `tofu apply` recreates anything pruned; it is the recovery path, not a
manual `docker run`. `docker volume prune` is equally unsafe here, for the same
reason: 47 named compose volumes look dangling only because their containers are
stopped.

### `tofu plan` deletes stopped containers

The pinned provider, kreuzwerker/docker **v3.9.0**, deletes a container during a
plain *refresh* if it is not running and `must_run` is true (the default). From
`resourceDockerContainerRead`:

```go
if !container.State.Running && d.Get("must_run").(bool) {
    if err := resourceDockerContainerDelete(ctx, d, meta); err != nil { ... }
```

So `tofu plan` is **not read-only here**, and it hits exactly the containers the
prune warning above lists. Anything offen has stopped via `backup.stop` gets
deleted by a plan run during the 01:30-02:00 backup window. On 2026-09-11 a plan
deleted `backup-daily` and `backup-weekly`, both sitting `Exited (0)` between
runs. This is a strong candidate for the real cause of the 2026-09-07
`immich_postgres` loss, which was attributed to a manual prune.

Volumes are unaffected (`prevent_destroy`), and `tofu apply` recreates the
container, so the damage is downtime rather than data loss. Avoid planning during
the backup window, and check `docker ps -a --filter status=exited` first. Later
provider versions only flag the drift in state instead of deleting; upgrading off
3.9.0 is the actual fix.

### Config that carries a secret uses `upload`, not the image

Configuration is normally baked into a custom image, because the Docker host is
remote and a bind mount would need the file to exist there. A `docker_image`
build context is static files on disk, though, so no Terraform variable can reach
it. Config that interpolates a variable therefore arrives as an `upload` block at
container-create time, which also keeps the value out of an image layer.

`docker_container.alertmanager` is the worked example: `alertmanager.yml` is
rendered from `alertmanager/alertmanager.yml.tftpl` with the Telegram chat id and
uploaded, and the bot token is a second upload read via `bot_token_file`. Contrast
`prometheus.yml` and `alerts.yml`, which hold no secrets and stay baked into
`prometheus/Dockerfile`.

Note that `templatefile()` in `compute_monitoring.tf` uses `path.cwd`, so tofu
must be run from inside `tf/`.

### Manual backup
```bash
docker run --rm \
  --env BACKUP_FILENAME=homeserver-backup-%Y%m%d-%H%M%S.tar.gz \
  --env BACKUP_STOP_DURING_BACKUP_LABEL=backup.stop \
  --env BACKUP_EXCLUDE_REGEXP='^/backup/tmp/' \
  -v nextcloud_db:/backup/postgresql:ro \
  -v nextcloud_nextcloud:/backup/nextcloud:ro \
  -v nextcloud_immich_upload:/backup/immich_upload:ro \
  -v nextcloud_immich_postgres:/backup/immich_postgres:ro \
  -v /mnt/backups:/archive \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --entrypoint backup \
  offen/docker-volume-backup:latest
```

### Restore a volume
```bash
# Stop affected containers first
ssh kcfam docker stop <container_names>

# Remove and restore volume
ssh kcfam docker volume rm nextcloud_<volume_name>
docker run --rm \
  -v nextcloud_<volume_name>:/backup/<path> \
  -v /mnt/backups:/archive \
  --entrypoint tar \
  offen/docker-volume-backup:latest \
  -xvzf /archive/homeserver-backup-YYYYMMDD-HHMMSS.tar.gz -C / --overwrite backup/<path>

# Redeploy
cd tf && tofu apply
```

## k3s side

Services are moving to the k3s cluster on the same host, synced by the gtfs
ArgoCD from this repo's `main` branch.

- `apps/home-root.yaml` is the app of apps (applied once by hand); every other
  file in `apps/` is an Application for one `home/<dir>`.
- Secrets are `home/**/*.enc.yaml`, encrypted to the age key in `.sops.yaml`.
  The private key is `age.key` (gitignored) and also sits in the `argocd/sops-age`
  Secret alongside the gtfs key. Render before committing:
  `PATH="$HOME/.local/bin:$PATH" SOPS_AGE_KEY_FILE=$PWD/age.key kustomize build --enable-alpha-plugins --enable-exec home/<dir>`
- New services serve `<name>.new.kcfam.us` first (wildcard cert in `home/base`,
  passthrough in `traefik/dynamic/kcfam-new-passthrough.yml`). A cutover is one
  per-host passthrough file `docker cp`'d into the `traefik` container.
- DNS: `home-external-dns` (values in `home/external-dns`) manages `kcfam.us`
  records only. An IngressRoute gets a CNAME to the apex by carrying
  `external-dns.alpha.kubernetes.io/target: kcfam.us`. Records it did not
  create are left alone; never declare the apex.
- Immich runs in `home` (`home/immich`) and owns `im.kcfam.us` via
  `traefik/dynamic/kcfam-im-passthrough.yml`. Originals are hardlinks under
  `/srv/photos` (mounted read-write, so deletes remove the file),
  uploads/thumbnails in `/srv/immich/upload`.
  The Docker `immich_server` and `immich_microservices` are stopped by hand with
  restart policy `no`, kept as the rollback until decommission;
  `immich_postgres` and `immich_machine_learning` still run.
- Files: `home/files` runs Syncthing (sync on host port 22000; GUI only by
  ssh tunnel, see `home/files/syncthing.yaml`) and File Browser Quantum (`files.new.kcfam.us`) over
  `/srv/files/{maxtkc,stkchristy,shared}`, all uid 1000. File Browser users and
  source access live in its database (PVC), not the ConfigMap.
  `migration/files-rsync.sh` copies Nextcloud user files in and compares sha256
  manifests.
- Files cut over 2026-10-07: `files.kcfam.us` and `nc.kcfam.us` (a pointer page,
  `home/nc-pointer`) pass through to k3s. Nextcloud is in maintenance mode and
  `nextcloud-web` is stopped by hand with restart policy `no` (its Traefik router
  otherwise beats the passthrough); `nextcloud`, `nextcloud-cron`, `db`, `redis`
  still run as the rollback.
- `home/backup` runs restic into the same `/mnt/backups/restic` repo as
  `restic-data`, as host `home-k8s`, daily 03:30, with a 5% read check Saturdays
  at 05:00. It `pg_dump`s the Immich DB to `/srv/backup-dumps` first.

## Network Architecture

- **proxy-tier**: External-facing services (Traefik, Sablier, GrampsWeb, Immich)
- **internal**: Internal service communication (DB, Redis, app containers)

The k3s Immich mounts `/srv/photos` read-write. Those files are hardlinks into the
Nextcloud volume, so a delete in Immich removes only the `/srv/photos` link.

## Pending: tgtg state drift

`tgtg` and `gluetun` were created by hand on the host, not through tofu, because
the state was not on the machine doing the work (2026-10-01, then again on
2026-10-07). The host matches the config in `tf/`; the state does not.

Current host state:
- `tgtg`: hand-made, **running**, on `kcfam/tgtg:local` (the fork with travel
  mode, built with `docker -H ssh://kcfam build -f docker/Dockerfile.alpine`) with
  the tofu env plus `SLEEP_TIME=180`, `METRICS=true`, `METRICS_PORT=8000`,
  `PRICE_MONITORING=true`, `HTTPS_PROXY=http://gluetun:8888`,
  `NO_PROXY=api.telegram.org,localhost,gluetun` and `GLUETUN_API_KEY`. Same volume
  and networks as the tofu definition. **Not in tofu state.** The previous fork
  build is tagged `kcfam/tgtg:prev-20261007` as a rollback.
- `gluetun`: hand-made, `qmcgaw/gluetun:v3.41.3`, NordVPN WireGuard exiting in the
  United States, on `internal` only. **Not in tofu state.**
- `prometheus`: still the container in state, but `prometheus.yml` and
  `alerts.yml` were copied in and hot-reloaded (`/-/reload`) instead of rebuilding
  the image. The next apply rebuilds `docker_image.prometheus` with the same files.
- `tgtg_old_v1.25`: the container tofu state still points at (stopped, restart
  `no`). Kept only as a rollback.
- `tgtg_prev_upstream`: the 2026-10-07 container on `derhenning/tgtg:v1.26.0-alpine`
  (stopped, restart `no`). Rollback for the fork image.
- In `nextcloud_tgtg_tokens`, DataDome cookies from the blocked IPs are parked as
  `datadome.bak-20261001` and `datadome.bak-20261007-homeip`.
- The NordVPN access token, NordLynx private key and gluetun control API key are in
  `~/tfstate/home-tf/nordvpn.secrets` on kcfam (mode 600, tfvars format).

To reconcile:
1. Append `nordvpn.secrets` (minus `nordvpn_access_token`, which is not a tf
   variable) to `secrets.auto.tfvars`, and set `tgtg_use_vpn = true`,
   `tgtg_sleep_time = 180`, `nordvpn_server_countries = "United States"`, and
   `tgtg_fork_path` to a checkout of the fork's `travel-mode` branch.
2. `ssh kcfam docker rm -f tgtg gluetun tgtg_old_v1.25 tgtg_prev_upstream`. Only the
   containers go; the tokens live in the `prevent_destroy` volume.
3. `cd tf && tofu apply`. It recreates `docker_container.tgtg` and creates
   `docker_container.gluetun` from config.

If `tgtg_old_v1.25` is left in place, the refresh will delete it anyway (stopped +
`must_run`, see "`tofu plan` deletes stopped containers"). If the hand-made `tgtg`
or `gluetun` is left in place, the apply fails on the name conflict.

Why tgtg goes through gluetun: TGTG's DataDome anti-bot layer returned 403
captcha interstitials to the home IP from 2026-09-25 on. A custom
`TGTG_USER_AGENT`, `TGTG_APK_VERSION=26.2.10`, a fresh DataDome cookie and a
four-day cool-off (still 403 on 2026-10-05) did not help. Through the NordVPN exit
on 2026-10-07, with a fresh cookie, scanning worked on the first try. If the VPN IP
gets blocked too, the bot says so and offers buttons; `/vpn new` (same country) or
`/vpn Germany` moves the exit through the gluetun control server and parks the
`datadome` file. A country change made this way lasts until gluetun restarts;
`nordvpn_server_countries` is the persistent default. Don't rotate on a schedule:
DataDome binds its cookie to the IP.

Related: floating tags like `latest-alpine` are never re-pulled, because
`docker_container.image` is a plain string and the provider only pulls when the
image is missing locally. That is how tgtg sat on v1.25 for seven weeks after
v1.26 shipped. Pin explicit versions.

Once reconciled, delete this section.
