# TTL minimal OVH : les IP changent a chaque reconstruction
resource "ovh_domain_zone_record" "app" {
  zone      = var.dns_zone
  subdomain = "ghost"
  fieldtype = "A"
  ttl       = 60
  target    = data.terraform_remote_state.instances.outputs.app_public_ip
}

resource "ovh_domain_zone_record" "staging" {
  zone      = var.dns_zone
  subdomain = "ghost-staging"
  fieldtype = "A"
  ttl       = 60
  target    = data.terraform_remote_state.instances.outputs.staging_public_ip
}

# Prefixe ghost- : zone partagee avec le VPN Sophos
resource "ovh_domain_zone_record" "monitoring" {
  # Pas d'enregistrement si la supervision n'existe pas
  count = var.supervision_public_ip != "" ? 1 : 0

  zone      = var.dns_zone
  subdomain = "ghost-monitoring"
  fieldtype = "A"
  ttl       = 60
  target    = var.supervision_public_ip
}
