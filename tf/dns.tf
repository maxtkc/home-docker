resource "porkbun_dns_record" "root" {
  domain    = local.domain
  subdomain = ""
  type      = "A"
  content   = var.server_ip
  ttl       = local.ttl
}

resource "porkbun_dns_record" "subdomains" {
  for_each  = local.dns_subdomains
  domain    = local.domain
  subdomain = each.key
  type      = "CNAME"
  content   = local.domain
  ttl       = local.ttl
}

resource "porkbun_dns_record" "static_sites" {
  for_each  = var.static_sites
  domain    = local.domain
  subdomain = each.key
  type      = "CNAME"
  content   = local.domain
  ttl       = local.ttl
}
