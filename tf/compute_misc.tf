
resource "docker_container" "backup" {
  name    = "nextcloud_backup_1"
  image   = "offen/docker-volume-backup:${var.docker_volume_backup_version}"
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
  image   = "offen/docker-volume-backup:${var.docker_volume_backup_version}"
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
  image   = "offen/docker-volume-backup:${var.docker_volume_backup_version}"
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

