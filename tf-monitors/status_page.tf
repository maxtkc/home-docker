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

  public_group_list = concat([

    # ───────────────── Public Services ────────────────────
    {
      name   = "Public Services"
      weight = 1

      # GrampsWeb and TGTG are excluded here — they are frequently down/idle
      # and would create noise on the public status page.
      monitor_list = concat(
        [
          { id = uptimekuma_monitor_http_keyword.nextcloud_external.id, send_url = true },
          { id = uptimekuma_monitor_http.immich_external.id,            send_url = true },
          { id = uptimekuma_monitor_http.grafana_external.id,           send_url = true },
          { id = uptimekuma_monitor_http.forgejo_external.id,           send_url = true },
          { id = uptimekuma_monitor_http.homeassistant_external.id,   send_url = true },
          { id = uptimekuma_monitor_http.musicassistant_external.id, send_url = true },
          { id = uptimekuma_monitor_http.penpot_external.id,         send_url = true },
        ],
        var.monitor_openproject ? [{ id = uptimekuma_monitor_http.openproject_external[0].id, send_url = true }] : [],
      )
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

      # forgejo_runner is excluded — it is scaled by a variable and may not always be running
      monitor_list = [
        { id = uptimekuma_monitor_http.forgejo_internal.id },
        { id = uptimekuma_monitor_tcp_port.forgejo_ssh.id },
        { id = uptimekuma_monitor_docker.forgejo.id },
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

    # GrampsWeb and TGTG groups are omitted from the status page — they are
    # frequently down/idle and would create noise on the public status page.

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

    # ───────────────── Penpot ────────────────────────────
    {
      name   = "Penpot"
      weight = 9

      monitor_list = [
        { id = uptimekuma_monitor_http.penpot_external.id },
        { id = uptimekuma_monitor_http.penpot_backend_internal.id },
        { id = uptimekuma_monitor_tcp_port.penpot_postgres.id },
        { id = uptimekuma_monitor_docker.penpot_frontend.id },
        { id = uptimekuma_monitor_docker.penpot_backend.id },
        { id = uptimekuma_monitor_docker.penpot_exporter.id },
        { id = uptimekuma_monitor_docker.penpot_postgres.id },
        { id = uptimekuma_monitor_docker.penpot_valkey.id },
      ]
    },

  ], var.monitor_openproject ? [

    # ───────────────── OpenProject ───────────────────────
    {
      name   = "OpenProject"
      weight = 7

      monitor_list = [
        { id = uptimekuma_monitor_http.openproject_web_internal[0].id },
        { id = uptimekuma_monitor_tcp_port.openproject_postgres[0].id },
        { id = uptimekuma_monitor_docker.openproject_db[0].id },
        { id = uptimekuma_monitor_docker.openproject_web[0].id },
        { id = uptimekuma_monitor_docker.openproject_worker[0].id },
        { id = uptimekuma_monitor_docker.openproject_cron[0].id },
      ]
    },

  ] : [])
}
