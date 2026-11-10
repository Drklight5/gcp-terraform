# gcp-terraform

Datacenter virtual en Google Cloud Platform (GCP) con Terraform. Incluye jerarquía de organización, red compartida hub-and-spoke, cómputo, almacenamiento, bases de datos, seguridad, observabilidad, respaldo y conectividad con el datacenter físico existente.

## Orden de despliegue
Cada etapa lee la anterior con `terraform_remote_state`.

| Orden | Etapa | Entornos | Propósito |
|-------|-------|----------|-----------|
| 0 | `stages/0-bootstrap` | — | Proyecto semilla, bucket de estado GCS y cuentas de servicio de Terraform. |
| 1 | `stages/1-org` | — | Jerarquía de carpetas, políticas de organización y roles base. |
| 2 | `stages/2-security` | — | KMS, Secret Manager, VPC Service Controls y exportación de logs. |
| 3 | `stages/3-networks` | dev → qa → prod | Hub y spokes VPC, firewall, DNS, conectividad híbrida y Cloud IDS. |
| 4 | `stages/4-projects` | dev → qa → prod | Proyectos por aplicación con facturación y APIs habilitadas. |
| 5 | `stages/5-workloads` | dev → qa → prod | GKE, Cloud Run, Cloud SQL, Memorystore, Storage, balanceadores, observabilidad y respaldo. |

Dentro de las etapas 3 a 5, los entornos se despliegan en orden: `dev`, luego `qa`, luego `prod`.

## Inicialización de una etapa

```bash
cd stages/3-networks/envs/dev
terraform init -backend-config="bucket=<bucket-semilla>" -backend-config="prefix=3-networks/dev"
terraform fmt -check -recursive
terraform validate
terraform plan -var-file=terraform.tfvars
```

Para las etapas 0 a 2 el prefijo es `<etapa>` (por ejemplo `1-org`). `terraform apply` lo ejecuta un humano tras revisar el plan.

## Estructura

- `modules/`: módulos reutilizables, sin backend.
- `stages/`: raíces de despliegue.
- `policies/`: políticas de organización y reglas de validación.
- `tests/`: pruebas de integración.
- `docs/adr/`, `docs/runbooks/`: decisiones y procedimientos.
- `.github/workflows/`: CI/CD.
