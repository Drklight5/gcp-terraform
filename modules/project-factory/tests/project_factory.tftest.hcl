mock_provider "google" {}
mock_provider "google-beta" {}

variables {
  environment     = "dev"
  domain          = "data"
  name_suffix     = "app"
  folder_id       = "folders/123456789012"
  billing_account = "0A0A0A-0B0B0B-0C0C0C"
  activate_apis   = ["storage.googleapis.com", "cloudkms.googleapis.com"]
  labels = {
    env         = "dev"
    app         = "landing-zone"
    owner       = "equipo-plataforma"
    cost_center = "0000"
  }
}

run "etiquetas_obligatorias" {
  command = plan

  assert {
    condition = alltrue([
      for k in ["env", "app", "owner", "cost_center", "managed_by"] :
      contains(keys(google_project.this.labels), k)
    ])
    error_message = "El proyecto no tiene las etiquetas obligatorias."
  }

  assert {
    condition     = google_project.this.labels["managed_by"] == "terraform" && google_project.this.labels["env"] == "dev"
    error_message = "managed_by debe ser terraform y env debe coincidir con environment."
  }

  assert {
    condition     = google_project.this.project_id == "banorte-dev-data-app" && google_project.this.folder_id == "123456789012"
    error_message = "ID o carpeta incorrectos."
  }

  assert {
    condition     = google_project.this.auto_create_network == false
    error_message = "No debe crearse la red default."
  }
}

run "apis_y_opcionales_desactivados" {
  command = plan

  assert {
    condition     = length(google_project_service.this) == 2 && contains(keys(google_project_service.this), "cloudkms.googleapis.com")
    error_message = "APIs habilitadas incorrectas."
  }

  assert {
    condition     = length(google_compute_shared_vpc_service_project.this) == 0 && length(google_billing_budget.this) == 0
    error_message = "Shared VPC y presupuesto deben estar desactivados por defecto."
  }
}

run "shared_vpc_y_presupuesto" {
  command = plan

  variables {
    shared_vpc_host_project_id = "banorte-dev-net-host"
    enable_budget              = true
    budget_amount              = 5000
  }

  assert {
    condition     = google_compute_shared_vpc_service_project.this[0].host_project == "banorte-dev-net-host"
    error_message = "Proyecto host incorrecto."
  }

  assert {
    condition     = contains(keys(google_project_service.this), "compute.googleapis.com")
    error_message = "Shared VPC requiere compute.googleapis.com."
  }

  assert {
    condition     = length(google_billing_budget.this[0].threshold_rules) == 3 && google_billing_budget.this[0].amount[0].specified_amount[0].units == "5000"
    error_message = "Presupuesto mal configurado."
  }
}

run "rechaza_etiquetas_incompletas" {
  command = plan

  variables {
    labels = { env = "dev", owner = "equipo-plataforma" }
  }

  expect_failures = [var.labels]
}

run "rechaza_entorno_invalido" {
  command = plan

  variables {
    environment = "test"
  }

  expect_failures = [var.environment]
}

run "rechaza_billing_invalido" {
  command = plan

  variables {
    billing_account = "123"
  }

  expect_failures = [var.billing_account]
}

run "project_id_explicito_bootstrap" {
  command = plan

  variables {
    environment = "bootstrap"
    domain      = "seed"
    name_suffix = null
    project_id  = "banorte-bootstrap-seed"
    labels = {
      env         = "bootstrap"
      app         = "landing-zone"
      owner       = "equipo-plataforma"
      cost_center = "0000"
    }
  }

  assert {
    condition     = google_project.this.project_id == "banorte-bootstrap-seed" && google_project.this.labels["env"] == "bootstrap"
    error_message = "El ID explícito o la etiqueta env no se aplicaron."
  }
}

run "rechaza_sin_id_ni_sufijo" {
  command = plan

  variables {
    name_suffix = null
  }

  expect_failures = [google_project.this]
}
