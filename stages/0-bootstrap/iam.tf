locals {
  # Orden de etapas = prefijos del bucket de estado.
  stage_prefixes = ["0-bootstrap", "1-org", "2-security", "3-networks", "4-projects", "5-workloads"]

  stages = {
    org       = "1-org"
    security  = "2-security"
    networks  = "3-networks"
    projects  = "4-projects"
    workloads = "5-workloads"
  }

  # Roles a nivel organización. Detalle en README.md.
  org_roles = {
    org = [
      "roles/resourcemanager.folderAdmin",
      "roles/orgpolicy.policyAdmin",
      "roles/resourcemanager.organizationViewer",
    ]
    security = [
      "roles/cloudkms.admin",
      "roles/secretmanager.admin",
      "roles/accesscontextmanager.policyAdmin",
    ]
    networks = [
      "roles/compute.networkAdmin",
      "roles/compute.securityAdmin",
      "roles/compute.xpnAdmin",
    ]
    projects = [
      "roles/resourcemanager.projectCreator",
    ]
    # Editor se otorga en 4-projects, solo en proyectos de servicio.
    workloads = []
  }

  org_bindings = merge([
    for sa, roles in local.org_roles : {
      for role in roles : "${sa}/${role}" => { sa = sa, role = role }
    }
  ]...)

  bucket_objects = "projects/_/buckets/${module.state_bucket.name}/objects"

  prefix_condition = {
    for sa, prefix in local.stages : sa => {
      own      = prefix
      previous = slice(local.stage_prefixes, 0, index(local.stage_prefixes, prefix))
    }
  }
}

resource "google_service_account" "tf" {
  for_each = local.stages

  project      = module.seed_project.project_id
  account_id   = "sa-tf-${each.key}"
  display_name = "Terraform ${each.value}"
  description  = "Ejecuta la etapa ${each.value} de la landing zone."

  depends_on = [module.seed_project]
}

resource "google_organization_iam_member" "tf" {
  for_each = local.org_bindings

  org_id = var.org_id
  role   = each.value.role
  member = google_service_account.tf[each.value.sa].member
}

# Asociar proyectos nuevos a la cuenta de facturación.
resource "google_billing_account_iam_member" "projects_billing_user" {
  billing_account_id = var.billing_account
  role               = "roles/billing.user"
  member             = google_service_account.tf["projects"].member
}

# Lectura/escritura en prefijo propio; listado del bucket (requerido por el backend gcs).
resource "google_storage_bucket_iam_member" "state_rw" {
  for_each = local.prefix_condition

  bucket = module.state_bucket.name
  role   = "roles/storage.objectUser"
  member = google_service_account.tf[each.key].member

  condition {
    title       = "tfstate-${each.value.own}"
    description = "Prefijo ${each.value.own}/ y listado del bucket."
    expression  = "resource.type == \"storage.googleapis.com/Bucket\" || resource.name.startsWith(\"${local.bucket_objects}/${each.value.own}/\")"
  }
}

# Solo lectura en prefijos de etapas anteriores.
resource "google_storage_bucket_iam_member" "state_read_previous" {
  for_each = local.prefix_condition

  bucket = module.state_bucket.name
  role   = "roles/storage.objectViewer"
  member = google_service_account.tf[each.key].member

  condition {
    title       = "tfstate-anteriores-${each.value.own}"
    description = "Lectura de estados previos a ${each.value.own}."
    expression  = join(" || ", [for p in each.value.previous : "resource.name.startsWith(\"${local.bucket_objects}/${p}/\")"])
  }
}
