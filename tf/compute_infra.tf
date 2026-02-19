resource "docker_container" "db" {
  name    = "nextcloud_db_1"
  image   = "postgres:${var.postgres_version}"
  restart = "always"

  env = [
    "POSTGRES_DB=${local.nextcloud_db_name}",
    "POSTGRES_USER=${local.nextcloud_db_user}",
    "POSTGRES_PASSWORD=${var.db_password}",
  ]

  volumes {
    volume_name    = docker_volume.db.name
    container_path = "/var/lib/postgresql/data"
  }

  networks_advanced {
    name    = docker_network.default.name
    aliases = ["db"]
  }

  labels {
    label = "backup.stop"
    value = "true"
  }
}

resource "docker_container" "redis" {
  name    = "nextcloud_redis_1"
  image   = "redis:${var.redis_version}"
  restart = "always"

  networks_advanced {
    name    = docker_network.default.name
    aliases = ["redis"]
  }

  labels {
    label = "backup.stop"
    value = "true"
  }
}

resource "docker_container" "traefik" {
  name    = "nextcloud_traefik_1"
  image   = docker_image.traefik.image_id
  restart = "always"

  env = [
    "PORKBUN_API_KEY=${var.porkbun_api_key}",
    "PORKBUN_SECRET_API_KEY=${var.porkbun_secret_api_key}",
  ]

  ports {
    internal = 80
    external = 80
  }

  ports {
    internal = 443
    external = 443
  }

  ports {
    internal = 8080
    external = 8080
    ip       = "127.0.0.1"
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  volumes {
    volume_name    = docker_volume.traefik_letsencrypt.name
    container_path = "/letsencrypt"
    read_only      = false
  }

  networks_advanced {
    name = docker_network.proxy_tier.name
  }
}

resource "docker_container" "sablier" {
  name    = "nextcloud_sablier_1"
  image   = "ghcr.io/sablierapp/sablier:${var.sablier_version}"
  restart = "always"

  command = [
    "start",
    "--provider.name=docker",
    "--server.port=10000",
    "--logging.level=info",
  ]

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
    read_only      = true
  }

  networks_advanced {
    name    = docker_network.proxy_tier.name
    aliases = ["sablier"]
  }

  networks_advanced {
    name    = docker_network.default.name
    aliases = ["sablier"]
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.sablier.rule"
    value = "Host(`sablier.kcfam.us`)"
  }

  labels {
    label = "traefik.http.routers.sablier.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.sablier.tls.certresolver"
    value = "letsencrypt"
  }

  labels {
    label = "traefik.http.services.sablier.loadbalancer.server.port"
    value = "10000"
  }
}
