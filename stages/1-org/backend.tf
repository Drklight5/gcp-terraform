terraform {
  # Configuración parcial: el bucket del proyecto semilla y el prefijo
  # se pasan en init, por ejemplo:
  #   terraform init -backend-config="bucket=<bucket-semilla>" -backend-config="prefix=<etapa>/<entorno>"
  backend "gcs" {}
}
