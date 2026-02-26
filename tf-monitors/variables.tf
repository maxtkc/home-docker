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

variable "telegram_bot_token" {
  type        = string
  description = "Telegram bot token for Uptime Kuma notifications"
  sensitive   = true
}

variable "telegram_chat_id" {
  type        = string
  description = "Telegram chat ID to send notifications to"
}
