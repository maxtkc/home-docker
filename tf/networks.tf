resource "docker_network" "proxy_tier" {
  name = "proxy-tier"
}

resource "docker_network" "default" {
  name = "internal"
}
