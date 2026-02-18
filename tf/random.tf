resource "random_password" "grafana_admin" {
  length  = 32
  special = false
}

resource "random_password" "forgejo_secret_key" {
  length  = 64
  special = false
}

