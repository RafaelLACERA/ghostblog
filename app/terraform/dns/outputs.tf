output "app_fqdn" {
  description = "Nom de domaine complet de la production"
  value       = "${ovh_domain_zone_record.app.subdomain}.${ovh_domain_zone_record.app.zone}"
}

output "staging_fqdn" {
  description = "Nom de domaine complet du staging"
  value       = "${ovh_domain_zone_record.staging.subdomain}.${ovh_domain_zone_record.staging.zone}"
}
