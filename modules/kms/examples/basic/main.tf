provider "google" {
  project = "banorte-dev-sec-kms"
  region  = "us-central1"
}

module "kms" {
  source = "../.."

  project_id  = "banorte-dev-sec-kms"
  environment = "dev"
  domain      = "sec"
  location    = "us-central1"
  key_name    = "storage"

  encrypter_decrypter_members = [
    "serviceAccount:service-000000000000@gs-project-accounts.iam.gserviceaccount.com",
  ]

  labels = {
    env         = "dev"
    app         = "landing-zone"
    owner       = "equipo-plataforma"
    cost_center = "0000"
  }
}

output "crypto_key_id" {
  value = module.kms.crypto_key_id
}
