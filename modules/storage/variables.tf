variable "project_id" {
  description = "ID del proyecto donde se crea el bucket."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.project_id))
    error_message = "project_id debe ser un ID de proyecto GCP válido."
  }
}

variable "environment" {
  description = "Entorno: dev, qa, prod o bootstrap (etapa 0)."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod", "bootstrap"], var.environment)
    error_message = "environment debe ser dev, qa, prod o bootstrap."
  }
}

variable "domain" {
  description = "Dominio funcional usado en los nombres (banorte-<entorno>-<dominio>-<recurso>)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,20}$", var.domain))
    error_message = "domain debe tener 2-21 caracteres: minúsculas, dígitos o guiones."
  }
}

variable "name_suffix" {
  description = "Sufijo del nombre del bucket (banorte-<entorno>-<dominio>-<name_suffix>)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,29}[a-z0-9]$", var.name_suffix))
    error_message = "name_suffix debe tener 2-31 caracteres: minúsculas, dígitos o guiones, sin guion al inicio ni al final."
  }
}

variable "location" {
  description = "Región del bucket: us-central1 (primaria) o us-east4 (DR)."
  type        = string
  default     = "us-central1"

  validation {
    condition     = contains(["us-central1", "us-east4"], lower(var.location))
    error_message = "location debe ser us-central1 o us-east4."
  }
}

variable "storage_class" {
  description = "Clase de almacenamiento por defecto."
  type        = string
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "storage_class debe ser STANDARD, NEARLINE, COLDLINE o ARCHIVE."
  }
}

variable "kms_key_id" {
  description = "Llave CMEK (projects/<p>/locations/<l>/keyRings/<kr>/cryptoKeys/<k>). Debe estar en la misma región que el bucket."
  type        = string

  validation {
    condition     = can(regex("^projects/[^/]+/locations/[^/]+/keyRings/[^/]+/cryptoKeys/[^/]+$", var.kms_key_id))
    error_message = "kms_key_id debe tener el formato projects/<p>/locations/<l>/keyRings/<kr>/cryptoKeys/<k>."
  }
}

variable "versioning_enabled" {
  description = "Habilita el versionado de objetos."
  type        = bool
  default     = true
}

variable "lifecycle_rules" {
  description = "Reglas de ciclo de vida. action.type: Delete, SetStorageClass o AbortIncompleteMultipartUpload."
  type = list(object({
    action = object({
      type          = string
      storage_class = optional(string)
    })
    condition = object({
      age                        = optional(number)
      created_before             = optional(string)
      with_state                 = optional(string)
      matches_storage_class      = optional(list(string))
      matches_prefix             = optional(list(string))
      matches_suffix             = optional(list(string))
      num_newer_versions         = optional(number)
      days_since_noncurrent_time = optional(number)
    })
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.lifecycle_rules : contains(["Delete", "SetStorageClass", "AbortIncompleteMultipartUpload"], r.action.type)])
    error_message = "action.type debe ser Delete, SetStorageClass o AbortIncompleteMultipartUpload."
  }

  validation {
    condition     = alltrue([for r in var.lifecycle_rules : r.action.type != "SetStorageClass" || r.action.storage_class != null])
    error_message = "SetStorageClass requiere action.storage_class."
  }

  validation {
    condition     = alltrue([for r in var.lifecycle_rules : r.condition.with_state == null || contains(["LIVE", "ARCHIVED", "ANY"], coalesce(r.condition.with_state, "ANY"))])
    error_message = "condition.with_state debe ser LIVE, ARCHIVED o ANY."
  }
}

variable "retention_period_days" {
  description = "Retención mínima de objetos en días. null desactiva la política."
  type        = number
  default     = null

  validation {
    condition     = var.retention_period_days == null || try(var.retention_period_days > 0, false)
    error_message = "retention_period_days debe ser mayor que 0."
  }
}

variable "soft_delete_retention_days" {
  description = "Días de retención de objetos eliminados (soft delete). 0 lo desactiva; 7-90 en otro caso."
  type        = number
  default     = 7

  validation {
    condition     = var.soft_delete_retention_days == 0 || (var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90)
    error_message = "soft_delete_retention_days debe ser 0 o estar entre 7 y 90."
  }
}

variable "log_bucket" {
  description = "Bucket destino de los logs de acceso. null los desactiva."
  type        = string
  default     = null
}

variable "force_destroy" {
  description = "Permite eliminar el bucket aunque contenga objetos."
  type        = bool
  default     = false
}

variable "labels" {
  description = "Etiquetas obligatorias: env, app, owner, cost_center. managed_by se fuerza a terraform."
  type        = map(string)

  validation {
    condition     = alltrue([for k in ["env", "app", "owner", "cost_center"] : contains(keys(var.labels), k)])
    error_message = "labels debe incluir env, app, owner y cost_center."
  }
}
