resource "docker_container" "forgejo_db_init" {
  name     = "forgejo_db_init"
  image    = "postgres:${var.postgres_version}"
  restart  = "no"
  must_run = false

  entrypoint = [
    "/bin/sh", "-c",
    <<-EOT
      until pg_isready -h db -U nextcloud; do sleep 2; done
      psql -h db -U nextcloud -tc "SELECT 1 FROM pg_roles WHERE rolname='forgejo'" | grep -q 1 || \
        psql -h db -U nextcloud -c "CREATE USER forgejo WITH PASSWORD '${var.forgejo_db_password}'"
      psql -h db -U nextcloud -tc "SELECT 1 FROM pg_database WHERE datname='forgejo'" | grep -q 1 || \
        psql -h db -U nextcloud -c "CREATE DATABASE forgejo OWNER forgejo"
    EOT
  ]

  env = [
    "PGPASSWORD=${var.db_password}",
  ]

  networks_advanced {
    name = docker_network.default.name
  }

  depends_on = [docker_container.db]
}

resource "docker_container" "forgejo" {
  name    = "forgejo"
  image   = "codeberg.org/forgejo/forgejo:11"
  restart = "always"

  env = [
    "FORGEJO__database__DB_TYPE=postgres",
    "FORGEJO__database__HOST=db:5432",
    "FORGEJO__database__NAME=forgejo",
    "FORGEJO__database__USER=forgejo",
    "FORGEJO__database__PASSWD=${var.forgejo_db_password}",
    "FORGEJO__server__DOMAIN=git.kcfam.us",
    "FORGEJO__server__ROOT_URL=https://git.kcfam.us",
    "FORGEJO__server__SSH_DOMAIN=git.kcfam.us",
    "FORGEJO__server__SSH_PORT=2222",
    "FORGEJO__security__SECRET_KEY=${random_password.forgejo_secret_key.result}",
    "FORGEJO__service__DISABLE_REGISTRATION=true",
  ]

  ports {
    internal = 22
    external = 2222
  }

  volumes {
    volume_name    = docker_volume.forgejo_data.name
    container_path = "/data"
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
    label = "traefik.http.routers.forgejo.rule"
    value = "Host(`git.kcfam.us`)"
  }
  labels {
    label = "traefik.http.routers.forgejo.tls"
    value = "true"
  }
  labels {
    label = "traefik.http.routers.forgejo.tls.certresolver"
    value = "letsencrypt"
  }
  labels {
    label = "traefik.http.services.forgejo.loadbalancer.server.port"
    value = "3000"
  }
  labels {
    label = "backup.stop"
    value = "true"
  }

  depends_on = [docker_container.forgejo_db_init]
}
