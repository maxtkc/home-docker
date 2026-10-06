# NordVPN tunnel used as an outbound HTTP proxy. Containers opt in with
# HTTPS_PROXY=http://gluetun:8888; nothing else is routed through it.
# Only created when the NordLynx private key is set.
#
# The control server on :8000 reconnects to a new server with
#   PUT /v1/vpn/status {"status":"stopped"} then {"status":"running"}
# using header X-API-Key: var.gluetun_control_apikey.
resource "docker_container" "gluetun" {
  count   = var.nordvpn_wireguard_private_key != null ? 1 : 0
  name    = "gluetun"
  image   = "qmcgaw/gluetun:${var.gluetun_version}"
  restart = "always"

  capabilities {
    add = ["NET_ADMIN"]
  }

  devices {
    host_path      = "/dev/net/tun"
    container_path = "/dev/net/tun"
  }

  env = [
    "VPN_SERVICE_PROVIDER=nordvpn",
    "VPN_TYPE=wireguard",
    "WIREGUARD_PRIVATE_KEY=${var.nordvpn_wireguard_private_key}",
    "SERVER_COUNTRIES=${var.nordvpn_server_countries}",
    "HTTPPROXY=on",
    "HTTP_CONTROL_SERVER_AUTH_DEFAULT_ROLE=${jsonencode({ auth = "apikey", apikey = var.gluetun_control_apikey })}",
    "TZ=${coalesce(var.tgtg_tz, "UTC")}",
  ]

  networks_advanced {
    name = docker_network.default.name
  }
}
