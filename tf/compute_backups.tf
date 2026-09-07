
# Databases only, about 1G. File data moved to docker_container.restic_data.
#
# This job exists because resticker cannot stop a container for the duration of
# a backup, and a Postgres data directory copied while the server is writing to
# it is not a backup. BACKUP_STOP_DURING_BACKUP_LABEL is the whole reason offen
# stays.
#
# Runs at 01:30, ahead of restic's 02:00, so the databases are quiesced and
# restarted before the long file run begins.
resource "docker_container" "backup" {
  name    = "backup-daily"
  image   = "offen/docker-volume-backup:${var.docker_volume_backup_version}"
  restart = "always"

  env = [
    # Distinct from the old homeserver-backup-* tarballs, which shared this
    # archive directory and were 188G rather than 1G.
    "BACKUP_FILENAME=homeserver-db-%Y%m%d-%H%M%S.tar.gz",
    "BACKUP_CRON_EXPRESSION=30 1 * * *",
    "BACKUP_RETENTION_DAYS=7",
    "BACKUP_STOP_DURING_BACKUP_LABEL=backup.stop",
    "BACKUP_EXCLUDE_REGEXP=^/backup/tmp/|\\.tmp$",
    "LOG_LEVEL=debug",
    "BACKUP_COMPRESSION=gz",
  ]

  # nextcloud_db was previously only in the monthly job, so a daily file backup
  # had no same-day database to restore alongside it.
  volumes {
    volume_name    = docker_volume.db.name
    container_path = "/backup/nextcloud_db"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.immich_postgres.name
    container_path = "/backup/immich_postgres"
    read_only      = true
  }

  volumes {
    host_path      = "/mnt/backups/tmp"
    container_path = "/tmp"
  }

  volumes {
    host_path      = "/mnt/backups/daily"
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
  name    = "backup-weekly"
  image   = "offen/docker-volume-backup:${var.docker_volume_backup_version}"
  restart = "always"

  env = [
    "BACKUP_FILENAME=homeserver-backup-%Y%m%d-%H%M%S.tar.gz",
    "BACKUP_CRON_EXPRESSION=0 3 * * 0",
    "BACKUP_RETENTION_DAYS=6",
    "BACKUP_STOP_DURING_BACKUP_LABEL=backup.stop",
    "BACKUP_EXCLUDE_REGEXP=^/backup/tmp/|\\.tmp$|\\.log$|/backup/immich_upload/backups/",
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
    host_path      = "/mnt/backups/tmp"
    container_path = "/tmp"
  }

  volumes {
    host_path      = "/mnt/backups/weekly"
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
  name    = "backup-monthly"
  image   = "offen/docker-volume-backup:${var.docker_volume_backup_version}"
  restart = "always"

  env = [
    "BACKUP_FILENAME=homeserver-backup-%Y%m%d-%H%M%S.tar.gz",
    "BACKUP_CRON_EXPRESSION=0 4 1 * *",
    "BACKUP_RETENTION_DAYS=28",
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
    volume_name    = docker_volume.forgejo_data.name
    container_path = "/backup/forgejo_data"
    read_only      = true
  }

  volumes {
    host_path      = "/mnt/backups/tmp"
    container_path = "/tmp"
  }

  volumes {
    host_path      = "/mnt/backups/monthly"
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
