resource "random_password" "grafana_admin" {
  length  = 32
  special = false
}

resource "random_password" "forgejo_secret_key" {
  length  = 64
  special = false
}

# 20 bytes = 40 hex characters, satisfying the Forgejo runner registration secret requirement
resource "random_id" "forgejo_runner_secret" {
  byte_length = 20
}

