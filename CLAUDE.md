# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Architecture

This is a Docker Compose-based home server setup that runs multiple services behind an nginx reverse proxy with Let's Encrypt SSL certificates. The stack consists of:

- **Nextcloud**: A custom-built Nextcloud instance (my_nc/) with ffmpeg, exiftool, and imagemagick support
- **PostgreSQL + Redis**: Database and caching layer for Nextcloud and shared by other services
- **nginx Reverse Proxy**: Custom nginx proxy (proxy/) with large file upload support (10GB max)
- **GrampsWeb**: Family tree/genealogy application with Celery workers and Redis
- **Immich**: Self-hosted photo and video management with AI features, machine learning, and microservices
- **Let's Encrypt**: Automatic SSL certificate management

The proxy handles all external traffic and routes to internal services based on virtual hosts:
- nc.kcfam.us → Nextcloud
- gramps.kcfam.us → GrampsWeb
- im.kcfam.us → Immich

## Key Components

- **docker-compose.yml**: Main orchestration file defining all services, networks, and volumes
- **db.env**: PostgreSQL credentials (contains sensitive data)
- **immich.env**: Immich configuration and credentials
- **my_nc/Dockerfile**: Custom Nextcloud build with additional media processing tools
- **proxy/Dockerfile**: nginx-proxy with custom upload size configuration
- **web/Dockerfile**: nginx web server with Nextcloud-specific configuration

## Common Commands

Start all services:
```bash
docker compose up -d
```

View logs for specific service:
```bash
docker compose logs -f [service_name]
```

Rebuild and restart a service:
```bash
docker compose build [service_name]
docker compose up -d [service_name]
```

Stop all services:
```bash
docker compose down
```

## Backup and Restore

The setup includes automated backups using [docker-volume-backup](https://offen.github.io/docker-volume-backup/) that run daily at 2 AM to `/mnt/backups`.

### Backup Operations

Manual backup:
```bash
# Using docker run (recommended)
docker run --rm \
  --env BACKUP_FILENAME=homeserver-backup-%Y%m%d-%H%M%S.tar.gz \
  --env BACKUP_STOP_DURING_BACKUP_LABEL=backup.stop \
  --env BACKUP_EXCLUDE_REGEXP='^/backup/tmp/' \
  -v home-docker_db:/backup/postgresql:ro \
  -v home-docker_nextcloud:/backup/nextcloud:ro \
  -v home-docker_gramps_users:/backup/gramps_users:ro \
  -v home-docker_gramps_index:/backup/gramps_index:ro \
  -v home-docker_gramps_thumb_cache:/backup/gramps_thumb_cache:ro \
  -v home-docker_gramps_cache:/backup/gramps_cache:ro \
  -v home-docker_gramps_secret:/backup/gramps_secret:ro \
  -v home-docker_gramps_db:/backup/gramps_db:ro \
  -v home-docker_gramps_media:/backup/gramps_media:ro \
  -v home-docker_immich_upload:/backup/immich_upload:ro \
  -v home-docker_immich_postgres:/backup/immich_postgres:ro \
  -v /mnt/backups:/archive \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --entrypoint backup \
  offen/docker-volume-backup:latest

# Alternative using docker compose (may have lock issues)
docker compose run --rm --entrypoint backup backup
```

View backup files:
```bash
ls -la /mnt/backups/
```

List contents of a backup:
```bash
docker compose run --rm backup tar -tzf /archive/homeserver-backup-YYYYMMDD-HHMMSS.tar.gz
```

### Restore Operations

**⚠️ IMPORTANT: Always stop services before restoring to prevent data corruption!**

**Lessons learned from testing:**
- Use the backup container's tar (GNU tar) instead of Alpine's BusyBox tar for large files
- Alpine's tar may fail with exit code 125 on large compressed files
- Always verify backup file size - empty backups indicate the volumes were empty when backed up
- Stop all services that use the volumes before restoring
- Check timestamps after restore to verify data was actually replaced

**Full system restore:**
```bash
# Stop all services
docker compose down

# Remove volumes to restore (WARNING: DESTRUCTIVE!)
docker volume rm home-docker_db home-docker_nextcloud home-docker_gramps_users home-docker_gramps_db home-docker_gramps_media home-docker_immich_upload home-docker_immich_postgres

# Restore from backup (use backup container's tar, NOT alpine)
docker run --rm \
  -v home-docker_db:/backup/postgresql \
  -v home-docker_nextcloud:/backup/nextcloud \
  -v home-docker_gramps_users:/backup/gramps_users \
  -v home-docker_gramps_db:/backup/gramps_db \
  -v home-docker_gramps_media:/backup/gramps_media \
  -v home-docker_immich_upload:/backup/immich_upload \
  -v home-docker_immich_postgres:/backup/immich_postgres \
  -v /mnt/backups:/archive \
  --entrypoint tar \
  offen/docker-volume-backup:latest \
  -xvzf /archive/homeserver-backup-YYYYMMDD-HHMMSS.tar.gz -C / --overwrite

# Restart services
docker compose up -d
```

**Selective restore (Nextcloud only):**
```bash
docker compose stop app web cron
docker run --rm \
  -v home-docker_nextcloud:/backup/nextcloud \
  -v /mnt/backups:/archive \
  --entrypoint tar \
  offen/docker-volume-backup:latest \
  -xvzf /archive/homeserver-backup-YYYYMMDD-HHMMSS.tar.gz -C / --overwrite backup/nextcloud
docker compose up -d app web cron
```

**Database-only restore:**
```bash
docker compose stop db app cron
docker volume rm home-docker_db
docker run --rm \
  -v home-docker_db:/backup/postgresql \
  -v /mnt/backups:/archive \
  --entrypoint tar \
  offen/docker-volume-backup:latest \
  -xvzf /archive/homeserver-backup-YYYYMMDD-HHMMSS.tar.gz -C / --overwrite backup/postgresql
docker compose up -d
```

## Network Architecture

- **proxy-tier network**: Connects external-facing services (web, proxy, letsencrypt-companion, grampsweb, immich_server)
- **default network**: Internal communication between application services
- All services use named volumes for persistent data storage

## Security Notes

- PostgreSQL credentials are stored in db.env and Immich credentials in immich.env (excluded from version control)
- Services run with restart policies for high availability
- nginx configured with security headers and hidden server tokens
- Docker socket access is read-only where possible
- Immich has read-only access to Nextcloud data for photo management integration