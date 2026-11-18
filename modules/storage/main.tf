locals {
  labels = merge(var.labels, {
    env        = var.environment
    managed_by = "terraform"
  })
}

resource "google_storage_bucket" "this" {
  project       = var.project_id
  name          = "banorte-${var.environment}-${var.domain}-${var.name_suffix}"
  location      = upper(var.location)
  storage_class = var.storage_class
  force_destroy = var.force_destroy
  labels        = local.labels

  # Sin acceso público.
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = var.versioning_enabled
  }

  encryption {
    default_kms_key_name = var.kms_key_id
  }

  soft_delete_policy {
    retention_duration_seconds = var.soft_delete_retention_days * 86400
  }

  dynamic "retention_policy" {
    for_each = var.retention_period_days == null ? [] : [var.retention_period_days]
    content {
      retention_period = retention_policy.value * 86400
    }
  }

  dynamic "logging" {
    for_each = var.log_bucket == null ? [] : [var.log_bucket]
    content {
      log_bucket = logging.value
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.lifecycle_rules
    content {
      action {
        type          = lifecycle_rule.value.action.type
        storage_class = lifecycle_rule.value.action.storage_class
      }
      condition {
        age                        = lifecycle_rule.value.condition.age
        created_before             = lifecycle_rule.value.condition.created_before
        with_state                 = lifecycle_rule.value.condition.with_state
        matches_storage_class      = lifecycle_rule.value.condition.matches_storage_class
        matches_prefix             = lifecycle_rule.value.condition.matches_prefix
        matches_suffix             = lifecycle_rule.value.condition.matches_suffix
        num_newer_versions         = lifecycle_rule.value.condition.num_newer_versions
        days_since_noncurrent_time = lifecycle_rule.value.condition.days_since_noncurrent_time
      }
    }
  }
}
