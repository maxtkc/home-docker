# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

This is a home server stack managed with **OpenTofu (Terraform)** deploying Docker containers to a remote SSH host (`ssh://kcfam`). All infrastructure is defined as code in the `tf/` directory. A separate `tf-monitors/` module manages Uptime Kuma health checks.

Services and their routes:
- `nc.kcfam.us` → Nextcloud (custom-built with ffmpeg, exiftool, imagemagick)
- `im.kcfam.us` → Immich (photo management with AI/ML)
- `gramps.kcfam.us` → GrampsWeb (genealogy)
- `gf.kcfam.us` → Grafana (metrics dashboards)
- `uptime.kcfam.us` → Uptime Kuma (status monitoring)
- `op.kcfam.us` → OpenProject (project management)
- `git.kcfam.us` → Forgejo (planned — see forgejo-terraform-plan.md)

**Traefik v3** handles reverse proxying and Let's Encrypt SSL. **Sablier** manages auto-scaling for low-traffic services (GrampsWeb, OpenProject): containers spin down after 1 minute of inactivity and wake on request.

## Terraform Modules

### `tf/` — Main infrastructure
- **providers.tf / terraform.tf**: Docker provider (kreuzwerker/docker v3.9.0) connecting via SSH to remote host
- **variables.tf / secrets.auto.tfvars**: Sensitive values (passwords, API keys) — gitignored
- **locals.tf**: Shared local values
- **networks.tf / volumes.tf**: Docker networks and named volumes (all volumes have `prevent_destroy = true`)
- **images.tf**: Custom Docker image builds (Nextcloud, nginx, Traefik, Prometheus, Grafana)
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

**View container logs (on remote host):**
```bash
ssh kcfam docker logs -f <container_name>
```

**Initialize a module (first time or after provider changes):**
```bash
cd tf          # or tf-monitors
tofu init
```

## Secrets Management

Sensitive values live in `secrets.auto.tfvars` (gitignored) in each module directory. Variable declarations are in `variables.tf`. The `.env` file holds non-sensitive configuration referenced by some containers.

## Backup and Restore

Three automated backup tiers (daily 2 AM, weekly Sunday 3 AM, monthly 1st 4 AM) write `.tar.gz` archives to `/mnt/backups` on the host.

**Lessons learned:**
- Use the backup container's tar (GNU tar), not Alpine's BusyBox tar — Alpine fails with exit code 125 on large files
- Verify backup file size; empty backups mean the volume was empty at backup time
- Always stop services using a volume before restoring it
- Check timestamps after restore to confirm data was replaced

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

## Network Architecture

- **nextcloud_proxy-tier**: External-facing services (Traefik, Sablier, GrampsWeb, Immich, OpenProject)
- **nextcloud_default**: Internal service communication (DB, Redis, app containers)

Immich has **read-only** access to the Nextcloud volume for photo library integration.
