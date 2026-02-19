resource "docker_container" "static_sites" {
  name    = "static-sites"
  image   = docker_image.static_sites.image_id
  restart = "unless-stopped"

  networks_advanced {
    name = docker_network.proxy_tier.name
  }

  volumes {
    volume_name    = docker_volume.static_sites.name
    container_path = "/sites"
    read_only      = true
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.static-sites.rule"
    value = join(" || ", [for s in var.static_sites : "Host(`${s}.${local.domain}`)"])
  }
  labels {
    label = "traefik.http.routers.static-sites.entrypoints"
    value = "websecure"
  }
  labels {
    label = "traefik.http.routers.static-sites.tls"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.static-sites.tls.certresolver"
    value = "letsencrypt"
  }
  labels {
    label = "traefik.http.services.static-sites.loadbalancer.server.port"
    value = "80"
  }
}
