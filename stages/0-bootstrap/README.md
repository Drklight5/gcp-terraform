# 0-bootstrap

Crea la base sobre la que corren las demás etapas:

- Carpeta `bootstrap` y proyecto semilla `banorte-bootstrap-seed` (módulo `project-factory`): ya existen y se importan.
- Llave KMS `banorte-bootstrap-seed-tfstate` y bucket de estado `banorte-bootstrap-seed-tfstate` con CMEK (módulos `kms` y `storage`).
- Cinco cuentas de servicio de Terraform, una por etapa, con roles mínimos y acceso al bucket por prefijo.
- Workload Identity Federation para GitHub Actions, restringida a `var.github_repo`.

## Ejecución

Se necesita una identidad con permisos de administración de la organización y de la cuenta de facturación (`roles/resourcemanager.organizationAdmin`, `roles/billing.admin`, `roles/iam.workloadIdentityPoolAdmin`).

```bash
cp terraform.tfvars.example terraform.tfvars   # completar
terraform init
terraform plan
```

La primera ejecución usa backend local. Tras crear el bucket, descomentar el bloque `gcs` de `backend.tf` y ejecutar `terraform init -migrate-state`.

Los bloques `import` usan `bootstrap_folder_id` (`folders/<ID>`) y `seed_project_id`. Revisar en el plan los cambios sobre ambos recursos antes de aplicar.

Los proveedores usan `user_project_override = true` con el proyecto semilla como `billing_project`: las APIs consultadas deben estar habilitadas en él antes del primer plan.

## Estado por prefijo

| Cuenta | Lectura/escritura | Solo lectura |
|---|---|---|
| sa-tf-org | `1-org/` | `0-bootstrap/` |
| sa-tf-security | `2-security/` | `0-bootstrap/`, `1-org/` |
| sa-tf-networks | `3-networks/` | `0-bootstrap/` … `2-security/` |
| sa-tf-projects | `4-projects/` | `0-bootstrap/` … `3-networks/` |
| sa-tf-workloads | `5-workloads/` | `0-bootstrap/` … `4-projects/` |

- Escritura: `roles/storage.objectUser` con condición `resource.name.startsWith(".../objects/<prefijo>/")`.
- Lectura: `roles/storage.objectViewer` con condición sobre los prefijos anteriores.
- El backend `gcs` necesita listar el bucket (`storage.objects.list` se evalúa sobre el bucket, no sobre el objeto). Por eso la condición de escritura también acepta `resource.type == "storage.googleapis.com/Bucket"`: cada cuenta puede ver los **nombres** de todos los objetos, pero solo leer el contenido de sus prefijos permitidos.
- Las cuentas no necesitan permisos de KMS: el cifrado CMEK lo hace el agente de servicio de GCS.

## Roles por cuenta

Todos se otorgan a nivel organización, salvo que se indique otra cosa.

### sa-tf-org (1-org)
| Rol | Motivo |
|---|---|
| `roles/resourcemanager.folderAdmin` | Crear y administrar carpetas, incluida su política IAM. |
| `roles/orgpolicy.policyAdmin` | Definir políticas de organización (regiones permitidas, sin IP públicas, Shielded VM). |
| `roles/resourcemanager.organizationViewer` | Leer la organización para usarla como padre de carpetas y políticas. |

### sa-tf-security (2-security)
| Rol | Motivo |
|---|---|
| `roles/cloudkms.admin` | Crear key rings, llaves y su IAM. No incluye cifrar ni descifrar. |
| `roles/secretmanager.admin` | Crear secretos, versiones y su IAM. |
| `roles/accesscontextmanager.policyAdmin` | Administrar perímetros de VPC Service Controls y niveles de acceso; solo existe a nivel organización. |

Los dos primeros pueden acotarse a la carpeta o proyecto de seguridad cuando `1-org` lo cree.

### sa-tf-networks (3-networks)
| Rol | Motivo |
|---|---|
| `roles/compute.networkAdmin` | VPC, subredes, rutas, Cloud Router, VPN e Interconnect. |
| `roles/compute.securityAdmin` | Reglas de firewall y políticas SSL (no incluidas en `networkAdmin`). |
| `roles/compute.xpnAdmin` | Habilitar proyectos host de Shared VPC; solo se otorga en organización o carpeta. |

### sa-tf-projects (4-projects)
| Rol | Motivo |
|---|---|
| `roles/resourcemanager.projectCreator` | Crear proyectos; el creador obtiene `owner` sobre cada proyecto creado. |
| `roles/billing.user` (cuenta de facturación) | Asociar proyectos nuevos a la cuenta de facturación. |

