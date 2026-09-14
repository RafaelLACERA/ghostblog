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

# "ghost-monitoring" et non "monitoring" tout court : la zone lacera.fr
# n'est pas dediee a ghostblog (ex: portail VPN Sophos deja sur cette
# meme zone) - prefixe explicite pour eviter toute ambiguite. IP recuperee
# via un lookup souple cote CI (voir app/terraform/dns/variables.tf), pas
# via terraform_remote_state - le state "supervision" peut n'avoir jamais
# ete applique.
resource "ovh_domain_zone_record" "monitoring" {
  count = var.supervision_public_ip != "" ? 1 : 0

  zone      = var.dns_zone
  subdomain = "ghost-monitoring"
  fieldtype = "A"
  ttl       = 60
  target    = var.supervision_public_ip
}
