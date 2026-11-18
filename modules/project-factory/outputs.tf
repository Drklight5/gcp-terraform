output "project_id" {
  description = "ID del proyecto."
  value       = google_project.this.project_id
}

output "project_number" {
  description = "Número del proyecto."
  value       = google_project.this.number
}

output "enabled_apis" {
  description = "APIs habilitadas."
  value       = sort([for s in google_project_service.this : s.service])
}

output "budget_id" {
  description = "ID del presupuesto, o null si enable_budget = false."
  value       = try(google_billing_budget.this[0].id, null)
}
