# All output blocks in alphabetical order.

output "grafana_admin_password" {
  description = "Generated Grafana admin password"
  value       = random_password.grafana_admin.result
  sensitive   = true
}

