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

resource "porkbun_dns_record" "external_domain_subdomains" {
  for_each  = var.external_domain_records
  domain    = each.value
  subdomain = each.key
  type      = "CNAME"
  content   = local.domain
  ttl       = local.ttl
}

resource "porkbun_dns_record" "google_site_verification" {
  count     = var.google_site_verification != null ? 1 : 0
  domain    = local.domain
  subdomain = ""
  type      = "TXT"
  content   = "google-site-verification=${var.google_site_verification}"
  ttl       = local.ttl
}
