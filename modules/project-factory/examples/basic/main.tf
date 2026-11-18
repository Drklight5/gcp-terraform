provider "google" {
  region                = "us-central1"
  user_project_override = true
  billing_project       = "banorte-dev-seed"
}

module "project" {
  source = "../.."

  environment     = "dev"
  domain          = "data"
  name_suffix     = "app"
  folder_id       = "folders/000000000000"
  billing_account = "000000-000000-000000"

  activate_apis = [
    "compute.googleapis.com",
    "storage.googleapis.com",
    "cloudkms.googleapis.com",
  ]

  shared_vpc_host_project_id = "banorte-dev-net-host"

  enable_budget   = true
  budget_amount   = 10000
  budget_currency = "MXN"

  labels = {
    env         = "dev"
    app         = "landing-zone"
    owner       = "equipo-plataforma"
    cost_center = "0000"
  }
}

output "project_id" {
  value = module.project.project_id
}
