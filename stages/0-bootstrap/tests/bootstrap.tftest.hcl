mock_provider "google" {}

mock_provider "google-beta" {}

variables {
  org_id          = "123456789012"
  billing_account = "0A0A0A-0B0B0B-0C0C0C"
  github_repo     = "mi-org/gcp-terraform"
  region          = "us-central1"
}

run "nombres_y_cmek" {
  command = plan

  assert {
    condition     = module.seed_project.project_id == "banorte-bootstrap-seed"
    error_message = "Proyecto semilla con nombre incorrecto."
  }

  assert {
    condition     = module.state_bucket.name == "banorte-bootstrap-seed-tfstate"
    error_message = "Bucket de estado con nombre incorrecto."
  }

  assert {
    condition     = google_folder.bootstrap.display_name == "bootstrap" && google_folder.bootstrap.parent == "organizations/123456789012"
    error_message = "Carpeta bootstrap mal ubicada."
  }

  assert {
    condition     = google_kms_crypto_key_iam_member.gcs_agent.role == "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    error_message = "El agente de GCS debe poder usar la llave."
  }
}

run "cuentas_y_roles" {
  command = plan

  assert {
    condition     = toset([for sa in google_service_account.tf : sa.account_id]) == toset(["sa-tf-org", "sa-tf-security", "sa-tf-networks", "sa-tf-projects", "sa-tf-workloads"])
    error_message = "Cuentas de servicio incorrectas."
  }

  assert {
    condition     = !anytrue([for b in google_organization_iam_member.tf : b.role == "roles/editor" || b.role == "roles/owner"])
    error_message = "No se permiten roles básicos a nivel organización."
  }

  assert {
    condition     = length([for k, _ in google_organization_iam_member.tf : k if startswith(k, "workloads/")]) == 0
    error_message = "sa-tf-workloads no debe tener roles en la organización."
  }

  assert {
    condition     = google_billing_account_iam_member.projects_billing_user.role == "roles/billing.user"
    error_message = "sa-tf-projects requiere billing.user."
  }
}

run "condiciones_por_prefijo" {
  command = plan

  assert {
    condition     = strcontains(google_storage_bucket_iam_member.state_rw["networks"].condition[0].expression, "/objects/3-networks/\")")
    error_message = "sa-tf-networks debe escribir solo en 3-networks/."
  }

  assert {
    condition     = google_storage_bucket_iam_member.state_read_previous["org"].condition[0].expression == "resource.name.startsWith(\"projects/_/buckets/banorte-bootstrap-seed-tfstate/objects/0-bootstrap/\")"
    error_message = "sa-tf-org solo debe leer 0-bootstrap/."
  }

  assert {
    condition = alltrue([
      for p in ["0-bootstrap", "1-org", "2-security", "3-networks"] :
      strcontains(google_storage_bucket_iam_member.state_read_previous["projects"].condition[0].expression, "/objects/${p}/")
    ]) && !strcontains(google_storage_bucket_iam_member.state_read_previous["projects"].condition[0].expression, "5-workloads")
    error_message = "sa-tf-projects debe leer solo etapas 0-3."
  }

  assert {
    condition     = google_storage_bucket_iam_member.state_rw["org"].role == "roles/storage.objectUser" && google_storage_bucket_iam_member.state_read_previous["org"].role == "roles/storage.objectViewer"
    error_message = "Roles de bucket incorrectos."
  }
}

run "wif_solo_repositorio" {
  command = plan

  assert {
    condition     = google_iam_workload_identity_pool_provider.github.attribute_condition == "assertion.repository == \"mi-org/gcp-terraform\""
    error_message = "attribute_condition debe limitar al repositorio."
  }

  assert {
    condition     = google_iam_workload_identity_pool_provider.github.oidc[0].issuer_uri == "https://token.actions.githubusercontent.com"
    error_message = "Issuer OIDC incorrecto."
  }
}

run "rechaza_repo_invalido" {
  command = plan

  variables {
    github_repo = "solo-repo"
  }

  expect_failures = [var.github_repo]
}

run "rechaza_region_no_permitida" {
  command = plan

  variables {
    region = "us-west1"
  }

  expect_failures = [var.region]
}
