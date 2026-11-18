output "bootstrap_folder_id" {
  description = "ID de la carpeta bootstrap (folders/<id>)."
  value       = google_folder.bootstrap.name
}

output "seed_project_id" {
  description = "ID del proyecto semilla."
  value       = module.seed_project.project_id
}

output "tfstate_bucket" {
  description = "Bucket de estado de Terraform."
  value       = module.state_bucket.name
}

output "tfstate_kms_key_id" {
  description = "Llave CMEK del bucket de estado."
  value       = module.kms.crypto_key_id
}

output "service_accounts" {
  description = "Correos de las cuentas de servicio de Terraform por etapa."
  value       = { for k, sa in google_service_account.tf : k => sa.email }
}

output "wif_provider" {
  description = "Nombre completo del proveedor WIF (valor de workload_identity_provider en google-github-actions/auth)."
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "wif_pool" {
  description = "Nombre completo del pool de Workload Identity."
  value       = google_iam_workload_identity_pool.github.name
}
