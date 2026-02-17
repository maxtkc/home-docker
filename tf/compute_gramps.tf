resource "docker_container" "grampsweb_redis" {
  name    = "grampsweb_redis"
  image   = "docker.io/library/redis:${var.grampsweb_redis_version}"
  restart = "always"

  networks_advanced {
    name = docker_network.default.name
  }

  labels {
    label = "backup.stop"
    value = "true"
  }
}

resource "docker_container" "grampsweb" {
  name    = "grampsweb"
  image   = "ghcr.io/gramps-project/grampsweb:${var.grampsweb_version}"
  restart = "always"

  env = local.grampsweb_env

  volumes {
    volume_name    = docker_volume.gramps_users.name
    container_path = "/app/users"
  }

  volumes {
    volume_name    = docker_volume.gramps_index.name
    container_path = "/app/indexdir"
  }

  volumes {
    volume_name    = docker_volume.gramps_thumb_cache.name
    container_path = "/app/thumbnail_cache"
  }

  volumes {
    volume_name    = docker_volume.gramps_cache.name
    container_path = "/app/cache"
  }

  volumes {
    volume_name    = docker_volume.gramps_secret.name
    container_path = "/app/secret"
  }

  volumes {
    volume_name    = docker_volume.gramps_db.name
    container_path = "/root/.gramps/grampsdb"
  }

  volumes {
    volume_name    = docker_volume.gramps_media.name
    container_path = "/app/media"
  }

  volumes {
    volume_name    = docker_volume.gramps_tmp.name
    container_path = "/tmp"
  }

  networks_advanced {
    name = docker_network.proxy_tier.name
  }

  networks_advanced {
    name = docker_network.default.name
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
    value = "gramps"
  }

  labels {
    label = "sablier.group.gramps.session_duration"
    value = "1m"
  }
}

resource "docker_container" "grampsweb_celery" {
  name    = "grampsweb_celery"
  image   = "ghcr.io/gramps-project/grampsweb:${var.grampsweb_version}"
  restart = "always"

  command = ["celery", "-A", "gramps_webapi.celery", "worker", "--loglevel=INFO"]

  env = local.grampsweb_env

  volumes {
    volume_name    = docker_volume.gramps_users.name
    container_path = "/app/users"
  }

  volumes {
    volume_name    = docker_volume.gramps_index.name
    container_path = "/app/indexdir"
  }

  volumes {
    volume_name    = docker_volume.gramps_thumb_cache.name
    container_path = "/app/thumbnail_cache"
  }

  volumes {
    volume_name    = docker_volume.gramps_cache.name
    container_path = "/app/cache"
  }

  volumes {
    volume_name    = docker_volume.gramps_secret.name
    container_path = "/app/secret"
  }

  volumes {
    volume_name    = docker_volume.gramps_db.name
    container_path = "/root/.gramps/grampsdb"
  }

  volumes {
    volume_name    = docker_volume.gramps_media.name
    container_path = "/app/media"
  }

  volumes {
    volume_name    = docker_volume.gramps_tmp.name
    container_path = "/tmp"
  }

  networks_advanced {
    name = docker_network.default.name
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
    value = "gramps"
  }

  depends_on = [docker_container.grampsweb_redis]
}
