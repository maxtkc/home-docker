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

resource "docker_image" "forgejo_runner" {
  name         = "kcfam/forgejo-runner:local"
  keep_locally = true

  build {
    context = "${path.cwd}/../forgejo_runner"
  }

  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset("${path.cwd}/../forgejo_runner", "**") : filesha1("${path.cwd}/../forgejo_runner/${f}")]))
  }
}


resource "docker_image" "static_sites" {
  name         = "kcfam/static-sites:local"
  keep_locally = true

  build {
    context = "${path.cwd}/../static-sites"
  }

  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset("${path.cwd}/../static-sites", "**") : filesha1("${path.cwd}/../static-sites/${f}")]))
  }
}

resource "docker_image" "cors_proxy" {
  name         = "kcfam/cors-proxy:local"
  keep_locally = true

  build {
    context = "${path.cwd}/../cors-proxy"
  }

  triggers = {
    dir_sha1 = sha1(join("", [for f in fileset("${path.cwd}/../cors-proxy", "**") : filesha1("${path.cwd}/../cors-proxy/${f}")]))
  }
}

# tgtg built from a local checkout of the fork (travel mode). Only the files the
# image's .dockerignore lets through feed the trigger, so .git and .venv are ignored.
locals {
  tgtg_fork_files = var.tgtg_fork_path == null ? [] : concat(
    tolist(fileset(var.tgtg_fork_path, "tgtg_scanner/**")),
    tolist(fileset(var.tgtg_fork_path, "docker/**")),
    ["pyproject.toml", "poetry.lock", "requirements.txt", "README.md"],
  )
}

resource "docker_image" "tgtg" {
  count        = var.tgtg_fork_path != null ? 1 : 0
  name         = "kcfam/tgtg:local"
  keep_locally = true

  build {
    context    = var.tgtg_fork_path
    dockerfile = "docker/Dockerfile.alpine"
  }

  triggers = {
    dir_sha1 = sha1(join("", [for f in local.tgtg_fork_files : filesha1("${var.tgtg_fork_path}/${f}")]))
  }
}
