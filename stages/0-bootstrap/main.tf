provider "google" {
  region = var.region
}

locals {
  seed_project_id = "banorte-bootstrap-seed"

  labels = {
    env         = "bootstrap"
    app         = "landing-zone"
    owner       = "equipo-plataforma"
    cost_center = "0000"
  }
}

resource "google_folder" "bootstrap" {
  display_name        = "bootstrap"
  parent              = "organizations/${var.org_id}"
  deletion_protection = true
}

module "seed_project" {
  source = "../../modules/project-factory"

  environment     = "bootstrap"
  domain          = "seed"
  project_id      = local.seed_project_id
  folder_id       = google_folder.bootstrap.folder_id
  billing_account = var.billing_account
  labels          = local.labels

  activate_apis = [
    "accesscontextmanager.googleapis.com",
    "cloudbilling.googleapis.com",
    "cloudkms.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "logging.googleapis.com",
    "orgpolicy.googleapis.com",
    "secretmanager.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "sts.googleapis.com",
  ]
}

# Auditoría completa: el proyecto guarda estado y cuentas de Terraform.
resource "google_project_iam_audit_config" "seed" {
  project = module.seed_project.project_id
  service = "allServices"

  audit_log_config {
    log_type = "ADMIN_READ"
  }

  audit_log_config {
    log_type = "DATA_READ"
  }

  audit_log_config {
    log_type = "DATA_WRITE"
  }
}

module "kms" {
  source = "../../modules/kms"

  project_id  = module.seed_project.project_id
  environment = "bootstrap"
  domain      = "seed"
  location    = var.region
  key_name    = "tfstate"
  labels      = local.labels

  depends_on = [module.seed_project]
}

# Agente de servicio de GCS; email desconocido hasta crear el proyecto.
data "google_storage_project_service_account" "gcs" {
  project = module.seed_project.project_id

  depends_on = [module.seed_project]
}

resource "google_kms_crypto_key_iam_member" "gcs_agent" {
  crypto_key_id = module.kms.crypto_key_id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:${data.google_storage_project_service_account.gcs.email_address}"
}

module "state_bucket" {
  source = "../../modules/storage"

  project_id  = module.seed_project.project_id
  environment = "bootstrap"
  domain      = "seed"
  name_suffix = "tfstate"
  location    = var.region
  kms_key_id  = module.kms.crypto_key_id
  labels      = local.labels

  lifecycle_rules = [
    {
      action    = { type = "Delete" }
      condition = { num_newer_versions = 20, with_state = "ARCHIVED" }
    },
  ]

  # CMEK requiere el permiso previo del agente.
  depends_on = [google_kms_crypto_key_iam_member.gcs_agent]
}
