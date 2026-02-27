# Docker host — gives Uptime Kuma access to the local Docker socket
resource "uptimekuma_docker_host" "local" {
  name          = "Local Docker Host"
  docker_type   = "socket"
  docker_daemon = "/run/docker.sock"
}

locals {
  notification_ids = [uptimekuma_notification.telegram.id]
}

# ─── External HTTP monitors ───────────────────────────────────────────────────

resource "uptimekuma_monitor_http_keyword" "nextcloud_external" {
  name                  = "Nextcloud"
  url                   = "https://nc.kcfam.us"
  keyword               = "Nextcloud"
  interval              = 60
  max_retries           = 3
  max_redirects         = 10
  accepted_status_codes = ["200"]
  notification_ids      = local.notification_ids
  active                = true
}

resource "uptimekuma_monitor_http" "immich_external" {
  name                  = "Immich"
  url                   = "https://im.kcfam.us"
  interval              = 60
  max_retries           = 3
  max_redirects         = 10
  accepted_status_codes = ["200"]
  notification_ids      = local.notification_ids
  active                = true
}

resource "uptimekuma_monitor_http" "grafana_external" {
  name                  = "Grafana"
  url                   = "https://gf.kcfam.us"
  interval              = 60
  max_retries           = 3
  max_redirects         = 10
  accepted_status_codes = ["200"]
  notification_ids      = local.notification_ids
  active                = true
}

resource "uptimekuma_monitor_http" "forgejo_external" {
  name                  = "Forgejo"
  url                   = "https://git.kcfam.us"
  interval              = 60
  max_retries           = 3
  max_redirects         = 10
  accepted_status_codes = ["200"]
  notification_ids      = local.notification_ids
  active                = true
}

# Long interval — avoids constantly waking the Sablier-managed container
resource "uptimekuma_monitor_http" "openproject_external" {
  count                 = var.monitor_openproject ? 1 : 0
  name                  = "OpenProject"
  url                   = "https://op.kcfam.us/health_checks/default"
  interval              = 60
  max_retries           = 3
  max_redirects         = 5
  accepted_status_codes = ["200"]
  notification_ids      = local.notification_ids
  active                = true
}

resource "uptimekuma_monitor_http" "grampsweb_external" {
  name                  = "GrampsWeb"
  url                   = "https://gramps.kcfam.us"
  interval              = 300
  max_retries           = 3
  max_redirects         = 10
  accepted_status_codes = ["200"]
  notification_ids      = []
  active                = true
  lifecycle {
    ignore_changes = [notification_ids]
  }
}

# ─── Internal HTTP monitors ───────────────────────────────────────────────────

resource "uptimekuma_monitor_http" "nextcloud_web_internal" {
  name                  = "Nextcloud Web (nginx)"
  url                   = "http://nextcloud-web:80"
  interval              = 60
  max_retries           = 3
  accepted_status_codes = ["200", "301", "302", "400", "404"]
  headers               = jsonencode({ Host = "nc.kcfam.us" })
  notification_ids      = local.notification_ids
  active                = true
}

resource "uptimekuma_monitor_http" "immich_server_internal" {
  name                  = "Immich Server (internal)"
  url                   = "http://immich_server:2283"
  interval              = 60
  max_retries           = 3
  accepted_status_codes = ["200", "404"]
  notification_ids      = local.notification_ids
  active                = true
}

resource "uptimekuma_monitor_http" "immich_ml_internal" {
  name                  = "Immich Machine Learning (internal)"
  url                   = "http://immich_machine_learning:3003"
  interval              = 60
  max_retries           = 3
  accepted_status_codes = ["200"]
  notification_ids      = local.notification_ids
  active                = true
}

resource "uptimekuma_monitor_http" "forgejo_internal" {
  name                  = "Forgejo (internal)"
  url                   = "http://forgejo:3000"
  interval              = 60
  max_retries           = 3
  accepted_status_codes = ["200"]
  notification_ids      = local.notification_ids
  active                = true
}

resource "uptimekuma_monitor_http" "prometheus_internal" {
  name                  = "Prometheus (internal)"
  url                   = "http://prometheus:9090/-/healthy"
  interval              = 60
  max_retries           = 3
  accepted_status_codes = ["200"]
  notification_ids      = local.notification_ids
  active                = true
}

resource "uptimekuma_monitor_http" "grafana_internal" {
  name                  = "Grafana (internal)"
  url                   = "http://grafana:3000/api/health"
  interval              = 60
  max_retries           = 3
  accepted_status_codes = ["200"]
  notification_ids      = local.notification_ids
  active                = true
}

# ─── TCP port monitors ────────────────────────────────────────────────────────

