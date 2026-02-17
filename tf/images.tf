# Custom images built from local Dockerfiles and pushed to the remote Docker daemon.
# Terraform streams the build context over SSH — no local Docker access required.
# Images are rebuilt automatically when any file in the build context changes.

resource "docker_image" "nextcloud" {
  name         = "kcfam/nextcloud:local"
  keep_locally = true

  build {
    context = "${path.cwd}/../my_nc"
  }

  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset("${path.cwd}/../my_nc", "**") : filesha1("${path.cwd}/../my_nc/${f}")]))
  }
}

resource "docker_image" "nextcloud_web" {
  name         = "kcfam/nextcloud-web:local"
  keep_locally = true

  build {
    context = "${path.cwd}/../web"
  }

  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset("${path.cwd}/../web", "**") : filesha1("${path.cwd}/../web/${f}")]))
  }
}

resource "docker_image" "traefik" {
  name         = "kcfam/traefik:local"
  keep_locally = true

  build {
    context = "${path.cwd}/../traefik"
  }

  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset("${path.cwd}/../traefik", "**") : filesha1("${path.cwd}/../traefik/${f}")]))
  }
}

resource "docker_image" "grafana" {
  name         = "kcfam/grafana:local"
  keep_locally = true

  build {
    context = "${path.cwd}/../grafana"
  }

  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset("${path.cwd}/../grafana", "**") : filesha1("${path.cwd}/../grafana/${f}")]))
  }
}

resource "docker_image" "prometheus" {
  name         = "kcfam/prometheus:local"
  keep_locally = true

  build {
    context = "${path.cwd}/../prometheus"
  }

  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset("${path.cwd}/../prometheus", "**") : filesha1("${path.cwd}/../prometheus/${f}")]))
  }
}
