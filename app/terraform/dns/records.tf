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

locals {
  # try() indispensable : le state "supervision" peut n'avoir jamais ete
  # deploye ou avoir ete detruit (cycle de vie independant, volontairement
  # pas de garde-fou bloquant ici, voir remote_state.tf).
  supervision_public_ip = try(data.terraform_remote_state.supervision.outputs.supervision_public_ip, null)
}

# "ghost-monitoring" et non "monitoring" tout court : la zone lacera.fr
# n'est pas dediee a ghostblog (ex: portail VPN Sophos deja sur cette
# meme zone) - prefixe explicite pour eviter toute ambiguite.
resource "ovh_domain_zone_record" "monitoring" {
  count = local.supervision_public_ip != null ? 1 : 0

  zone      = var.dns_zone
  subdomain = "ghost-monitoring"
  fieldtype = "A"
  ttl       = 60
  target    = local.supervision_public_ip
}
