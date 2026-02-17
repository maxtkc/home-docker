resource "random_password" "grafana_admin" {
  length  = 32
  special = false
}

