# home-docker

Home server stack managed with OpenTofu, deploying Docker containers to a remote host over SSH (`ssh://kcfam`).

## Services

| Service | URL | Notes |
|---------|-----|-------|
| Nextcloud | nc.kcfam.us | Custom build with ffmpeg, exiftool, imagemagick |
| Immich | im.kcfam.us | Photo management with AI/ML |
| GrampsWeb | gramps.kcfam.us | Genealogy, auto-scales with Sablier |
| Grafana | gf.kcfam.us | Metrics dashboards |
| Uptime Kuma | uptime.kcfam.us | Status monitoring at status.kcfam.us |
| Forgejo | git.kcfam.us | Git hosting with CI/CD runner |
| OpenProject | op.kcfam.us | Project management (toggleable) |
| TGTG | tgtg.kcfam.us | Too Good To Go notifier |

## Infrastructure

- **Traefik v3** — reverse proxy and Let's Encrypt SSL
- **Sablier** — auto-scales low-traffic services (spin down after 1 min idle)
- **Prometheus + Grafana** — metrics and dashboards
- **Uptime Kuma** — health monitoring and public status page at status.kcfam.us

## External Dependencies

- Porkbun — DNS management (managed via Terraform)
- Let's Encrypt — TLS certificates (via Traefik)
- Remote host `kcfam` — Docker runs here, accessed over SSH

## Deployment

Infrastructure is defined in `tf/`. Monitors are in `tf-monitors/`.

```bash
cd tf
tofu plan
tofu apply
```

Custom images (Nextcloud, Traefik, Prometheus, Grafana, nginx) are baked with config files rather than volume-mounted, since the Docker host is remote. Rebuild with:

```bash
tofu apply -replace=docker_image.nextcloud
```

Secrets go in `secrets.auto.tfvars` (gitignored) in each module directory.
