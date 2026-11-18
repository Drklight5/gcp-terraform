# project-factory

Proyecto GCP en una carpeta, con cuenta de facturación, etiquetas obligatorias y APIs habilitadas. Opcionalmente lo adjunta a una Shared VPC y crea un presupuesto.

- ID: `banorte-<entorno>-<dominio>-<name_suffix>` (máximo 30 caracteres).
- Sin red `default` (`auto_create_network = false`); `deletion_policy = "PREVENT"` por defecto.
- Shared VPC habilita `compute.googleapis.com` automáticamente.
- `google_billing_budget` requiere `user_project_override = true` y `billing_project` en el proveedor (ver `examples/basic`).

## Uso

```hcl
module "project" {
  source = "../../modules/project-factory"

  environment     = "dev"
  domain          = "data"
  name_suffix     = "app"
  folder_id       = "folders/123456789012"
  billing_account = "0A0A0A-0B0B0B-0C0C0C"
  activate_apis   = ["storage.googleapis.com"]

  shared_vpc_host_project_id = "banorte-dev-net-host"
  enable_budget              = true
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
| [google_billing_budget.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/billing_budget) | resource |
| [google_compute_shared_vpc_service_project.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/compute_shared_vpc_service_project) | resource |
| [google_project.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project) | resource |
| [google_project_service.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/project_service) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_activate_apis"></a> [activate\_apis](#input\_activate\_apis) | APIs a habilitar en el proyecto. | `list(string)` | <pre>[<br/>  "compute.googleapis.com",<br/>  "logging.googleapis.com",<br/>  "monitoring.googleapis.com"<br/>]</pre> | no |
| <a name="input_billing_account"></a> [billing\_account](#input\_billing\_account) | Cuenta de facturación (XXXXXX-XXXXXX-XXXXXX). | `string` | n/a | yes |
| <a name="input_budget_alert_thresholds"></a> [budget\_alert\_thresholds](#input\_budget\_alert\_thresholds) | Umbrales de alerta como fracción del monto (p. ej. 0.5 = 50 %). | `list(number)` | <pre>[<br/>  0.5,<br/>  0.9,<br/>  1<br/>]</pre> | no |
| <a name="input_budget_amount"></a> [budget\_amount](#input\_budget\_amount) | Monto del presupuesto (unidades enteras de budget\_currency). | `number` | `1000` | no |
| <a name="input_budget_currency"></a> [budget\_currency](#input\_budget\_currency) | Moneda del presupuesto (ISO 4217); debe coincidir con la de la cuenta de facturación. | `string` | `"MXN"` | no |
| <a name="input_budget_notification_channels"></a> [budget\_notification\_channels](#input\_budget\_notification\_channels) | Canales de Cloud Monitoring para alertas del presupuesto (projects/<p>/notificationChannels/<id>). | `list(string)` | `[]` | no |
| <a name="input_deletion_policy"></a> [deletion\_policy](#input\_deletion\_policy) | Política de borrado del proyecto: PREVENT, ABANDON o DELETE. | `string` | `"PREVENT"` | no |
| <a name="input_domain"></a> [domain](#input\_domain) | Dominio funcional usado en los nombres (banorte-<entorno>-<dominio>-<recurso>). | `string` | n/a | yes |
| <a name="input_enable_budget"></a> [enable\_budget](#input\_enable\_budget) | Crea un presupuesto de facturación para el proyecto. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Entorno: dev, qa o prod. | `string` | n/a | yes |
| <a name="input_folder_id"></a> [folder\_id](#input\_folder\_id) | Carpeta destino: ID numérico o folders/<id>. | `string` | n/a | yes |
| <a name="input_labels"></a> [labels](#input\_labels) | Etiquetas obligatorias: env, app, owner, cost\_center. managed\_by se fuerza a terraform. | `map(string)` | n/a | yes |
| <a name="input_name_suffix"></a> [name\_suffix](#input\_name\_suffix) | Sufijo del ID del proyecto (banorte-<entorno>-<dominio>-<name\_suffix>). | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Nombre visible del proyecto. null usa el ID. | `string` | `null` | no |
| <a name="input_shared_vpc_host_project_id"></a> [shared\_vpc\_host\_project\_id](#input\_shared\_vpc\_host\_project\_id) | Proyecto host de Shared VPC. null no adjunta el proyecto como servicio. | `string` | `null` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_budget_id"></a> [budget\_id](#output\_budget\_id) | ID del presupuesto, o null si enable\_budget = false. |
| <a name="output_enabled_apis"></a> [enabled\_apis](#output\_enabled\_apis) | APIs habilitadas. |
| <a name="output_project_id"></a> [project\_id](#output\_project\_id) | ID del proyecto. |
| <a name="output_project_number"></a> [project\_number](#output\_project\_number) | Número del proyecto. |
<!-- END_TF_DOCS -->