Para adjuntar proyectos de servicio a la Shared VPC se requiere además `roles/compute.xpnAdmin`, y para presupuestos `roles/billing.costsManager`. No se otorgan aquí; añadirlos si `4-projects` los usa.

### sa-tf-workloads (5-workloads)
Sin roles en la organización. `4-projects` le otorga `roles/editor` solo en cada proyecto de servicio que crea (salida `service_accounts.workloads`), de modo que nunca tiene permisos fuera de esos proyectos.

### Comunes
- `roles/iam.workloadIdentityUser` en cada cuenta para `principalSet://.../attribute.repository/<owner>/<repo>`: el repositorio puede suplantarla desde GitHub Actions.
- El proveedor OIDC solo acepta tokens con `assertion.repository == "<owner>/<repo>"`.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.16.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | ~> 8.10 |
| <a name="requirement_google-beta"></a> [google-beta](#requirement\_google-beta) | ~> 8.10 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_google"></a> [google](#provider\_google) | 8.12.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_kms"></a> [kms](#module\_kms) | ../../modules/kms | n/a |
| <a name="module_seed_project"></a> [seed\_project](#module\_seed\_project) | ../../modules/project-factory | n/a |
| <a name="module_state_bucket"></a> [state\_bucket](#module\_state\_bucket) | ../../modules/storage | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [google_billing_account_iam_member.projects_billing_user](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_account_iam_member) | resource |
| [google_folder.bootstrap](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/folder) | resource |
| [google_iam_workload_identity_pool.github](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool) | resource |
| [google_iam_workload_identity_pool_provider.github](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/iam_workload_identity_pool_provider) | resource |
| [google_kms_crypto_key_iam_member.gcs_agent](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_organization_iam_member.tf](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/organization_iam_member) | resource |
| [google_project_iam_audit_config.seed](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_iam_audit_config) | resource |
| [google_service_account.tf](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account) | resource |
| [google_service_account_iam_member.github_wif](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/service_account_iam_member) | resource |
| [google_storage_bucket_iam_member.state_read_previous](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_storage_bucket_iam_member.state_rw](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket_iam_member) | resource |
| [google_storage_project_service_account.gcs](https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/storage_project_service_account) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_billing_account"></a> [billing\_account](#input\_billing\_account) | Cuenta de facturación del proyecto semilla (XXXXXX-XXXXXX-XXXXXX). | `string` | n/a | yes |
| <a name="input_bootstrap_folder_id"></a> [bootstrap\_folder\_id](#input\_bootstrap\_folder\_id) | ID numérico de la carpeta bootstrap existente, sin el prefijo folders/. | `string` | n/a | yes |
| <a name="input_github_repo"></a> [github\_repo](#input\_github\_repo) | Repositorio de GitHub autorizado en Workload Identity Federation (<owner>/<repo>). | `string` | n/a | yes |
| <a name="input_org_id"></a> [org\_id](#input\_org\_id) | ID numérico de la organización. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | Región de la llave KMS y del bucket de estado: us-central1 (primaria) o us-east4 (DR). | `string` | `"us-central1"` | no |
| <a name="input_seed_project_id"></a> [seed\_project\_id](#input\_seed\_project\_id) | ID del proyecto semilla existente. | `string` | `"banorte-bootstrap-seed"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_bootstrap_folder_id"></a> [bootstrap\_folder\_id](#output\_bootstrap\_folder\_id) | ID de la carpeta bootstrap (folders/<id>). |
| <a name="output_seed_project_id"></a> [seed\_project\_id](#output\_seed\_project\_id) | ID del proyecto semilla. |
| <a name="output_service_accounts"></a> [service\_accounts](#output\_service\_accounts) | Correos de las cuentas de servicio de Terraform por etapa. |
| <a name="output_tfstate_bucket"></a> [tfstate\_bucket](#output\_tfstate\_bucket) | Bucket de estado de Terraform. |
| <a name="output_tfstate_kms_key_id"></a> [tfstate\_kms\_key\_id](#output\_tfstate\_kms\_key\_id) | Llave CMEK del bucket de estado. |
| <a name="output_wif_pool"></a> [wif\_pool](#output\_wif\_pool) | Nombre completo del pool de Workload Identity. |
| <a name="output_wif_provider"></a> [wif\_provider](#output\_wif\_provider) | Nombre completo del proveedor WIF (valor de workload\_identity\_provider en google-github-actions/auth). |
<!-- END_TF_DOCS -->
