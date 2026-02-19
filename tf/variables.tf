# All input variables in alphabetical order.
# Secrets are declared with sensitive = true and supplied via secrets.auto.tfvars.

variable "db_password" {
  type        = string
  description = "PostgreSQL password for the Nextcloud database user"
  sensitive   = true
}

variable "forgejo_db_password" {
  type        = string
  description = "PostgreSQL password for the Forgejo database user"
  sensitive   = true
}

variable "docker_host" {
  type        = string
  description = "Remote Docker daemon URI (e.g. ssh://kcfam)"
  default     = "ssh://kcfam"
}

variable "github_client_id" {
  type        = string
  description = "GitHub OAuth app client ID for Grafana SSO"
  sensitive   = true
}

variable "github_client_secret" {
  type        = string
  description = "GitHub OAuth app client secret for Grafana SSO"
  sensitive   = true
}

variable "immich_db_password" {
  type        = string
  description = "PostgreSQL password for the Immich database user"
  sensitive   = true
}

variable "porkbun_api_key" {
  type      = string
  sensitive = true
}

variable "porkbun_secret_api_key" {
  type      = string
  sensitive = true
}

variable "server_ip" {
  type        = string
  description = "Public IP address of the home server"
}

variable "static_sites" {
  type        = set(string)
  description = "Subdomains to create as CNAME records for static site hosting"
  default     = []
}

# Image versions — pin these to specific digests or tags for reproducible deployments.

variable "cadvisor_version" {
  type        = string
  description = "cAdvisor image tag"
  default     = "latest"
}

variable "docker_volume_backup_version" {
  type        = string
  description = "offen/docker-volume-backup image tag"
  default     = "latest"
}

variable "grampsweb_redis_version" {
  type        = string
  description = "Redis image tag used by GrampsWeb"
  default     = "7.2.4-alpine"
}

variable "grampsweb_version" {
  type        = string
  description = "GrampsWeb image tag"
  default     = "latest"
}

variable "immich_postgres_version" {
  type        = string
  description = "pgvecto-rs image tag used by Immich"
  default     = "pg14-v0.2.0"
}

variable "immich_version" {
  type        = string
  description = "Immich server and machine-learning image tag"
  default     = "v2.3.1"
}

variable "node_exporter_version" {
  type        = string
  description = "Prometheus node-exporter image tag"
  default     = "latest"
}

variable "postgres_version" {
  type        = string
  description = "PostgreSQL image tag used by Nextcloud"
  default     = "15-alpine"
}

variable "redis_version" {
  type        = string
  description = "Redis image tag used by Nextcloud"
  default     = "alpine"
}

variable "sablier_version" {
  type        = string
  description = "Sablier image tag"
  default     = "1.10.1"
}

variable "uptime_kuma_version" {
  type        = string
  description = "Uptime Kuma image tag"
  default     = "latest"
}
