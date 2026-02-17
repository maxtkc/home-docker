# Docker host — gives Uptime Kuma access to the local Docker socket
resource "uptimekuma_docker_host" "local" {
  name          = "Local Docker Host"
  docker_type   = "socket"
  docker_daemon = "/run/docker.sock"
}

# ─── External HTTP monitors ───────────────────────────────────────────────────

resource "uptimekuma_monitor_http_keyword" "nextcloud_external" {
  name                  = "Nextcloud (External)"
  description           = "Nextcloud file sharing and collaboration platform"
  url                   = "https://nc.kcfam.us"
  keyword               = "Nextcloud"
  interval              = 60
  max_retries           = 3
  max_redirects         = 10
  accepted_status_codes = ["200"]
  active                = true
}

resource "uptimekuma_monitor_http" "immich_external" {
  name                  = "Immich (External)"
  description           = "Immich photo management and AI features"
  url                   = "https://im.kcfam.us"
  interval              = 60
  max_retries           = 3
  max_redirects         = 10
  accepted_status_codes = ["200"]
  active                = true
}

# ─── Internal HTTP monitors ───────────────────────────────────────────────────

resource "uptimekuma_monitor_http" "nginx_web" {
  name                  = "Nginx Web Server"
  description           = "Nginx web server for Nextcloud"
  url                   = "http://nextcloud_web_1:80"
  interval              = 60
  max_retries           = 3
  accepted_status_codes = ["200", "301", "302", "400", "404"]
  headers               = jsonencode({ Host = "nc.kcfam.us" })
  active                = true
}

resource "uptimekuma_monitor_http" "immich_server_internal" {
  name                  = "Immich Server (Internal)"
  description           = "Internal Immich server API"
  url                   = "http://immich_server:2283"
  interval              = 60
  max_retries           = 3
  accepted_status_codes = ["200", "404"]
  active                = true
}

# ─── TCP port monitors ────────────────────────────────────────────────────────

resource "uptimekuma_monitor_tcp_port" "postgres_main" {
  name        = "PostgreSQL (Main DB)"
  description = "Main PostgreSQL database for Nextcloud and shared services"
  hostname    = "nextcloud_db_1"
  port        = 5432
  interval    = 30
  max_retries = 3
  active      = true
}

resource "uptimekuma_monitor_tcp_port" "postgres_immich" {
  name        = "PostgreSQL (Immich)"
  description = "PostgreSQL database for Immich with vector extensions"
  hostname    = "immich_postgres"
  port        = 5432
  interval    = 30
  max_retries = 3
  active      = true
}

resource "uptimekuma_monitor_tcp_port" "redis" {
  name        = "Redis Cache"
  description = "Redis cache for Nextcloud and shared services"
  hostname    = "nextcloud_redis_1"
  port        = 6379
  interval    = 30
  max_retries = 3
  active      = true
}

resource "uptimekuma_monitor_tcp_port" "nextcloud_app_internal" {
  name        = "Nextcloud App (Internal)"
  description = "Internal Nextcloud PHP-FPM application"
  hostname    = "nextcloud_app_1"
  port        = 9000
  interval    = 60
  max_retries = 3
  active      = true
}

resource "uptimekuma_monitor_tcp_port" "traefik_http" {
  name        = "Traefik HTTP"
  description = "Traefik reverse proxy (HTTP)"
  hostname    = "nextcloud_traefik_1"
  port        = 80
  interval    = 30
  max_retries = 3
  active      = true
}

resource "uptimekuma_monitor_tcp_port" "traefik_https" {
  name        = "Traefik HTTPS"
  description = "Traefik reverse proxy (HTTPS)"
  hostname    = "nextcloud_traefik_1"
  port        = 443
  interval    = 30
  max_retries = 3
  active      = true
}

# ─── Docker container monitors ───────────────────────────────────────────────

resource "uptimekuma_monitor_docker" "nextcloud_app" {
  name             = "Nextcloud App Container"
  description      = "Nextcloud PHP-FPM application container"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "nextcloud_app_1"
  interval         = 60
  max_retries      = 3
  active           = true
}

resource "uptimekuma_monitor_docker" "nextcloud_web" {
  name             = "Nextcloud Web Container"
  description      = "Nginx web server container"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "nextcloud_web_1"
  interval         = 60
  max_retries      = 3
  active           = true
}

resource "uptimekuma_monitor_docker" "nextcloud_cron" {
  name             = "Nextcloud Cron Container"
  description      = "Nextcloud background job container"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "nextcloud_cron_1"
  interval         = 60
  max_retries      = 3
  active           = true
}

resource "uptimekuma_monitor_docker" "postgres" {
  name             = "PostgreSQL Container"
  description      = "Main PostgreSQL database container"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "nextcloud_db_1"
  interval         = 60
  max_retries      = 3
  active           = true
}

resource "uptimekuma_monitor_docker" "redis" {
  name             = "Redis Container"
  description      = "Redis cache container"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "nextcloud_redis_1"
  interval         = 60
  max_retries      = 3
  active           = true
}

resource "uptimekuma_monitor_docker" "traefik" {
  name             = "Traefik Container"
  description      = "Traefik reverse proxy container"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "nextcloud_traefik_1"
  interval         = 60
  max_retries      = 3
  active           = true
}

resource "uptimekuma_monitor_docker" "immich_server" {
  name             = "Immich Server Container"
  description      = "Immich main server container"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "immich_server"
  interval         = 60
  max_retries      = 3
  active           = true
}

resource "uptimekuma_monitor_docker" "immich_microservices" {
  name             = "Immich Microservices Container"
  description      = "Immich background processing container"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "immich_microservices"
  interval         = 60
  max_retries      = 3
  active           = true
}

resource "uptimekuma_monitor_docker" "immich_machine_learning" {
  name             = "Immich ML Container"
  description      = "Immich machine learning container"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "immich_machine_learning"
  interval         = 60
  max_retries      = 3
  active           = true
}

resource "uptimekuma_monitor_docker" "immich_postgres" {
  name             = "Immich PostgreSQL Container"
  description      = "Immich PostgreSQL with vector extensions"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "immich_postgres"
  interval         = 60
  max_retries      = 3
  active           = true
}
