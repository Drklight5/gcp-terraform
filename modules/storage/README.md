# storage

Bucket de Cloud Storage privado: acceso uniforme, `public_access_prevention = "enforced"`, versionado, CMEK, reglas de ciclo de vida configurables y etiquetas obligatorias.

- Nombre: `banorte-<entorno>-<dominio>-<name_suffix>`.
- El agente de servicio de GCS (`service-<número>@gs-project-accounts.iam.gserviceaccount.com`) necesita `roles/cloudkms.cryptoKeyEncrypterDecrypter` sobre la llave; se otorga con el módulo `kms`.
- La llave debe estar en la misma región que el bucket.

## Uso

```hcl
module "storage" {
  source = "../../modules/storage"

  project_id  = "banorte-dev-data-prj"
  environment = "dev"
  domain      = "data"
  name_suffix = "raw"
  kms_key_id  = module.kms.crypto_key_id

  lifecycle_rules = [{
    action    = { type = "Delete" }
    condition = { num_newer_versions = 5, with_state = "ARCHIVED" }
  }]
  labels = { env = "dev", app = "landing-zone", owner = "equipo-plataforma", cost_center = "0000" }
}
```

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

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [google_storage_bucket.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/storage_bucket) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_domain"></a> [domain](#input\_domain) | Dominio funcional usado en los nombres (banorte-<entorno>-<dominio>-<recurso>). | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Entorno: dev, qa o prod. | `string` | n/a | yes |
| <a name="input_force_destroy"></a> [force\_destroy](#input\_force\_destroy) | Permite eliminar el bucket aunque contenga objetos. | `bool` | `false` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | Llave CMEK (projects/<p>/locations/<l>/keyRings/<kr>/cryptoKeys/<k>). Debe estar en la misma región que el bucket. | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Etiquetas obligatorias: env, app, owner, cost\_center. managed\_by se fuerza a terraform. | `map(string)` | n/a | yes |
| <a name="input_lifecycle_rules"></a> [lifecycle\_rules](#input\_lifecycle\_rules) | Reglas de ciclo de vida. action.type: Delete, SetStorageClass o AbortIncompleteMultipartUpload. | <pre>list(object({<br/>    action = object({<br/>      type          = string<br/>      storage_class = optional(string)<br/>    })<br/>    condition = object({<br/>      age                        = optional(number)<br/>      created_before             = optional(string)<br/>      with_state                 = optional(string)<br/>      matches_storage_class      = optional(list(string))<br/>      matches_prefix             = optional(list(string))<br/>      matches_suffix             = optional(list(string))<br/>      num_newer_versions         = optional(number)<br/>      days_since_noncurrent_time = optional(number)<br/>    })<br/>  }))</pre> | `[]` | no |
| <a name="input_location"></a> [location](#input\_location) | Región del bucket: us-central1 (primaria) o us-east4 (DR). | `string` | `"us-central1"` | no |
| <a name="input_log_bucket"></a> [log\_bucket](#input\_log\_bucket) | Bucket destino de los logs de acceso. null los desactiva. | `string` | `null` | no |
| <a name="input_name_suffix"></a> [name\_suffix](#input\_name\_suffix) | Sufijo del nombre del bucket (banorte-<entorno>-<dominio>-<name\_suffix>). | `string` | n/a | yes |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | ID del proyecto donde se crea el bucket. | `string` | n/a | yes |
| <a name="input_retention_period_days"></a> [retention\_period\_days](#input\_retention\_period\_days) | Retención mínima de objetos en días. null desactiva la política. | `number` | `null` | no |
| <a name="input_soft_delete_retention_days"></a> [soft\_delete\_retention\_days](#input\_soft\_delete\_retention\_days) | Días de retención de objetos eliminados (soft delete). 0 lo desactiva; 7-90 en otro caso. | `number` | `7` | no |
| <a name="input_storage_class"></a> [storage\_class](#input\_storage\_class) | Clase de almacenamiento por defecto. | `string` | `"STANDARD"` | no |
| <a name="input_versioning_enabled"></a> [versioning\_enabled](#input\_versioning\_enabled) | Habilita el versionado de objetos. | `bool` | `true` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_name"></a> [name](#output\_name) | Nombre del bucket. |
| <a name="output_self_link"></a> [self\_link](#output\_self\_link) | Self link del bucket. |
| <a name="output_url"></a> [url](#output\_url) | URL gs:// del bucket. |
<!-- END_TF_DOCS -->
