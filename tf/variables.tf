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

variable "google_site_verification" {
  type        = string
  description = "Google site verification token (the value after 'google-site-verification=')"
  default     = null
  nullable    = true
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

variable "tgtg_version" {
  type        = string
  description = "derhenning/tgtg image tag"
  default     = "latest-alpine"
}

variable "openproject_version" {
  type        = string
  description = "OpenProject image tag"
  default     = "17-slim"
}

variable "openproject_postgres_version" {
  type        = string
  description = "PostgreSQL image tag used by OpenProject"
  default     = "17"
}

variable "openproject_hocuspocus_enabled" {
  type        = bool
  description = "Whether to enable the collaborative editing (Hocuspocus) container"
  default     = false
}

variable "openproject_hocuspocus_version" {
  type        = string
  description = "OpenProject Hocuspocus image tag"
  default     = "17.1.1"
}

variable "openproject_db_password" {
  type        = string
  description = "PostgreSQL password for the OpenProject database user"
  sensitive   = true
}

variable "openproject_secret_key_base" {
  type        = string
  description = "Rails secret key base for OpenProject"
  sensitive   = true
}

variable "openproject_hocuspocus_secret" {
  type        = string
  description = "Shared secret between OpenProject and Hocuspocus for collaborative editing"
  sensitive   = true
  nullable    = true
  default     = null
}

variable "forgejo_disable_registration" {
  type        = bool
  description = "Disable public registration on Forgejo"
  default     = false
}

variable "forgejo_register_email_confirm" {
  type        = bool
  description = "Require email confirmation to complete registration"
  default     = true
}

variable "forgejo_enable_notify_mail" {
  type        = bool
  description = "Send email notifications to watchers on issues, PRs, etc."
  default     = true
}

variable "forgejo_show_registration_button" {
  type        = bool
  description = "Show the register button on the login page"
  default     = true
}

variable "forgejo_enable_captcha" {
  type        = bool
  description = "Require captcha on registration"
  default     = true
}

variable "forgejo_captcha_type" {
  type        = string
  description = "Captcha type: image, recaptcha, hcaptcha, mcaptcha, cfturnstile"
  default     = "image"
}

variable "smtp_email" {
  type        = string
  description = "Gmail address used as the SMTP sender"
  sensitive   = true
}

variable "smtp_password" {
  type        = string
  description = "Gmail App Password for SMTP"
  sensitive   = true
}

# TGTG account
variable "tgtg_username" {
  type      = string
  sensitive = true
}

# Main settings
variable "tgtg_sleep_time" {
  type     = number
  nullable = true
  default  = null
}

variable "tgtg_tz" {
  type     = string
  nullable = true
  default  = null
}

variable "tgtg_locale" {
  type     = string
  nullable = true
  default  = null
}

# Must match the port hardcoded in traefik/dynamic/tgtg.yml
variable "tgtg_port" {
  type    = number
  default = 3000
}

variable "tgtg_metrics" {
  type     = bool
  nullable = true
  default  = null
}

variable "tgtg_metrics_port" {
  type     = number
  nullable = true
  default  = null
}

variable "tgtg_disable_tests" {
  type     = bool
  nullable = true
  default  = null
}

variable "tgtg_quiet" {
  type     = bool
  nullable = true
  default  = null
}


variable "tgtg_schedule_cron" {
  type     = string
  nullable = true
  default  = null
}

variable "tgtg_price_monitoring" {
  type     = bool
  nullable = true
  default  = null
}

# Telegram notifier
variable "tgtg_telegram" {
  type     = bool
  nullable = true
  default  = null
}

variable "tgtg_telegram_token" {
  type      = string
  sensitive = true
  nullable  = true
  default   = null
}

variable "tgtg_telegram_chat_ids" {
  type      = string
  sensitive = true
  nullable  = true
  default   = null
}

variable "tgtg_telegram_body" {
  type     = string
  nullable = true
  default  = null
}

variable "tgtg_telegram_disable_commands" {
  type     = bool
  nullable = true
  default  = null
}

variable "tgtg_telegram_only_reservations" {
  type     = bool
  nullable = true
  default  = null
}

variable "tgtg_telegram_cron" {
  type     = string
  nullable = true
  default  = null
}
