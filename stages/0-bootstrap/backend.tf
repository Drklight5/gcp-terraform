# Primera ejecución: backend local (terraform.tfstate, ignorado por git).
# Migración tras crear el bucket: descomentar y ejecutar
#   terraform init -migrate-state
#
# terraform {
#   backend "gcs" {
#     bucket = "banorte-bootstrap-seed-tfstate"
#     prefix = "0-bootstrap"
#   }
# }
