resource "docker_container" "nanomq" {
  name    = "nanomq"
  image   = "emqx/nanomq:latest"
  restart = "always"

  networks_advanced {
    name = docker_network.proxy_tier.name
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  # ── MQTT TCP (TLS terminated by Traefik on 443, SNI routing) ────────────────
  labels {
    label = "traefik.tcp.routers.nanomq-mqtt.rule"
    value = "HostSNI(`mqtt.kcfam.us`)"
  }

  labels {
    label = "traefik.tcp.routers.nanomq-mqtt.entrypoints"
    value = "websecure"
  }

  labels {
    label = "traefik.tcp.routers.nanomq-mqtt.tls"
    value = "true"
  }

  labels {
    label = "traefik.tcp.routers.nanomq-mqtt.tls.certresolver"
    value = "letsencrypt"
  }

  labels {
    label = "traefik.tcp.services.nanomq-mqtt.loadbalancer.server.port"
    value = "1883"
  }

  # ── MQTT WebSocket — wss:// on port 443 ─────────────────────────────────────
  labels {
    label = "traefik.http.routers.nanomq-ws.rule"
    value = "Host(`ws.mqtt.kcfam.us`)"
  }

  labels {
    label = "traefik.http.routers.nanomq-ws.entrypoints"
    value = "websecure"
  }

  labels {
    label = "traefik.http.routers.nanomq-ws.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.nanomq-ws.tls.certresolver"
    value = "letsencrypt"
  }

  labels {
    label = "traefik.http.services.nanomq-ws.loadbalancer.server.port"
    value = "8083"
  }
}
