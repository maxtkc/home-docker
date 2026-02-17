variable "uptime_kuma_username" {
  type        = string
  description = "Uptime Kuma admin username"
  default     = "maxtkc"
}

variable "uptime_kuma_password" {
  type        = string
  description = "Uptime Kuma admin password"
  sensitive   = true
}
