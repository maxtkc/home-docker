# Forgejo Terraform Plan

Two-layer approach: the Docker container lives in `tf/` (like all other services); Forgejo
API resources (users, orgs, repos) live in a separate `tf-forgejo/` module — mirroring how
`tf-monitors/` manages Uptime Kuma independently from the main infrastructure. The Forgejo
provider requires the instance to be running first, so there's a bootstrap step in the middle.

## Phase 1: Deploy the Container (in `tf/`)

### `tf/variables.tf`
```hcl
variable "forgejo_db_password" {
  type      = string
  sensitive = true
}
```

### `tf/random.tf`
```hcl
resource "random_password" "forgejo_secret_key" {
  length  = 64
  special = false
}
```

### `tf/volumes.tf`
```hcl
resource "docker_volume" "forgejo_data" {
  name = "nextcloud_forgejo_data"
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [labels]
  }
}
```

### `tf/compute_forgejo.tf` (new file)
```hcl
resource "docker_container" "forgejo" {
  name    = "forgejo"
  image   = "codeberg.org/forgejo/forgejo:11"
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
    "FORGEJO__security__SECRET_KEY=${random_password.forgejo_secret_key.result}",
    "FORGEJO__service__DISABLE_REGISTRATION=true",
  ]

  volumes {
    volume_name    = docker_volume.forgejo_data.name
    container_path = "/data"
  }

  networks_advanced { name = docker_network.proxy_tier.name }
  networks_advanced { name = docker_network.default.name }

  labels { label = "traefik.enable"; value = "true" }
  labels { label = "traefik.http.routers.forgejo.rule"; value = "Host(`git.kcfam.us`)" }
  labels { label = "traefik.http.routers.forgejo.tls"; value = "true" }
  labels { label = "traefik.http.routers.forgejo.tls.certresolver"; value = "letsencrypt" }
  labels { label = "traefik.http.services.forgejo.loadbalancer.server.port"; value = "3000" }
  labels { label = "backup.stop"; value = "true" }
}
```

### `tf/compute_misc.tf` — `backup_monthly` container
Add forgejo volume:
```hcl
volumes {
  volume_name    = docker_volume.forgejo_data.name
  container_path = "/backup/forgejo_data"
  read_only      = true
}
```

---

## Bootstrap Step (manual, between Phase 1 and Phase 2)

After `tofu apply` deploys the container:

1. **Create the Forgejo DB** on the shared `db` container:
   ```bash
   docker exec -it <db_container> psql -U postgres \
     -c "CREATE USER forgejo WITH PASSWORD '<forgejo_db_password>';" \
     -c "CREATE DATABASE forgejo OWNER forgejo;"
   ```
   (Do this *before* first `tofu apply`, since Forgejo will try to connect on startup.)

2. **Complete initial setup** — visit `https://git.kcfam.us` or it auto-configures from env.

3. **Create admin API token** — Forgejo UI → Settings → Applications → Generate token
   with scopes: `write:organization`, `write:repository`, `write:user`, `write:admin`.

4. **Add to `tf-forgejo/secrets.auto.tfvars`**:
   ```
   forgejo_api_token = "<token>"
   ```

---

## Phase 2: Manage Forgejo Resources (in `tf-forgejo/`)

A separate module keeps the Forgejo provider isolated — it only works once the instance is
running, and its lifecycle is independent of the main infrastructure (same pattern as
`tf-monitors/` for Uptime Kuma).

### `tf-forgejo/terraform.tf`
```hcl
terraform {
  required_providers {
    forgejo = {
      source  = "svalabs/forgejo"
      version = "~> 1.2"
    }
  }
  backend "local" {}
}
```

### `tf-forgejo/providers.tf`
```hcl
provider "forgejo" {
  host      = "https://git.kcfam.us"
  api_token = var.forgejo_api_token
}
```

### `tf-forgejo/variables.tf`
```hcl
variable "forgejo_api_token" {
  type      = string
  sensitive = true
}
```

### `tf-forgejo/resources.tf`
```hcl
resource "forgejo_user" "admin" {
  login = "maxtkc"
  # ... other fields
}

resource "forgejo_organization" "kcfam" {
  name = "kcfam"
}
```

---

## Order of Operations

1. Create DB user/database manually on the `db` container
2. Add `forgejo_db_password` to `tf/secrets.auto.tfvars`
3. `cd tf && tofu init && tofu apply` (deploys container)
4. Bootstrap: complete setup and create admin API token via UI
5. Create `tf-forgejo/` directory with files above
6. Add `forgejo_api_token` to `tf-forgejo/secrets.auto.tfvars`
7. `cd tf-forgejo && tofu init && tofu apply`
