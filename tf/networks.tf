resource "docker_network" "proxy_tier" {
  name = "proxy-tier"
}

resource "docker_network" "default" {
  name = "internal"
}

resource "docker_network" "runner_tier" {
  name = "runner-tier"
}
