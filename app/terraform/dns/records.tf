# TTL court (minimum autorise par OVH) le temps de stabiliser les IP :
# a augmenter une fois l'infra moins volatile.
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
