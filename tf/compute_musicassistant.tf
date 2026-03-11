resource "docker_container" "music_assistant" {
  name    = "music-assistant"
  image   = "ghcr.io/music-assistant/server:${var.music_assistant_version}"
  restart = "always"

  env = [
    "TZ=America/Chicago",
  ]

  volumes {
    volume_name    = docker_volume.music_assistant_data.name
    container_path = "/data"
  }

  # Snapcast clients on the LAN connect directly to this port (bypasses Traefik)
  ports {
    internal = 4953
    external = 4953
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
    label = "traefik.http.routers.musicassistant.rule"
    value = "Host(`ma.kcfam.us`)"
  }

  labels {
    label = "traefik.http.routers.musicassistant.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.musicassistant.tls.certresolver"
    value = "letsencrypt"
  }

  labels {
    label = "traefik.http.services.musicassistant.loadbalancer.server.port"
    value = "8095"
  }
}
