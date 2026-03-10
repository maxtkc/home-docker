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
  image   = "codeberg.org/forgejo/forgejo:14"
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
    "FORGEJO__service__DISABLE_REGISTRATION=${var.forgejo_disable_registration}",
    "FORGEJO__service__REGISTER_EMAIL_CONFIRM=${var.forgejo_register_email_confirm}",
    "FORGEJO__service__ENABLE_NOTIFY_MAIL=${var.forgejo_enable_notify_mail}",
    "FORGEJO__service__SHOW_REGISTRATION_BUTTON=${var.forgejo_show_registration_button}",
    "FORGEJO__service__ENABLE_CAPTCHA=${var.forgejo_enable_captcha}",
    "FORGEJO__service__CAPTCHA_TYPE=${var.forgejo_captcha_type}",
    "FORGEJO__mailer__ENABLED=true",
    "FORGEJO__mailer__SMTP_ADDR=smtp.gmail.com",
    "FORGEJO__mailer__SMTP_PORT=587",
    "FORGEJO__mailer__USER=${var.smtp_email}",
    "FORGEJO__mailer__PASSWD=${var.smtp_password}",
    "FORGEJO__mailer__FROM=${var.smtp_email}",
    "FORGEJO__mailer__PROTOCOL=smtp+starttls",
    "FORGEJO__markdown__ENABLE_HARD_LINE_BREAK_IN_COMMENTS=false",
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

# Register each scoped runner in Forgejo's database using offline registration.
# Re-runs whenever the runner's secret rotates.
resource "terraform_data" "forgejo_runner_registration" {
  for_each         = var.forgejo_runners
  triggers_replace = random_id.forgejo_runner_secret[each.key].hex

  provisioner "local-exec" {
    command = <<-EOT
      for i in $(seq 1 36); do
        ssh kcfam docker exec -u git forgejo forgejo forgejo-cli actions register \
          --name forgejo-runner-${each.key} \
          --scope ${each.value.scope} \
          --secret "${random_id.forgejo_runner_secret[each.key].hex}" && break
        echo "Forgejo not ready yet, retrying in 10s..."
        sleep 10
      done
    EOT
  }

  depends_on = [docker_container.forgejo]
}

resource "docker_container" "forgejo_runner" {
  for_each = var.forgejo_runners
  name     = "forgejo_runner_${each.key}"
  image    = docker_image.forgejo_runner.image_id
  restart  = "always"
  user     = "root"

  # Secrets and per-runner resource limits passed via env; never appear in command args.
  env = [
    "RUNNER_SECRET=${random_id.forgejo_runner_secret[each.key].hex}",
    "RUNNER_TIMEOUT=${each.value.timeout}",
    "RUNNER_MEMORY=${each.value.memory}",
    "RUNNER_CPUS=${each.value.cpus}",
  ]

  # On first start, register the runner then start the daemon.
  # The baked config.yml is copied to /data and patched with per-runner values before starting.
  command = [
    "/bin/sh", "-c",
    <<-EOT
      cd /data
      [ -f /data/.runner ] || forgejo-runner create-runner-file \
        --instance http://forgejo:3000 \
        --secret "$RUNNER_SECRET" \
        --name forgejo-runner-${each.key}
      cp /etc/forgejo-runner/config.yml /data/config.yml
      sed -i "s|^  timeout:.*|  timeout: $RUNNER_TIMEOUT|" /data/config.yml
      sed -i "s|--memory=[^ \"]*|--memory=$RUNNER_MEMORY|" /data/config.yml
      sed -i "s|--cpus=[^ \"]*|--cpus=$RUNNER_CPUS|" /data/config.yml
      forgejo-runner daemon --config /data/config.yml
    EOT
  ]

  volumes {
    volume_name    = docker_volume.forgejo_runner_volumes[each.key].name
    container_path = "/data"
  }

  # Mount host Docker socket so the runner can spin up job containers.
  # docker_host in config.yml stays "-" so job containers don't get Docker access.
  volumes {
    host_path      = "/var/run/docker.sock"
    container_path = "/var/run/docker.sock"
  }

  networks_advanced {
    name = docker_network.default.name
  }

  depends_on = [terraform_data.forgejo_runner_registration]
}
