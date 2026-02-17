resource "docker_network" "proxy_tier" {
  # Preserve existing name to reuse containers' network membership
  name = "nextcloud_proxy-tier"
}

resource "docker_network" "default" {
  name = "nextcloud_default"
}
