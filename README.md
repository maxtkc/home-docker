# kcfam-infra

The `kcfam.us` home server: Kubernetes manifests synced by ArgoCD into the k3s
cluster on `kcfam`.

## Services

| Service | URL | Where |
|---------|-----|-------|
| Immich | im.kcfam.us | `home/immich` |
| File Browser Quantum, Syncthing | files.kcfam.us | `home/files` |
| GrampsWeb | gramps.kcfam.us | `home/grampsweb` |
| Grafana, Prometheus, Alertmanager | gf.kcfam.us | `home/monitoring` |
| Gatus | status.kcfam.us | `home/gatus` |
| cors-anywhere | cors.kcfam.us | `home/cors-proxy` |
| tgtg notifier, gluetun | (no hostname) | `home/tgtg` |
| restic backups (local + B2) | | `home/backup` |
| Personal site | max.kcfam.us | GitHub Pages (`maxtkc/personal-site`) |

## Layout

- `apps/`: ArgoCD Applications. `apps/home-root.yaml` is the app of apps; every
  other file deploys one `home/<dir>`.
- `home/`: manifests, one directory per service, namespace `home`. Secrets are
  SOPS files (`*.enc.yaml`).
- `migration/`: scripts and baselines from the move off Docker/Nextcloud.

## Deployment

Commit and push to `main`; ArgoCD syncs.
