mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  project_id  = "banorte-dev-data-prj"
  environment = "dev"
  domain      = "data"
  name_suffix = "raw"
  kms_key_id  = "projects/banorte-dev-sec-kms/locations/us-central1/keyRings/banorte-dev-sec-kr/cryptoKeys/banorte-dev-sec-storage"
  labels = {
    env         = "dev"
    app         = "landing-zone"
    owner       = "equipo-plataforma"
    cost_center = "0000"
  }
  lifecycle_rules = [
    {
      action    = { type = "Delete" }
      condition = { num_newer_versions = 5, with_state = "ARCHIVED" }
    },
  ]
}

run "bucket_no_publico" {
  command = plan

  assert {
    condition     = google_storage_bucket.this.public_access_prevention == "enforced"
    error_message = "public_access_prevention debe ser enforced."
  }

  assert {
    condition     = google_storage_bucket.this.uniform_bucket_level_access == true
    error_message = "uniform_bucket_level_access debe ser true."
  }
}

run "versionado_cmek_y_etiquetas" {
  command = plan

  assert {
    condition     = google_storage_bucket.this.versioning[0].enabled == true
    error_message = "El versionado debe estar activo."
  }

  assert {
    condition     = google_storage_bucket.this.encryption[0].default_kms_key_name == var.kms_key_id
    error_message = "El bucket debe usar la llave CMEK."
  }

  assert {
    condition = alltrue([
      for k in ["env", "app", "owner", "cost_center", "managed_by"] :
      contains(keys(google_storage_bucket.this.labels), k)
    ])
    error_message = "Faltan etiquetas obligatorias."
  }

  assert {
    condition     = google_storage_bucket.this.labels["managed_by"] == "terraform"
    error_message = "managed_by debe ser terraform."
  }

  assert {
    condition     = google_storage_bucket.this.name == "banorte-dev-data-raw"
    error_message = "El bucket no sigue la convención de nombres."
  }

  assert {
    condition     = length(google_storage_bucket.this.lifecycle_rule) == 1
    error_message = "Se espera una regla de ciclo de vida."
  }
}

run "rechaza_etiquetas_incompletas" {
  command = plan

  variables {
    labels = { env = "dev", app = "landing-zone" }
  }

  expect_failures = [var.labels]
}

run "rechaza_kms_invalida" {
  command = plan

  variables {
    kms_key_id = "mi-llave"
  }

  expect_failures = [var.kms_key_id]
}

run "rechaza_region_no_permitida" {
  command = plan

  variables {
    location = "US"
  }

  expect_failures = [var.location]
}
