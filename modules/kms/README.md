# kms

Key ring y llave CMEK de Cloud KMS con rotación de 90 días, `prevent_destroy` configurable y roles `cryptoKeyEncrypterDecrypter` para cuentas de servicio.

- Nombres: `banorte-<entorno>-<dominio>-kr` y `banorte-<entorno>-<dominio>-<key_name>`.
- `prevent_destroy` no admite variables en `lifecycle`; el módulo usa dos recursos (`protected` / `unprotected`). Cambiar el valor sobre una llave existente requiere `terraform state mv`.

## Uso

```hcl
module "kms" {
  source = "../../modules/kms"

  project_id  = "banorte-dev-sec-kms"
  environment = "dev"
  domain      = "sec"
  key_name    = "storage"

  encrypter_decrypter_members = ["serviceAccount:service-123@gs-project-accounts.iam.gserviceaccount.com"]
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
| [google_kms_crypto_key.protected](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_crypto_key.unprotected](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key) | resource |
| [google_kms_crypto_key_iam_member.encrypter_decrypter](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_crypto_key_iam_member) | resource |
| [google_kms_key_ring.this](https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/kms_key_ring) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_domain"></a> [domain](#input\_domain) | Dominio funcional usado en los nombres (banorte-<entorno>-<dominio>-<recurso>). | `string` | n/a | yes |
| <a name="input_encrypter_decrypter_members"></a> [encrypter\_decrypter\_members](#input\_encrypter\_decrypter\_members) | Cuentas de servicio con roles/cloudkms.cryptoKeyEncrypterDecrypter (formato serviceAccount:<email>). | `list(string)` | `[]` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Entorno: dev, qa o prod. | `string` | n/a | yes |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | Sufijo del nombre de la llave (banorte-<entorno>-<dominio>-<key\_name>). | `string` | `"key"` | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Etiquetas obligatorias: env, app, owner, cost\_center. managed\_by se fuerza a terraform. | `map(string)` | n/a | yes |
| <a name="input_location"></a> [location](#input\_location) | Región del key ring: us-central1 (primaria) o us-east4 (DR). | `string` | `"us-central1"` | no |
| <a name="input_prevent_destroy"></a> [prevent\_destroy](#input\_prevent\_destroy) | Si es true, la llave se crea con lifecycle.prevent\_destroy. | `bool` | `true` | no |
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | ID del proyecto donde se crea el key ring. | `string` | n/a | yes |
| <a name="input_protection_level"></a> [protection\_level](#input\_protection\_level) | Nivel de protección de la llave: SOFTWARE o HSM. | `string` | `"SOFTWARE"` | no |
| <a name="input_rotation_period"></a> [rotation\_period](#input\_rotation\_period) | Periodo de rotación en segundos con sufijo 's'. Máximo 90 días (7776000s). | `string` | `"7776000s"` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_crypto_key_id"></a> [crypto\_key\_id](#output\_crypto\_key\_id) | ID de la llave (projects/.../cryptoKeys/...), usable como default\_kms\_key\_name. |
| <a name="output_crypto_key_name"></a> [crypto\_key\_name](#output\_crypto\_key\_name) | Nombre de la llave. |
| <a name="output_key_ring_id"></a> [key\_ring\_id](#output\_key\_ring\_id) | ID del key ring. |
<!-- END_TF_DOCS -->
