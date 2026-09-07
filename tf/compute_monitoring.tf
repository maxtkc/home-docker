resource "docker_container" "node_exporter" {
  name    = "node-exporter"
  image   = "prom/node-exporter:${var.node_exporter_version}"
  restart = "always"

  command = [
    "--path.procfs=/host/proc",
    "--path.rootfs=/rootfs",
    "--path.sysfs=/host/sys",
    "--collector.filesystem.mount-points-exclude=^/(sys|proc|dev|host|etc)($|/)",
    "--collector.textfile.directory=/textfile",
  ]

  # restic-data writes its last-success metric here; this is what makes the
  # BackupStale rule possible.
  volumes {
    volume_name    = docker_volume.textfile_collector.name
    container_path = "/textfile"
    read_only      = true
  }

  volumes {
    host_path      = "/proc"
    container_path = "/host/proc"
    read_only      = true
  }

  volumes {
    host_path      = "/sys"
    container_path = "/host/sys"
    read_only      = true
  }

  volumes {
    host_path      = "/"
    container_path = "/rootfs"
    read_only      = true
  }

  networks_advanced {
    name = docker_network.default.name
  }
}

resource "docker_container" "cadvisor" {
  name       = "cadvisor"
  image      = "ghcr.io/google/cadvisor:${var.cadvisor_version}"
  restart    = "always"
  privileged = true

  volumes {
    host_path      = "/"
    container_path = "/rootfs"
    read_only      = true
  }

  volumes {
    host_path      = "/var/run"
    container_path = "/var/run"
    read_only      = true
  }

  volumes {
    host_path      = "/sys"
    container_path = "/sys"
    read_only      = true
  }

  volumes {
    host_path      = "/var/lib/docker"
    container_path = "/var/lib/docker"
    read_only      = true
  }

  volumes {
    host_path      = "/dev/disk"
    container_path = "/dev/disk"
    read_only      = true
  }

  devices {
    host_path      = "/dev/kmsg"
    container_path = "/dev/kmsg"
    permissions    = "rwm"
  }

  networks_advanced {
    name = docker_network.default.name
  }
}

resource "docker_container" "prometheus" {
  name    = "prometheus"
  image   = docker_image.prometheus.image_id
  restart = "always"

  command = [
    "--config.file=/etc/prometheus/prometheus.yml",
    "--storage.tsdb.path=/prometheus",
    "--web.console.libraries=/etc/prometheus/console_libraries",
    "--web.console.templates=/etc/prometheus/consoles",
    "--web.enable-lifecycle",
    "--storage.tsdb.retention.time=30d",
    "--query.lookback-delta=30s",
  ]

  volumes {
    volume_name    = docker_volume.prometheus_data.name
    container_path = "/prometheus"
  }

  networks_advanced {
    name = docker_network.default.name
  }

  depends_on = [docker_container.node_exporter, docker_container.cadvisor]
}

# Internal only: on docker_network.default and NOT proxy_tier, so it is not
# routable from the internet, same as Prometheus.
#
# Unlike prometheus, this is the upstream image rather than a locally built one.
# Its config carries the Telegram chat id, which comes from a Terraform variable,
# and a docker_image build context cannot see Terraform variables. Both the
# config and the token therefore arrive as `upload` blocks at container-create
# time, which also keeps the token out of an image layer.
resource "docker_container" "alertmanager" {
  name    = "alertmanager"
  image   = "prom/alertmanager:${var.alertmanager_version}"
  restart = "always"

  command = [
    "--config.file=/etc/alertmanager/alertmanager.yml",
    "--storage.path=/alertmanager",
  ]

  upload {
    content = templatefile("${path.cwd}/../alertmanager/alertmanager.yml.tftpl", {
      chat_id = var.alertmanager_telegram_chat_id
    })
    file = "/etc/alertmanager/alertmanager.yml"
  }

  upload {
    content = var.alertmanager_telegram_token
    file    = "/etc/alertmanager/telegram_token"
  }

  networks_advanced {
    name = docker_network.default.name
  }
}

resource "docker_container" "grafana" {
  name    = "grafana"
  image   = docker_image.grafana.image_id
  restart = "always"
  user    = "472"

  env = [
    "GF_SECURITY_ADMIN_PASSWORD=${random_password.grafana_admin.result}",
    "GF_USERS_ALLOW_SIGN_UP=false",
    "GF_INSTALL_PLUGINS=grafana-piechart-panel",
    "GF_PLUGINS_ALLOW_LOADING_UNSIGNED_PLUGINS=grafana-piechart-panel",
    "GF_SERVER_ROOT_URL=https://gf.kcfam.us",
    "GF_AUTH_GITHUB_ENABLED=true",
    "GF_AUTH_GITHUB_CLIENT_ID=${var.github_client_id}",
    "GF_AUTH_GITHUB_CLIENT_SECRET=${var.github_client_secret}",
    "GF_AUTH_GITHUB_SCOPES=user:email,read:org",
    "GF_AUTH_GITHUB_ALLOW_SIGN_UP=true",
    "GF_AUTH_GITHUB_ALLOWED_USERS=maxtkc",
    "GF_AUTH_GITHUB_SKIP_ORG_ROLE_SYNC=true",
    "GF_AUTH_OAUTH_ALLOW_INSECURE_EMAIL_LOOKUP=true",
  ]

  volumes {
    volume_name    = docker_volume.grafana_data.name
    container_path = "/var/lib/grafana"
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
    label = "traefik.http.routers.grafana.rule"
    value = "Host(`gf.kcfam.us`)"
  }

  labels {
    label = "traefik.http.routers.grafana.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.grafana.tls.certresolver"
    value = "letsencrypt"
  }

  labels {
    label = "traefik.http.services.grafana.loadbalancer.server.port"
    value = "3000"
  }

  depends_on = [docker_container.prometheus]
}

resource "docker_container" "uptime_kuma" {
  name    = "uptime-kuma"
  image   = "louislam/uptime-kuma:${var.uptime_kuma_version}"
  restart = "always"

  volumes {
    volume_name    = docker_volume.uptime_kuma.name
    container_path = "/app/data"
  }

  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
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
    label = "traefik.http.routers.uptime.rule"
    value = "Host(`uptime.kcfam.us`)"
  }

  labels {
    label = "traefik.http.routers.uptime.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.uptime.tls.certresolver"
    value = "letsencrypt"
  }

  labels {
    label = "traefik.http.services.uptime.loadbalancer.server.port"
    value = "3001"
  }

  # Router: pass all status.kcfam.us traffic to Uptime Kuma (custom domain set in UI)
  labels {
    label = "traefik.http.routers.status-page.rule"
    value = "Host(`status.kcfam.us`)"
  }

  labels {
    label = "traefik.http.routers.status-page.tls"
    value = "true"
  }

  labels {
    label = "traefik.http.routers.status-page.tls.certresolver"
    value = "letsencrypt"
  }

  labels {
    label = "traefik.http.routers.status-page.service"
    value = "uptime"
  }
}
