variable "org_id" {
  description = "ID numérico de la organización."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{6,20}$", var.org_id))
    error_message = "org_id debe ser numérico."
  }
}

variable "billing_account" {
  description = "Cuenta de facturación del proyecto semilla (XXXXXX-XXXXXX-XXXXXX)."
  type        = string

  validation {
    condition     = can(regex("^[0-9A-F]{6}-[0-9A-F]{6}-[0-9A-F]{6}$", var.billing_account))
    error_message = "billing_account debe tener el formato XXXXXX-XXXXXX-XXXXXX (hexadecimal en mayúsculas)."
  }
}

variable "github_repo" {
  description = "Repositorio de GitHub autorizado en Workload Identity Federation (<owner>/<repo>)."
  type        = string

  validation {
    condition     = can(regex("^[A-Za-z0-9-]{1,39}/[A-Za-z0-9._-]{1,100}$", var.github_repo))
    error_message = "github_repo debe tener el formato <owner>/<repo>."
  }
}

variable "region" {
  description = "Región de la llave KMS y del bucket de estado: us-central1 (primaria) o us-east4 (DR)."
  type        = string
  default     = "us-central1"

  validation {
    condition     = contains(["us-central1", "us-east4"], var.region)
    error_message = "region debe ser us-central1 o us-east4."
  }
}
