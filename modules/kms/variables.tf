variable "project_id" {
  description = "ID del proyecto donde se crea el key ring."
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

variable "location" {
  description = "Región del key ring: us-central1 (primaria) o us-east4 (DR)."
  type        = string
  default     = "us-central1"

  validation {
    condition     = contains(["us-central1", "us-east4"], var.location)
    error_message = "location debe ser us-central1 o us-east4."
  }
}

variable "key_name" {
  description = "Sufijo del nombre de la llave (banorte-<entorno>-<dominio>-<key_name>)."
  type        = string
  default     = "key"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{0,30}$", var.key_name))
    error_message = "key_name debe tener 1-31 caracteres: minúsculas, dígitos o guiones."
  }
}

variable "rotation_period" {
  description = "Periodo de rotación en segundos con sufijo 's'. Máximo 90 días (7776000s)."
  type        = string
  default     = "7776000s"

  validation {
    condition = (
      can(regex("^[0-9]+s$", var.rotation_period)) &&
      try(tonumber(trimsuffix(var.rotation_period, "s")) >= 86400 && tonumber(trimsuffix(var.rotation_period, "s")) <= 7776000, false)
    )
    error_message = "rotation_period debe estar entre 86400s (1 día) y 7776000s (90 días)."
  }
}

variable "protection_level" {
  description = "Nivel de protección de la llave: SOFTWARE o HSM."
  type        = string
  default     = "SOFTWARE"

  validation {
    condition     = contains(["SOFTWARE", "HSM"], var.protection_level)
    error_message = "protection_level debe ser SOFTWARE o HSM."
  }
}

variable "prevent_destroy" {
  description = "Si es true, la llave se crea con lifecycle.prevent_destroy."
  type        = bool
  default     = true
}

variable "encrypter_decrypter_members" {
  description = "Cuentas de servicio con roles/cloudkms.cryptoKeyEncrypterDecrypter (formato serviceAccount:<email>)."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for m in var.encrypter_decrypter_members : can(regex("^serviceAccount:[^@]+@[^@]+$", m))])
    error_message = "Cada miembro debe tener el formato serviceAccount:<email>."
  }
}

variable "labels" {
  description = "Etiquetas obligatorias: env, app, owner, cost_center. managed_by se fuerza a terraform."
  type        = map(string)

  validation {
    condition     = alltrue([for k in ["env", "app", "owner", "cost_center"] : contains(keys(var.labels), k)])
    error_message = "labels debe incluir env, app, owner y cost_center."
  }
}
