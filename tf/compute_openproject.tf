resource "docker_container" "openproject_db" {
  name    = "openproject_db"
  image   = "postgres:${var.openproject_postgres_version}"
  restart = "always"

  env = [
    "POSTGRES_DB=openproject",
    "POSTGRES_USER=openproject",
    "POSTGRES_PASSWORD=${var.openproject_db_password}",
  ]

  volumes {
    volume_name    = docker_volume.openproject_pgdata.name
    container_path = "/var/lib/postgresql/data"
  }

  networks_advanced {
    name    = docker_network.default.name
    aliases = ["openproject-db"]
  }

  labels {
    label = "backup.stop"
    value = "true"
  }
}

resource "docker_container" "openproject_cache" {
  name    = "openproject_cache"
  image   = "memcached"
  restart = "always"

  networks_advanced {
    name    = docker_network.default.name
    aliases = ["openproject-cache"]
  }
}

resource "docker_container" "openproject_seeder" {
  name      = "openproject_seeder"
  image     = "openproject/openproject:${var.openproject_version}"
  restart   = "on-failure"
  must_run  = false
  command   = ["./docker/prod/seeder"]

  env = local.openproject_env

  volumes {
    volume_name    = docker_volume.openproject_assets.name
    container_path = "/var/openproject/assets"
  }

  networks_advanced {
    name = docker_network.default.name
  }

  depends_on = [docker_container.openproject_db, docker_container.openproject_cache]
}

resource "docker_container" "openproject_web" {
  name    = "openproject_web"
  image   = "openproject/openproject:${var.openproject_version}"
  restart = "always"
  command = ["./docker/prod/web"]

  env = local.openproject_env

  volumes {
    volume_name    = docker_volume.openproject_assets.name
    container_path = "/var/openproject/assets"
  }

  networks_advanced {
    name    = docker_network.proxy_tier.name
    aliases = ["openproject-web"]
  }

  networks_advanced {
    name    = docker_network.default.name
    aliases = ["openproject-web"]
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.openproject.rule"
    value = "Host(`op.kcfam.us`)"
  }

  labels {
    label = "traefik.http.routers.openproject.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.openproject.tls.certresolver"
    value = "letsencrypt"
  }

  labels {
    label = "traefik.http.services.openproject.loadbalancer.server.port"
    value = "8080"
  }

  depends_on = [docker_container.openproject_seeder]
}

resource "docker_container" "openproject_worker" {
  name    = "openproject_worker"
  image   = "openproject/openproject:${var.openproject_version}"
  restart = "always"
  command = ["./docker/prod/worker"]

  env = local.openproject_env

  volumes {
    volume_name    = docker_volume.openproject_assets.name
    container_path = "/var/openproject/assets"
  }

  networks_advanced {
    name = docker_network.default.name
  }

  depends_on = [docker_container.openproject_seeder]
}

resource "docker_container" "openproject_cron" {
  name    = "openproject_cron"
  image   = "openproject/openproject:${var.openproject_version}"
  restart = "always"
  command = ["./docker/prod/cron"]

  env = local.openproject_env

  volumes {
    volume_name    = docker_volume.openproject_assets.name
    container_path = "/var/openproject/assets"
  }

  networks_advanced {
    name = docker_network.default.name
  }

  depends_on = [docker_container.openproject_seeder]
}

resource "docker_container" "openproject_hocuspocus" {
  count   = var.openproject_hocuspocus_enabled ? 1 : 0
  name    = "openproject_hocuspocus"
  image   = "openproject/hocuspocus:${var.openproject_hocuspocus_version}"
  restart = "always"

  env = [
    "SECRET=${var.openproject_hocuspocus_secret}",
    "OPENPROJECT_URL=http://openproject-web:8080",
    "OPENPROJECT_HTTPS=true",
  ]

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
    label = "traefik.http.routers.openproject-hocuspocus.rule"
    value = "Host(`op.kcfam.us`) && PathPrefix(`/hocuspocus`)"
  }

  labels {
    label = "traefik.http.routers.openproject-hocuspocus.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.openproject-hocuspocus.tls.certresolver"
    value = "letsencrypt"
  }

  labels {
    label = "traefik.http.services.openproject-hocuspocus.loadbalancer.server.port"
    value = "3000"
  }

  depends_on = [docker_container.openproject_web]
}
