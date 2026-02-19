# All named volumes. prevent_destroy guards against accidental data loss.
# Volume names follow the pattern <project>_<volume> (project = "nextcloud").
# Labels are managed by Docker Compose and ignored here to avoid forced replacements.

resource "docker_volume" "db" {
  name = "nextcloud_db"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "nextcloud" {
  name = "nextcloud_nextcloud"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "traefik_letsencrypt" {
  name = "nextcloud_traefik_letsencrypt"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "gramps_users" {
  name = "nextcloud_gramps_users"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "gramps_index" {
  name = "nextcloud_gramps_index"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "gramps_thumb_cache" {
  name = "nextcloud_gramps_thumb_cache"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "gramps_cache" {
  name = "nextcloud_gramps_cache"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "gramps_secret" {
  name = "nextcloud_gramps_secret"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "gramps_db" {
  name = "nextcloud_gramps_db"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "gramps_media" {
  name = "nextcloud_gramps_media"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "gramps_tmp" {
  name = "nextcloud_gramps_tmp"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "immich_upload" {
  name = "nextcloud_immich_upload"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "immich_postgres" {
  name = "nextcloud_immich_postgres"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "model_cache" {
  name = "nextcloud_model_cache"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "uptime_kuma" {
  name = "nextcloud_uptime_kuma"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "grafana_data" {
  name = "nextcloud_grafana_data"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "prometheus_data" {
  name = "nextcloud_prometheus_data"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "forgejo_data" {
  name = "nextcloud_forgejo_data"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "forgejo_runner_data" {
  name = "nextcloud_forgejo_runner_data"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}

resource "docker_volume" "static_sites" {
  name = "nextcloud_static_sites"

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}
