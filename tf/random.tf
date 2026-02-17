resource "random_password" "grafana_admin" {
  length  = 32
  special = false
}

resource "random_password" "openproject_secret_key_base" {
  length  = 128
  special = false
}
