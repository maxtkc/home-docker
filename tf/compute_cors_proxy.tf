resource "docker_container" "cors_proxy" {
  name    = "cors-proxy"
  image   = docker_image.cors_proxy.image_id
  restart = "unless-stopped"

  env = [
    "PORT=8080",
    "CORS_ALLOWED_ORIGINS=${join(",", var.cors_proxy_allowed_origins)}",
  ]

  networks_advanced {
    name = docker_network.proxy_tier.name
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.cors-proxy.rule"
    value = join(" || ", concat(
      ["Host(`cors.${local.domain}`)"],
      [for subdomain, domain in var.cors_proxy_domain_records : "Host(`${subdomain}.${domain}`)"],
    ))
  }
  labels {
    label = "traefik.http.routers.cors-proxy.entrypoints"
    value = "websecure"
  }
  labels {
    label = "traefik.http.routers.cors-proxy.tls"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.cors-proxy.tls.certresolver"
    value = "letsencrypt"
  }
  labels {
    label = "traefik.http.services.cors-proxy.loadbalancer.server.port"
    value = "8080"
  }
}
