mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id  = "banorte-dev-sec-kms"
  environment = "dev"
  domain      = "sec"
  labels = {
    env         = "dev"
    app         = "landing-zone"
    owner       = "equipo-plataforma"
    cost_center = "0000"
  }
  encrypter_decrypter_members = [
    "serviceAccount:app@banorte-dev-sec-kms.iam.gserviceaccount.com",
  ]
}

run "rotacion_90_dias" {
  command = plan

  assert {
    condition     = google_kms_crypto_key.protected[0].rotation_period == "7776000s"
    error_message = "La rotación por defecto debe ser 7776000s (90 días)."
  }

  assert {
    condition     = length(google_kms_crypto_key.unprotected) == 0
    error_message = "Con prevent_destroy=true solo debe existir la llave protegida."
  }

  assert {
    condition     = google_kms_crypto_key.protected[0].labels["managed_by"] == "terraform"
    error_message = "La llave debe llevar managed_by = terraform."
  }

  assert {
    condition     = google_kms_key_ring.this.name == "banorte-dev-sec-kr"
    error_message = "El key ring no sigue la convención de nombres."
  }
}

run "iam_encrypter_decrypter" {
  command = plan

  assert {
    condition = alltrue([
      for m in google_kms_crypto_key_iam_member.encrypter_decrypter :
      m.role == "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    ])
    error_message = "Rol IAM incorrecto."
  }

  assert {
    condition     = length(google_kms_crypto_key_iam_member.encrypter_decrypter) == 1
    error_message = "Se espera un binding por cuenta de servicio."
  }
}

run "sin_prevent_destroy" {
  command = plan

  variables {
    prevent_destroy = false
  }

  assert {
    condition     = length(google_kms_crypto_key.protected) == 0 && google_kms_crypto_key.unprotected[0].rotation_period == "7776000s"
    error_message = "Con prevent_destroy=false debe usarse la llave no protegida con rotación de 90 días."
  }
}

run "rechaza_rotacion_mayor_90_dias" {
  command = plan

  variables {
    rotation_period = "7776001s"
  }

  expect_failures = [var.rotation_period]
}

run "rechaza_region_no_permitida" {
  command = plan

  variables {
    location = "europe-west1"
  }

  expect_failures = [var.location]
}

run "rechaza_miembro_no_sa" {
  command = plan

  variables {
    encrypter_decrypter_members = ["user:alguien@example.com"]
  }

  expect_failures = [var.encrypter_decrypter_members]
}
