resource "docker_container" "homeassistant" {
  name    = "homeassistant"
  image   = "ghcr.io/home-assistant/home-assistant:${var.homeassistant_version}"
  restart = "always"

  env = [
    "TZ=America/Chicago",
  ]

  volumes {
    volume_name    = docker_volume.homeassistant_config.name
    container_path = "/config"
  }

  volumes {
    host_path      = "/etc/localtime"
    container_path = "/etc/localtime"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.proxy_tier.name
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
    label = "traefik.http.routers.homeassistant.rule"
    value = "Host(`ha.kcfam.us`)"
  }

  labels {
    label = "traefik.http.routers.homeassistant.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.homeassistant.tls.certresolver"
    value = "letsencrypt"
  }

  labels {
    label = "traefik.http.services.homeassistant.loadbalancer.server.port"
    value = "8123"
  }
}