resource "uptimekuma_monitor_tcp_port" "traefik_http" {
  name             = "Traefik HTTP"
  hostname         = "traefik"
  port             = 80
  interval         = 30
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_tcp_port" "traefik_https" {
  name             = "Traefik HTTPS"
  hostname         = "traefik"
  port             = 443
  interval         = 30
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_tcp_port" "postgres_main" {
  name             = "PostgreSQL (main)"
  hostname         = "db"
  port             = 5432
  interval         = 30
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_tcp_port" "postgres_immich" {
  name             = "PostgreSQL (Immich)"
  hostname         = "immich_postgres"
  port             = 5432
  interval         = 30
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_tcp_port" "redis" {
  name             = "Redis"
  hostname         = "redis"
  port             = 6379
  interval         = 30
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_tcp_port" "nextcloud_php_fpm" {
  name             = "Nextcloud PHP-FPM"
  hostname         = "nextcloud"
  port             = 9000
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_tcp_port" "forgejo_ssh" {
  name             = "Forgejo SSH"
  hostname         = "git.kcfam.us"
  port             = 2222
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

# ─── Docker container monitors ───────────────────────────────────────────────

# Infrastructure
resource "uptimekuma_monitor_docker" "traefik" {
  name             = "traefik"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "traefik"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "sablier" {
  name             = "sablier"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "sablier"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "db" {
  name             = "db (postgres)"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "db"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "redis" {
  name             = "redis"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "redis"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

# Nextcloud
resource "uptimekuma_monitor_docker" "nextcloud" {
  name             = "nextcloud (app)"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "nextcloud"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "nextcloud_web" {
  name             = "nextcloud-web"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "nextcloud-web"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "nextcloud_cron" {
  name             = "nextcloud-cron"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "nextcloud-cron"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

# Immich
resource "uptimekuma_monitor_docker" "immich_server" {
  name             = "immich_server"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "immich_server"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "immich_microservices" {
  name             = "immich_microservices"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "immich_microservices"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "immich_machine_learning" {
  name             = "immich_machine_learning"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "immich_machine_learning"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "immich_postgres" {
  name             = "immich_postgres"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "immich_postgres"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

# GrampsWeb (Sablier-managed — containers may be stopped when idle; no notifications)
resource "uptimekuma_monitor_docker" "grampsweb" {
  name             = "grampsweb"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "grampsweb"
  interval         = 60
  max_retries      = 3
  notification_ids = []
  active           = true
  lifecycle {
    ignore_changes = [notification_ids]
  }
}

resource "uptimekuma_monitor_docker" "grampsweb_celery" {
  name             = "grampsweb_celery"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "grampsweb_celery"
  interval         = 60
  max_retries      = 3
  notification_ids = []
  active           = true
  lifecycle {
    ignore_changes = [notification_ids]
  }
}

resource "uptimekuma_monitor_docker" "grampsweb_redis" {
  name             = "grampsweb_redis"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "grampsweb_redis"
  interval         = 60
  max_retries      = 3
  notification_ids = []
  active           = true
  lifecycle {
    ignore_changes = [notification_ids]
  }
}

# Forgejo
resource "uptimekuma_monitor_docker" "forgejo" {
  name             = "forgejo"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "forgejo"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "forgejo_runner" {
  name             = "forgejo_runner"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "forgejo_runner"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

# Monitoring stack
resource "uptimekuma_monitor_docker" "prometheus" {
  name             = "prometheus"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "prometheus"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "grafana" {
  name             = "grafana"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "grafana"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "node_exporter" {
  name             = "node-exporter"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "node-exporter"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "cadvisor" {
  name             = "cadvisor"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "cadvisor"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "uptime_kuma" {
  name             = "uptime-kuma"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "uptime-kuma"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

# Misc
resource "uptimekuma_monitor_docker" "static_sites" {
  name             = "static-sites"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "static-sites"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "backup_daily" {
  name             = "backup-daily"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "backup-daily"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "backup_weekly" {
  name             = "backup-weekly"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "backup-weekly"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "backup_monthly" {
  name             = "backup-monthly"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "backup-monthly"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

# OpenProject
resource "uptimekuma_monitor_http" "openproject_web_internal" {
  count                 = var.monitor_openproject ? 1 : 0
  name                  = "OpenProject Web (internal)"
  url                   = "http://openproject_web:8080/health_checks/default"
  interval              = 60
  max_retries           = 3
  accepted_status_codes = ["200"]
  headers               = jsonencode({ Host = "op.kcfam.us" })
  notification_ids      = local.notification_ids
  active                = true
}

resource "uptimekuma_monitor_tcp_port" "openproject_postgres" {
  count            = var.monitor_openproject ? 1 : 0
  name             = "PostgreSQL (OpenProject)"
  hostname         = "openproject_db"
  port             = 5432
  interval         = 30
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "openproject_db" {
  count            = var.monitor_openproject ? 1 : 0
  name             = "openproject_db"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "openproject_db"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "openproject_web" {
  count            = var.monitor_openproject ? 1 : 0
  name             = "openproject_web"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "openproject_web"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "openproject_worker" {
  count            = var.monitor_openproject ? 1 : 0
  name             = "openproject_worker"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "openproject_worker"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}

resource "uptimekuma_monitor_docker" "openproject_cron" {
  count            = var.monitor_openproject ? 1 : 0
  name             = "openproject_cron"
  docker_host_id   = uptimekuma_docker_host.local.id
  docker_container = "openproject_cron"
  interval         = 60
  max_retries      = 3
  notification_ids = local.notification_ids
  active           = true
}
