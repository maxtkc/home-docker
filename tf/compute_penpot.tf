resource "random_password" "penpot_secret_key" {
  length  = 64
  special = false
}

resource "random_password" "penpot_user_password" {
  for_each = { for u in var.penpot_admin_users : u.email => u }
  length   = 24
  special  = false
}

resource "terraform_data" "penpot_admin_users" {
  for_each = { for u in var.penpot_admin_users : u.email => u }

  triggers_replace = sha256(each.key)

  provisioner "local-exec" {
    command = <<-EOT
      for i in $(seq 1 18); do
        ssh kcfam docker exec penpot-backend python3 manage.py \
          create-profile \
          --email "${each.value.email}" \
          --fullname "${each.value.fullname}" \
          --password "${random_password.penpot_user_password[each.key].result}" && break
        echo "Penpot not ready, retrying in 10s..."
        sleep 10
      done
    EOT
  }

  depends_on = [docker_container.penpot_backend]
}

output "penpot_admin_passwords" {
  value       = { for email, pw in random_password.penpot_user_password : email => pw.result }
  sensitive   = true
  description = "Retrieve with: tofu output -json penpot_admin_passwords"
}

resource "docker_container" "penpot_postgres" {
  name    = "penpot-postgres"
  image   = "postgres:${var.penpot_postgres_version}"
  restart = "always"

  env = [
    "POSTGRES_DB=penpot",
    "POSTGRES_USER=penpot",
    "POSTGRES_PASSWORD=${var.penpot_db_password}",
  ]

  volumes {
    volume_name    = docker_volume.penpot_postgres.name
    container_path = "/var/lib/postgresql/data"
  }

  networks_advanced {
    name = docker_network.default.name
  }

  labels {
    label = "backup.stop"
    value = "true"
  }
}

resource "docker_container" "penpot_valkey" {
  name    = "penpot-valkey"
  image   = "valkey/valkey:${var.penpot_valkey_version}"
  restart = "always"

  command = [
    "valkey-server",
    "--save", "60", "1",
    "--loglevel", "warning",
    "--maxmemory", "128mb",
    "--maxmemory-policy", "allkeys-lru",
  ]

  networks_advanced {
    name = docker_network.default.name
  }
}

resource "docker_container" "penpot_backend" {
  name    = "penpot-backend"
  image   = "penpotapp/backend:${var.penpot_version}"
  restart = "always"

  env = [
    "PENPOT_FLAGS=${local.penpot_flags}",
    "PENPOT_PUBLIC_URI=https://penpot.kcfam.us",
    "PENPOT_SECRET_KEY=${random_password.penpot_secret_key.result}",
    "PENPOT_DATABASE_URI=postgresql://penpot-postgres/penpot",
    "PENPOT_DATABASE_USERNAME=penpot",
    "PENPOT_DATABASE_PASSWORD=${var.penpot_db_password}",
    "PENPOT_REDIS_URI=redis://penpot-valkey/0",
    "PENPOT_OBJECTS_STORAGE_BACKEND=fs",
    "PENPOT_OBJECTS_STORAGE_FS_DIRECTORY=/opt/data/assets",
    "PENPOT_TELEMETRY_ENABLED=${var.penpot_telemetry_enabled ? "true" : "false"}",
    "PENPOT_SMTP_DEFAULT_FROM=${var.smtp_email}",
    "PENPOT_SMTP_DEFAULT_REPLY_TO=${var.smtp_email}",
    "PENPOT_SMTP_HOST=smtp.gmail.com",
    "PENPOT_SMTP_PORT=587",
    "PENPOT_SMTP_USERNAME=${var.smtp_email}",
    "PENPOT_SMTP_PASSWORD=${var.smtp_password}",
    "PENPOT_SMTP_TLS=true",
    "PENPOT_SMTP_SSL=false",
  ]

  volumes {
    volume_name    = docker_volume.penpot_assets.name
    container_path = "/opt/data/assets"
  }

  networks_advanced {
    name = docker_network.default.name
  }
}

resource "docker_container" "penpot_exporter" {
  name    = "penpot-exporter"
  image   = "penpotapp/exporter:${var.penpot_version}"
  restart = "always"

  env = [
    "PENPOT_FLAGS=${local.penpot_flags}",
    "PENPOT_PUBLIC_URI=http://penpot-frontend:8080",
    "PENPOT_REDIS_URI=redis://penpot-valkey/0",
  ]

  networks_advanced {
    name = docker_network.default.name
  }
}

resource "docker_container" "penpot_frontend" {
  name    = "penpot-frontend"
  image   = "penpotapp/frontend:${var.penpot_version}"
  restart = "always"

  env = [
    "PENPOT_FLAGS=${local.penpot_flags}",
  ]

  volumes {
    volume_name    = docker_volume.penpot_assets.name
    container_path = "/opt/data/assets"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.proxy_tier.name
  }

  networks_advanced {
    name = docker_network.default.name
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.penpot.rule"
    value = "Host(`penpot.kcfam.us`)"
  }

  labels {
    label = "traefik.http.routers.penpot.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.penpot.tls.certresolver"
    value = "letsencrypt"
  }

  labels {
    label = "traefik.http.services.penpot.loadbalancer.server.port"
    value = "8080"
  }
}
