variable "porkbun_api_key" {
  type        = string
  description = "Porkbun API key"
  sensitive   = true
}

variable "porkbun_secret_api_key" {
  type        = string
  description = "Porkbun secret API key"
  sensitive   = true
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
