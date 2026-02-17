resource "docker_container" "app" {
  name    = "nextcloud_app_1"
  image   = docker_image.nextcloud.image_id
  restart = "always"

  env = [
    "POSTGRES_HOST=db",
    "POSTGRES_DB=${local.nextcloud_db_name}",
    "POSTGRES_USER=${local.nextcloud_db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
    "REDIS_HOST=redis",
    "PHP_MEMORY_LIMIT=1024M",
  ]

  volumes {
    volume_name    = docker_volume.nextcloud.name
    container_path = "/var/www/html"
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  mounts {
    target = "/tmp"
    type   = "tmpfs"
  }

  networks_advanced {
    name    = docker_network.default.name
    aliases = ["app"]
  }

  labels {
    label = "backup.stop"
    value = "true"
  }

  depends_on = [docker_container.db, docker_container.redis]
}

resource "docker_container" "web" {
  name    = "nextcloud_web_1"
  image   = docker_image.nextcloud_web.image_id
  restart = "always"

  volumes {
    volume_name    = docker_volume.nextcloud.name
    container_path = "/var/www/html"
    read_only      = true
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
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.nextcloud.rule"
    value = "Host(`nc.kcfam.us`)"
  }

  labels {
    label = "traefik.http.routers.nextcloud.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.nextcloud.tls.certresolver"
    value = "letsencrypt"
  }

  labels {
    label = "traefik.http.services.nextcloud.loadbalancer.server.port"
    value = "80"
  }

  depends_on = [docker_container.app]
}

resource "docker_container" "cron" {
  name       = "nextcloud_cron_1"
  image      = docker_container.app.image
  restart    = "always"
  entrypoint = ["/cron.sh"]

  volumes {
    volume_name    = docker_volume.nextcloud.name
    container_path = "/var/www/html"
  }

  networks_advanced {
    name = docker_network.default.name
  }

  labels {
    label = "backup.stop"
    value = "true"
  }

  depends_on = [docker_container.db, docker_container.redis]
}
