# Le DNS suit le cycle de vie des instances qu'il designe
resource "ovh_domain_zone_record" "app" {
  zone      = var.dns_zone
  subdomain = "ghost"
  fieldtype = "A"
  ttl       = 60
  target    = module.app_instance.public_ip
}

resource "ovh_domain_zone_record" "staging" {
  zone      = var.dns_zone
  subdomain = "ghost-staging"
  fieldtype = "A"
  ttl       = 60
  target    = module.staging_instance.public_ip
}
