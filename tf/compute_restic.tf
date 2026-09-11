# restic file backups, replacing the daily 188G offen tarball.
#
# restic dedups against the existing repository and streams into it, so there is
# no monolithic staging file that can fill a disk. This is the container that
# makes the Phase 2 /tmp workaround unnecessary for file data.
#
# BACKUP_CRON and CHECK_CRON are SIX-field expressions with SECONDS FIRST
# (resticker ships a customised go-cron). The five-field form the offen
# containers use is accepted here and silently schedules the wrong time.
#
# Databases are deliberately NOT backed up here: resticker has no equivalent of
# offen's BACKUP_STOP_DURING_BACKUP_LABEL, so a live Postgres data directory
# would be copied mid-write. docker_container.backup keeps that job.
resource "docker_container" "restic_data" {
  name    = "restic-data"
  image   = "mazzolino/restic:${var.restic_version}"
  restart = "always"

  env = [
    "RESTIC_REPOSITORY=/mnt/backups/restic",
    "RESTIC_PASSWORD=${var.restic_password}",
    "RESTIC_BACKUP_SOURCES=/data/nextcloud /data/immich_upload",
    "RESTIC_BACKUP_ARGS=--tag homeserver --exclude *.log --verbose",
    "RESTIC_FORGET_ARGS=--prune --keep-daily 7 --keep-weekly 4 --keep-monthly 6",
    "BACKUP_CRON=0 0 2 * * *",
    # Feeds node-exporter's textfile collector so BackupStale can alert on a
    # backup that stopped running. Written to a temp file and moved into place
    # because the collector reads whole files and would otherwise catch a
    # half-written one.
    "POST_COMMANDS_SUCCESS={ echo '# HELP homeserver_backup_last_success_timestamp_seconds Unix time of the last fully successful restic backup.'; echo '# TYPE homeserver_backup_last_success_timestamp_seconds gauge'; echo homeserver_backup_last_success_timestamp_seconds $(date +%s); } > /textfile/restic.prom.tmp && mv /textfile/restic.prom.tmp /textfile/restic.prom",
  ]

  volumes {
    volume_name    = docker_volume.nextcloud.name
    container_path = "/data/nextcloud"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.immich_upload.name
    container_path = "/data/immich_upload"
    read_only      = true
  }

  # The repository lives here; the path must match RESTIC_REPOSITORY.
  volumes {
    host_path      = "/mnt/backups"
    container_path = "/mnt/backups"
  }

  volumes {
    volume_name    = docker_volume.textfile_collector.name
    container_path = "/textfile"
  }

  networks_advanced {
    name = docker_network.default.name
  }
}

# resticker rejects BACKUP_CRON and CHECK_CRON in the same container ("mutually
# exclusive ... Exiting"), so the weekly integrity check runs as its own
# container against the same repository. Sundays at 05:00, after the 02:00
# backup.
#
# Six-field cron with SECONDS FIRST, same as restic_data.
resource "docker_container" "restic_check" {
  name    = "restic-check"
  image   = "mazzolino/restic:${var.restic_version}"
  restart = "always"

  env = [
    "RESTIC_REPOSITORY=/mnt/backups/restic",
    "RESTIC_PASSWORD=${var.restic_password}",
    "CHECK_CRON=0 0 5 * * 0",
    # restic_data owns initialization. Two containers racing to init the same
    # repository can corrupt it, which is what resticker's docs warn about.
    "SKIP_INIT=true",
  ]

  # Repository only; the check reads the repo, never the source data.
  volumes {
    host_path      = "/mnt/backups"
    container_path = "/mnt/backups"
  }

  networks_advanced {
    name = docker_network.default.name
  }
}
