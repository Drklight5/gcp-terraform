variable "environment" {
  description = "Entorno: dev, qa o prod."
  type        = string

  validation {
    condition     = contains(["dev", "qa", "prod"], var.environment)
    error_message = "environment debe ser dev, qa o prod."
  }
}

variable "domain" {
  description = "Dominio funcional usado en los nombres (banorte-<entorno>-<dominio>-<recurso>)."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,10}$", var.domain))
    error_message = "domain debe tener 2-11 caracteres: minúsculas, dígitos o guiones."
  }
}

variable "name_suffix" {
  description = "Sufijo del ID del proyecto (banorte-<entorno>-<dominio>-<name_suffix>)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{0,8}[a-z0-9]$|^[a-z0-9]$", var.name_suffix))
    error_message = "name_suffix debe tener 1-10 caracteres: minúsculas, dígitos o guiones, sin guion al inicio ni al final."
  }
}

variable "project_name" {
  description = "Nombre visible del proyecto. null usa el ID."
  type        = string
  default     = null

  validation {
    condition     = var.project_name == null || can(regex("^[A-Za-z0-9 '\"!-]{4,30}$", var.project_name))
    error_message = "project_name debe tener 4-30 caracteres válidos."
  }
}

variable "folder_id" {
  description = "Carpeta destino: ID numérico o folders/<id>."
  type        = string

  validation {
    condition     = can(regex("^(folders/)?[0-9]+$", var.folder_id))
    error_message = "folder_id debe ser numérico o con formato folders/<id>."
  }
}

variable "billing_account" {
  description = "Cuenta de facturación (XXXXXX-XXXXXX-XXXXXX)."
  type        = string

  validation {
    condition     = can(regex("^[0-9A-F]{6}-[0-9A-F]{6}-[0-9A-F]{6}$", var.billing_account))
    error_message = "billing_account debe tener el formato XXXXXX-XXXXXX-XXXXXX (hexadecimal en mayúsculas)."
  }
}

variable "deletion_policy" {
  description = "Política de borrado del proyecto: PREVENT, ABANDON o DELETE."
  type        = string
  default     = "PREVENT"

  validation {
    condition     = contains(["PREVENT", "ABANDON", "DELETE"], var.deletion_policy)
    error_message = "deletion_policy debe ser PREVENT, ABANDON o DELETE."
  }
}

variable "activate_apis" {
  description = "APIs a habilitar en el proyecto."
  type        = list(string)
  default     = ["compute.googleapis.com", "logging.googleapis.com", "monitoring.googleapis.com"]

  validation {
    condition     = alltrue([for a in var.activate_apis : can(regex("^[a-z0-9.-]+\\.googleapis\\.com$", a))])
    error_message = "Cada API debe tener el formato <servicio>.googleapis.com."
  }
}

variable "shared_vpc_host_project_id" {
  description = "Proyecto host de Shared VPC. null no adjunta el proyecto como servicio."
  type        = string
  default     = null

  validation {
    condition     = var.shared_vpc_host_project_id == null || can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", var.shared_vpc_host_project_id))
    error_message = "shared_vpc_host_project_id debe ser un ID de proyecto GCP válido."
  }
}

variable "enable_budget" {
  description = "Crea un presupuesto de facturación para el proyecto."
  type        = bool
  default     = false
}

variable "budget_amount" {
  description = "Monto del presupuesto (unidades enteras de budget_currency)."
  type        = number
  default     = 1000

  validation {
    condition     = var.budget_amount > 0 && floor(var.budget_amount) == var.budget_amount
    error_message = "budget_amount debe ser un entero mayor que 0."
  }
}

variable "budget_currency" {
  description = "Moneda del presupuesto (ISO 4217); debe coincidir con la de la cuenta de facturación."
  type        = string
  default     = "MXN"

  validation {
    condition     = can(regex("^[A-Z]{3}$", var.budget_currency))
    error_message = "budget_currency debe ser un código ISO 4217 de 3 letras."
  }
}

variable "budget_alert_thresholds" {
  description = "Umbrales de alerta como fracción del monto (p. ej. 0.5 = 50 %)."
  type        = list(number)
  default     = [0.5, 0.9, 1.0]

  validation {
    condition     = length(var.budget_alert_thresholds) > 0 && alltrue([for t in var.budget_alert_thresholds : t > 0 && t <= 2])
    error_message = "Cada umbral debe estar en (0, 2]."
  }
}

variable "budget_notification_channels" {
  description = "Canales de Cloud Monitoring para alertas del presupuesto (projects/<p>/notificationChannels/<id>)."
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Etiquetas obligatorias: env, app, owner, cost_center. managed_by se fuerza a terraform."
  type        = map(string)

  validation {
    condition     = alltrue([for k in ["env", "app", "owner", "cost_center"] : contains(keys(var.labels), k)])
    error_message = "labels debe incluir env, app, owner y cost_center."
  }
}
