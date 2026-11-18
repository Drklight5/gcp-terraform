locals {
  prefix = "banorte-${var.environment}-${var.domain}"

  labels = merge(var.labels, {
    env        = var.environment
    managed_by = "terraform"
  })

  crypto_key = var.prevent_destroy ? google_kms_crypto_key.protected[0] : google_kms_crypto_key.unprotected[0]
}

resource "google_kms_key_ring" "this" {
  project  = var.project_id
  name     = "${local.prefix}-kr"
  location = var.location
}

# lifecycle no admite variables: un recurso por modo.
resource "google_kms_crypto_key" "protected" {
  count = var.prevent_destroy ? 1 : 0

  name            = "${local.prefix}-${var.key_name}"
  key_ring        = google_kms_key_ring.this.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = var.rotation_period
  labels          = local.labels

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = var.protection_level
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key" "unprotected" {
  count = var.prevent_destroy ? 0 : 1

  name            = "${local.prefix}-${var.key_name}"
  key_ring        = google_kms_key_ring.this.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = var.rotation_period
  labels          = local.labels

  version_template {
    algorithm        = "GOOGLE_SYMMETRIC_ENCRYPTION"
    protection_level = var.protection_level
  }
}

resource "google_kms_crypto_key_iam_member" "encrypter_decrypter" {
  for_each = toset(var.encrypter_decrypter_members)

  crypto_key_id = local.crypto_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = each.value
}
