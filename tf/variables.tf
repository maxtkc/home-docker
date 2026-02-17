# All input variables in alphabetical order.
# Secrets are declared with sensitive = true and supplied via secrets.auto.tfvars.

variable "db_password" {
  type        = string
  description = "PostgreSQL password for the Nextcloud database user"
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
