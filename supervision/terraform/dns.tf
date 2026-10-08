# Le DNS de Grafana suit le cycle de vie de la supervision
resource "ovh_domain_zone_record" "monitoring" {
  zone      = var.dns_zone
  subdomain = "ghost-monitoring"
  fieldtype = "A"
  ttl       = 60
  target    = module.supervision_instance.public_ip
}
