locals {
  domain = "kcfam.us"
  ttl    = 600

  # Subdomains pointing to the root domain via CNAME
  subdomains = toset([
    "ssh",     # For ssh
    "nc",      # Nextcloud
    "im",      # Immich
    "gramps",  # GrampsWeb
    "gf",      # Grafana
    "uptime",  # Uptime Kuma
    "op",      # OpenProject
    "git",     # Forgejo
    "status",  # Uptime Kuma public status page
  ])
}

resource "porkbun_dns_record" "root" {
  domain    = local.domain
  subdomain = ""
  type      = "A"
  content   = var.server_ip
  ttl       = local.ttl
}

resource "porkbun_dns_record" "subdomains" {
  for_each = local.subdomains

  domain    = local.domain
  subdomain = each.key
  type      = "CNAME"
  content   = local.domain
  ttl       = local.ttl
}
