resource "docker_container" "immich_postgres" {
  name    = "immich_postgres"
  image   = "ghcr.io/immich-app/postgres:${var.immich_postgres_version}"
  restart = "always"

  env = [
    "POSTGRES_DB=${local.immich_db_name}",
    "POSTGRES_USER=${local.immich_db_user}",
    "POSTGRES_PASSWORD=${var.immich_db_password}",
  ]

  volumes {
    volume_name    = docker_volume.immich_postgres.name
    container_path = "/var/lib/postgresql/data"
  }

  shm_size = 134217728 # 128MB

  networks_advanced {
    name = docker_network.default.name
  }

  labels {
    label = "backup.stop"
    value = "true"
  }
}

resource "docker_container" "immich_server" {
  name    = "immich_server"
  image   = "ghcr.io/immich-app/immich-server:${var.immich_version}"
  restart = "always"

  command = ["start.sh", "immich"]

  env = [
    "DB_HOSTNAME=immich_postgres",
    "DB_DATABASE_NAME=${local.immich_db_name}",
    "DB_USERNAME=${local.immich_db_user}",
    "DB_PASSWORD=${var.immich_db_password}",
    "REDIS_HOSTNAME=${local.immich_redis_hostname}",
    "IMMICH_HOST=${local.immich_host}",
    "IMMICH_PORT=${local.immich_port}",
    "IMMICH_MACHINE_LEARNING_URL=${local.immich_ml_url}",
  ]

  volumes {
    volume_name    = docker_volume.immich_upload.name
    container_path = "/usr/src/app/upload"
  }

  volumes {
    volume_name    = docker_volume.nextcloud.name
    container_path = "/mnt/nextcloud"
    read_only      = true
  }

  volumes {
    host_path      = "/etc/localtime"
    container_path = "/etc/localtime"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.proxy_tier.name
  }

  networks_advanced {
    name = docker_network.default.name
  }

  labels {
    label = "backup.stop"
    value = "true"
  }

  labels {
    label = "traefik.enable"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.immich.rule"
    value = "Host(`im.kcfam.us`)"
  }

  labels {
    label = "traefik.http.routers.immich.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.immich.tls.certresolver"
    value = "letsencrypt"
  }

  labels {
    label = "traefik.http.services.immich.loadbalancer.server.port"
    value = "2283"
  }

  depends_on = [docker_container.redis, docker_container.immich_postgres]
}

resource "docker_container" "immich_microservices" {
  name    = "immich_microservices"
  image   = "ghcr.io/immich-app/immich-server:${var.immich_version}"
  restart = "always"

  command = ["start.sh", "microservices"]

  env = [
    "DB_HOSTNAME=immich_postgres",
    "DB_DATABASE_NAME=${local.immich_db_name}",
    "DB_USERNAME=${local.immich_db_user}",
    "DB_PASSWORD=${var.immich_db_password}",
    "REDIS_HOSTNAME=${local.immich_redis_hostname}",
    "IMMICH_HOST=${local.immich_host}",
    "IMMICH_PORT=${local.immich_port}",
    "IMMICH_MACHINE_LEARNING_URL=${local.immich_ml_url}",
  ]

  volumes {
    volume_name    = docker_volume.immich_upload.name
    container_path = "/usr/src/app/upload"
  }

  volumes {
    volume_name    = docker_volume.nextcloud.name
    container_path = "/mnt/nextcloud"
    read_only      = true
  }

  volumes {
    host_path      = "/etc/localtime"
    container_path = "/etc/localtime"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.default.name
  }

  labels {
    label = "backup.stop"
    value = "true"
  }

  depends_on = [docker_container.redis, docker_container.immich_postgres]
}

resource "docker_container" "immich_machine_learning" {
  name    = "immich_machine_learning"
  image   = "ghcr.io/immich-app/immich-machine-learning:${var.immich_version}"
  restart = "always"

  env = [
    "IMMICH_MACHINE_LEARNING_URL=${local.immich_ml_url}",
  ]

  volumes {
    volume_name    = docker_volume.model_cache.name
    container_path = "/cache"
  }

  networks_advanced {
    name = docker_network.default.name
  }

  labels {
    label = "backup.stop"
    value = "true"
  }
}
