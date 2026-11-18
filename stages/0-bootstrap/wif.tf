resource "google_iam_workload_identity_pool" "github" {
  project                   = module.seed_project.project_id
  workload_identity_pool_id = "banorte-bootstrap-github"
  display_name              = "GitHub Actions"
  description               = "Identidades de GitHub Actions para Terraform."

  depends_on = [module.seed_project]
}

resource "google_iam_workload_identity_pool_provider" "github" {
  #checkov:skip=CKV_GCP_125:attribute_condition fija var.github_repo; checkov no resuelve la variable.
  project                            = module.seed_project.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = "github-oidc"
  display_name                       = "GitHub OIDC"

  attribute_mapping = {
    "google.subject"             = "assertion.sub"
    "attribute.repository"       = "assertion.repository"
    "attribute.repository_owner" = "assertion.repository_owner"
    "attribute.ref"              = "assertion.ref"
  }

  # Solo el repositorio autorizado.
  attribute_condition = "assertion.repository == \"${var.github_repo}\""

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# El repositorio puede suplantar las cuentas de Terraform.
resource "google_service_account_iam_member" "github_wif" {
  for_each = google_service_account.tf

  service_account_id = each.value.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github.name}/attribute.repository/${var.github_repo}"
}
