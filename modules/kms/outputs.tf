output "key_ring_id" {
  description = "ID del key ring."
  value       = google_kms_key_ring.this.id
}

output "crypto_key_id" {
  description = "ID de la llave (projects/.../cryptoKeys/...), usable como default_kms_key_name."
  value       = local.crypto_key.id
}

output "crypto_key_name" {
  description = "Nombre de la llave."
  value       = local.crypto_key.name
}
