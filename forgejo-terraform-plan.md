# Forgejo Terraform Plan

Two-layer approach: Docker provider deploys the container; svalabs/forgejo provider manages
Forgejo configuration (users, orgs, repos). The Forgejo provider requires the instance to be
running first, so there's a bootstrap step in the middle.

## Phase 1: Deploy the Container

### `tf/terraform.tf`
Add to `required_providers`:
```hcl
forgejo = {
  source  = "svalabs/forgejo"
  version = "~> 1.2"
}
```

### `tf/providers.tf`
```hcl
provider "forgejo" {
  host      = "https://git.kcfam.us"
  api_token = var.forgejo_api_token
}
```

### `tf/variables.tf`
```hcl
variable "forgejo_db_password" {
  type      = string
  sensitive = true
}

variable "forgejo_api_token" {
  type      = string
  sensitive = true
  default   = ""  # empty until bootstrap complete
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

4. **Add to `secrets.auto.tfvars`**:
   ```
   forgejo_api_token = "<token>"
   ```

---

## Phase 2: Manage Forgejo Resources

### `tf/compute_forgejo.tf` (additions after bootstrap)
Example resources to manage declaratively:
```hcl
resource "forgejo_user" "admin" {
  login    = "maxtkc"
  # ... other fields
}

resource "forgejo_organization" "kcfam" {
  name = "kcfam"
}
```

---

## Order of Operations

1. Create DB user/database manually (or via a null_resource if desired)
2. Add `forgejo_db_password` to `secrets.auto.tfvars` (leave `forgejo_api_token = ""`)
3. `tofu init` (picks up new svalabs/forgejo provider)
4. `tofu apply` (deploys container only; Forgejo provider resources are added later)
5. Bootstrap: create admin API token via UI
6. Add `forgejo_api_token` to `secrets.auto.tfvars`
7. Add Forgejo provider resources (users, orgs, repos) to tf files
8. `tofu apply` again
