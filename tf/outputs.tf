# All output blocks in alphabetical order.

output "grafana_admin_password" {
  description = "Generated Grafana admin password"
  value       = random_password.grafana_admin.result
  sensitive   = true
}

output "openproject_secret_key_base" {
  description = "Generated OpenProject Rails secret key base"
  value       = random_password.openproject_secret_key_base.result
  sensitive   = true
}
