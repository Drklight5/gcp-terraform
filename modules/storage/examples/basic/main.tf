provider "google" {
  project = "banorte-dev-data-prj"
  region  = "us-central1"
}

module "storage" {
  source = "../.."

  project_id  = "banorte-dev-data-prj"
  environment = "dev"
  domain      = "data"
  name_suffix = "raw"
  location    = "us-central1"
  kms_key_id  = "projects/banorte-dev-sec-kms/locations/us-central1/keyRings/banorte-dev-sec-kr/cryptoKeys/banorte-dev-sec-storage"
  log_bucket  = "banorte-dev-data-logs"

  lifecycle_rules = [
    {
      action    = { type = "SetStorageClass", storage_class = "NEARLINE" }
      condition = { age = 30, with_state = "LIVE" }
    },
    {
      action    = { type = "Delete" }
      condition = { num_newer_versions = 5, with_state = "ARCHIVED" }
    },
  ]

  labels = {
    env         = "dev"
    app         = "landing-zone"
    owner       = "equipo-plataforma"
    cost_center = "0000"
  }
}

output "bucket_url" {
  value = module.storage.url
}
