resource "uptimekuma_status_page" "main" {
  slug        = "status"
  title       = "KCFam Services Status"
  description = "Live status for Nextcloud, Immich, and supporting infrastructure"
  published   = true

  theme     = "auto"
  show_tags = false

  public_group_list = [

    # ───────────────── External Services ─────────────────

    {
      name   = "External Services"
      weight = 1

      monitor_list = [
        {
          id       = uptimekuma_monitor_http_keyword.nextcloud_external.id
          send_url = true
        },
        {
          id       = uptimekuma_monitor_http.immich_external.id
          send_url = true
        }
      ]
    },

    # ───────────────── Internal Web Services ──────────────

    {
      name   = "Internal Web Services"
      weight = 2

      monitor_list = [
        {
          id = uptimekuma_monitor_http.nginx_web.id
        },
        {
          id = uptimekuma_monitor_http.immich_server_internal.id
        }
      ]
    },

    # ───────────────── Databases & Cache ──────────────────

    {
      name   = "Databases & Cache"
      weight = 3

      monitor_list = [
        {
          id = uptimekuma_monitor_tcp_port.postgres_main.id
        },
        {
          id = uptimekuma_monitor_tcp_port.postgres_immich.id
        },
        {
          id = uptimekuma_monitor_tcp_port.redis.id
        }
      ]
    },

    # ───────────────── App & Network ──────────────────────

    {
      name   = "Application & Network"
      weight = 4

      monitor_list = [
        {
          id = uptimekuma_monitor_tcp_port.nextcloud_app_internal.id
        },
        {
          id = uptimekuma_monitor_tcp_port.traefik_http.id
        },
        {
          id = uptimekuma_monitor_tcp_port.traefik_https.id
        }
      ]
    },

    # ───────────────── Docker Containers ──────────────────

    {
      name   = "Docker Containers"
      weight = 5

      monitor_list = [
        {
          id = uptimekuma_monitor_docker.nextcloud_app.id
        },
        {
          id = uptimekuma_monitor_docker.nextcloud_web.id
        },
        {
          id = uptimekuma_monitor_docker.nextcloud_cron.id
        },
        {
          id = uptimekuma_monitor_docker.postgres.id
        },
        {
          id = uptimekuma_monitor_docker.redis.id
        },
        {
          id = uptimekuma_monitor_docker.traefik.id
        },
        {
          id = uptimekuma_monitor_docker.immich_server.id
        },
        {
          id = uptimekuma_monitor_docker.immich_microservices.id
        },
        {
          id = uptimekuma_monitor_docker.immich_machine_learning.id
        },
        {
          id = uptimekuma_monitor_docker.immich_postgres.id
        }
      ]
    }
  ]
}
