resource "docker_container" "openproject" {
  name    = "openproject"
  image   = "openproject/openproject:16"
  restart = "always"

  env = [
    "OPENPROJECT_SECRET_KEY_BASE=${random_password.openproject_secret_key_base.result}",
    "OPENPROJECT_HOST__NAME=op.kcfam.us",
    "OPENPROJECT_HTTPS=true",
    "OPENPROJECT_DEFAULT__LANGUAGE=en",
    "OPENPROJECT_RAILS__SESSION__STORE=active_record_store",
    "OPENPROJECT_SESSION__TTL__ENABLED=true",
    "OPENPROJECT_SESSION__TTL=28800",
    "OPENPROJECT_DROP__OLD__SESSIONS__ON__LOGIN=false",
  ]

  volumes {
    volume_name    = docker_volume.openproject_data.name
    container_path = "/var/openproject/assets"
  }

  volumes {
    volume_name    = docker_volume.openproject_pgdata.name
    container_path = "/var/openproject/pgdata"
  }

  networks_advanced {
    name = docker_network.proxy_tier.name
  }

  networks_advanced {
    name = docker_network.default.name
  }

  healthcheck {
    test         = ["CMD", "curl", "-f", "http://localhost:80/health_checks/default"]
    interval     = "30s"
    timeout      = "10s"
    retries      = 3
    start_period = "2m0s"
  }

  labels {
    label = "backup.stop"
    value = "true"
  }

  labels {
    label = "sablier.enable"
    value = "true"
  }

  labels {
    label = "sablier.group"
    value = "openproject"
  }

  labels {
    label = "sablier.group.openproject.session_duration"
    value = "15m"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.openproject.rule"
    value = "Host(`op.kcfam.us`)"
  }

  labels {
    label = "traefik.http.routers.openproject.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.openproject.tls.certresolver"
    value = "letsencrypt"
  }

  labels {
    label = "traefik.http.services.openproject.loadbalancer.server.port"
    value = "80"
  }
}

resource "docker_container" "backup" {
  name    = "nextcloud_backup_1"
  image   = "offen/docker-volume-backup:latest"
  restart = "always"

  env = [
    "BACKUP_FILENAME=homeserver-backup-%Y%m%d-%H%M%S.tar.gz",
    "BACKUP_CRON_EXPRESSION=0 2 * * *",
    "BACKUP_RETENTION_DAYS=1",
    "BACKUP_STOP_DURING_BACKUP_LABEL=backup.stop",
    "BACKUP_EXCLUDE_REGEXP=^/backup/tmp/|\\.tmp$|/backup/immich_upload/backups/",
    "LOG_LEVEL=debug",
    "BACKUP_COMPRESSION=gz",
  ]

  volumes {
    volume_name    = docker_volume.nextcloud.name
    container_path = "/backup/nextcloud"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.immich_upload.name
    container_path = "/backup/immich_upload"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.immich_postgres.name
    container_path = "/backup/immich_postgres"
    read_only      = true
  }

  volumes {
    host_path      = "/mnt/backups"
    container_path = "/archive"
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.default.name
  }
}

resource "docker_container" "backup_weekly" {
  name    = "nextcloud_backup_weekly_1"
  image   = "offen/docker-volume-backup:latest"
  restart = "always"

  env = [
    "BACKUP_FILENAME=homeserver-backup-weekly-%Y%m%d-%H%M%S.tar.gz",
    "BACKUP_CRON_EXPRESSION=0 3 * * 0",
    "BACKUP_RETENTION_DAYS=7",
    "BACKUP_STOP_DURING_BACKUP_LABEL=backup.stop",
    "BACKUP_EXCLUDE_REGEXP=^/backup/tmp/|\\.tmp$|/backup/immich_upload/backups/",
    "LOG_LEVEL=debug",
    "BACKUP_COMPRESSION=gz",
  ]

  volumes {
    volume_name    = docker_volume.nextcloud.name
    container_path = "/backup/nextcloud"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.immich_upload.name
    container_path = "/backup/immich_upload"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.immich_postgres.name
    container_path = "/backup/immich_postgres"
    read_only      = true
  }

  volumes {
    host_path      = "/mnt/backups"
    container_path = "/archive"
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.default.name
  }
}

resource "docker_container" "backup_monthly" {
  name    = "nextcloud_backup_monthly_1"
  image   = "offen/docker-volume-backup:latest"
  restart = "always"

  env = [
    "BACKUP_FILENAME=homeserver-backup-monthly-%Y%m%d-%H%M%S.tar.gz",
    "BACKUP_CRON_EXPRESSION=0 4 1 * *",
    "BACKUP_RETENTION_DAYS=32",
    "BACKUP_STOP_DURING_BACKUP_LABEL=backup.stop",
    "BACKUP_EXCLUDE_REGEXP=^/backup/tmp/|\\.tmp$",
    "LOG_LEVEL=debug",
    "BACKUP_COMPRESSION=gz",
  ]

  volumes {
    volume_name    = docker_volume.db.name
    container_path = "/backup/postgresql"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.gramps_users.name
    container_path = "/backup/gramps_users"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.gramps_index.name
    container_path = "/backup/gramps_index"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.gramps_thumb_cache.name
    container_path = "/backup/gramps_thumb_cache"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.gramps_cache.name
    container_path = "/backup/gramps_cache"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.gramps_secret.name
    container_path = "/backup/gramps_secret"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.gramps_db.name
    container_path = "/backup/gramps_db"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.gramps_media.name
    container_path = "/backup/gramps_media"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.uptime_kuma.name
    container_path = "/backup/uptime_kuma"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/backup/grafana_data"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.prometheus_data.name
    container_path = "/backup/prometheus_data"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.openproject_data.name
    container_path = "/backup/openproject_data"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.openproject_pgdata.name
    container_path = "/backup/openproject_pgdata"
    read_only      = true
  }

  volumes {
    host_path      = "/mnt/backups"
    container_path = "/archive"
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.default.name
  }
}

