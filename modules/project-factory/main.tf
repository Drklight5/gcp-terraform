locals {
  project_id = "banorte-${var.environment}-${var.domain}-${var.name_suffix}"

  labels = merge(var.labels, {
    env        = var.environment
    managed_by = "terraform"
  })

  apis = toset(var.shared_vpc_host_project_id == null ? var.activate_apis : concat(var.activate_apis, ["compute.googleapis.com"]))
}

resource "google_project" "this" {
  project_id          = local.project_id
  name                = coalesce(var.project_name, local.project_id)
  folder_id           = trimprefix(var.folder_id, "folders/")
  billing_account     = var.billing_account
  labels              = local.labels
  auto_create_network = false
  deletion_policy     = var.deletion_policy

  lifecycle {
    precondition {
      condition     = length(local.project_id) <= 30
      error_message = "El ID del proyecto excede 30 caracteres."
    }
  }
}

resource "google_project_service" "this" {
  for_each = local.apis

  project            = google_project.this.project_id
  service            = each.value
  disable_on_destroy = false
}

resource "google_compute_shared_vpc_service_project" "this" {
  count = var.shared_vpc_host_project_id == null ? 0 : 1

  host_project    = var.shared_vpc_host_project_id
  service_project = google_project.this.project_id

  depends_on = [google_project_service.this]
}

resource "google_billing_budget" "this" {
  count = var.enable_budget ? 1 : 0

  billing_account = var.billing_account
  display_name    = "${local.project_id}-budget"

  budget_filter {
    projects = ["projects/${google_project.this.number}"]
  }

  amount {
    specified_amount {
      currency_code = var.budget_currency
      units         = tostring(var.budget_amount)
    }
  }

  dynamic "threshold_rules" {
    for_each = var.budget_alert_thresholds
    content {
      threshold_percent = threshold_rules.value
    }
  }

  dynamic "all_updates_rule" {
    for_each = length(var.budget_notification_channels) > 0 ? [1] : []
    content {
      monitoring_notification_channels = var.budget_notification_channels
    }
  }
}
