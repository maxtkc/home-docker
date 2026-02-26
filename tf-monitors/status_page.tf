resource "uptimekuma_status_page" "main" {
  slug        = "status"
  title       = "KCFam Services Status"
  description = "Live status for all home server services"
  published   = true

  theme     = "auto"
  show_tags = false

  domain_name_list = [
    "status.kcfam.us",
  ]

  public_group_list = [

    # ───────────────── Public Services ────────────────────
    {
      name   = "Public Services"
      weight = 1

      monitor_list = [
        { id = uptimekuma_monitor_http_keyword.nextcloud_external.id, send_url = true },
        { id = uptimekuma_monitor_http.immich_external.id,            send_url = true },
        { id = uptimekuma_monitor_http.grafana_external.id,           send_url = true },
        { id = uptimekuma_monitor_http.forgejo_external.id,           send_url = true },
        { id = uptimekuma_monitor_http.openproject_external.id,       send_url = true },
      ]
    },

    # ───────────────── Infrastructure ─────────────────────
    {
      name   = "Infrastructure"
      weight = 2

      monitor_list = [
        { id = uptimekuma_monitor_tcp_port.traefik_http.id },
        { id = uptimekuma_monitor_tcp_port.traefik_https.id },
        { id = uptimekuma_monitor_tcp_port.postgres_main.id },
        { id = uptimekuma_monitor_tcp_port.postgres_immich.id },
        { id = uptimekuma_monitor_tcp_port.redis.id },
      ]
    },

    # ───────────────── Nextcloud ───────────────────────────
    {
      name   = "Nextcloud"
      weight = 3

      monitor_list = [
        { id = uptimekuma_monitor_http.nextcloud_web_internal.id },
        { id = uptimekuma_monitor_tcp_port.nextcloud_php_fpm.id },
        { id = uptimekuma_monitor_docker.nextcloud.id },
        { id = uptimekuma_monitor_docker.nextcloud_web.id },
        { id = uptimekuma_monitor_docker.nextcloud_cron.id },
      ]
    },

    # ───────────────── Immich ──────────────────────────────
    {
      name   = "Immich"
      weight = 4

      monitor_list = [
        { id = uptimekuma_monitor_http.immich_server_internal.id },
        { id = uptimekuma_monitor_http.immich_ml_internal.id },
        { id = uptimekuma_monitor_docker.immich_server.id },
        { id = uptimekuma_monitor_docker.immich_microservices.id },
        { id = uptimekuma_monitor_docker.immich_machine_learning.id },
        { id = uptimekuma_monitor_docker.immich_postgres.id },
      ]
    },

    # ───────────────── Forgejo ────────────────────────────
    {
      name   = "Forgejo"
      weight = 5

      monitor_list = [
        { id = uptimekuma_monitor_http.forgejo_internal.id },
        { id = uptimekuma_monitor_tcp_port.forgejo_ssh.id },
        { id = uptimekuma_monitor_docker.forgejo.id },
        { id = uptimekuma_monitor_docker.forgejo_runner.id },
      ]
    },

    # ───────────────── Monitoring Stack ───────────────────
    {
      name   = "Monitoring"
      weight = 6

      monitor_list = [
        { id = uptimekuma_monitor_http.prometheus_internal.id },
        { id = uptimekuma_monitor_http.grafana_internal.id },
        { id = uptimekuma_monitor_docker.prometheus.id },
        { id = uptimekuma_monitor_docker.grafana.id },
        { id = uptimekuma_monitor_docker.node_exporter.id },
        { id = uptimekuma_monitor_docker.cadvisor.id },
        { id = uptimekuma_monitor_docker.uptime_kuma.id },
      ]
    },

    # ───────────────── OpenProject ───────────────────────
    {
      name   = "OpenProject"
      weight = 7

      monitor_list = [
        { id = uptimekuma_monitor_http.openproject_web_internal.id },
        { id = uptimekuma_monitor_tcp_port.openproject_postgres.id },
        { id = uptimekuma_monitor_docker.openproject_db.id },
        { id = uptimekuma_monitor_docker.openproject_web.id },
        { id = uptimekuma_monitor_docker.openproject_worker.id },
        { id = uptimekuma_monitor_docker.openproject_cron.id },
      ]
    },

    # ───────────────── Misc ───────────────────────────────
    {
      name   = "Misc"
      weight = 8

      monitor_list = [
        { id = uptimekuma_monitor_docker.static_sites.id },
        { id = uptimekuma_monitor_docker.backup_daily.id },
        { id = uptimekuma_monitor_docker.backup_weekly.id },
        { id = uptimekuma_monitor_docker.backup_monthly.id },
      ]
    },
  ]
}
