---
draft: false
date: 2025-10-23
authors:
  - rfernandezdo
categories:
  - DevOps
  - Terraform
  - GitHub Actions
tags:
  - Terraform
  - GitHub Secrets
  - Azure
---

# Terraform: Uso de Variables y Secrets de GitHub

## Resumen
Cómo usar variables y secrets de GitHub en despliegues con Terraform para Azure. Ejemplo práctico y buenas prácticas para admins y DevOps que quieren CI/CD seguro y reproducible.

## ¿Qué problema resuelve?
Permite gestionar credenciales y parámetros sensibles (como client secrets, IDs, claves) de forma segura en pipelines de GitHub Actions, evitando exponerlos en el código fuente.

## ¿Qué es y cómo funciona?

- **Secrets**: Valores cifrados almacenados en GitHub (por repo o por entorno). Ej: credenciales Azure, claves API.
- **Variables de configuración**: Valores no sensibles, útiles para parámetros de entorno, nombres, ubicaciones, flags, etc. Se gestionan en Settings → Secrets and variables → Actions → Variables.
- Los workflows de GitHub Actions pueden acceder a estos valores como variables de entorno.
- Terraform puede consumirlos usando la sintaxis `${{ secrets.SECRET_NAME }}` para secrets y `${{ vars.VAR_NAME }}` para variables de configuración en el workflow.

---

## Ejemplo sencillo: despliegue de Azure Resource Group con variables y secrets

### 1. Añadir secrets en GitHub

- Ve a tu repo → Settings → Secrets and variables → Actions
- Añade los secrets:
  - `AZURE_CLIENT_ID`
  - `AZURE_TENANT_ID`
  - `AZURE_SUBSCRIPTION_ID`

### 2. Añadir variables de configuración (no sensibles)

- Ejemplo: `RG_NAME`, `LOCATION`

### 3. Workflow de GitHub Actions (`.github/workflows/terraform.yml`)
```yaml
name: 'Terraform Azure'
on:
  push:
    branches: [ main ]

---
  deploy:
    runs-on: ubuntu-latest
    env:
      # Recomendado: Federated Identity (OIDC) - no uses client secret
      ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
      ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
      TF_VAR_rg_name: ${{ vars.RG_NAME }}
      TF_VAR_location: ${{ vars.LOCATION }}
    steps:
      - uses: actions/checkout@v4
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
      - name: Terraform Init
        run: terraform init
      - name: Terraform Plan
        run: terraform plan
      - name: Terraform Apply
        run: terraform apply -auto-approve
```

En este ejemplo, `RG_NAME` y `LOCATION` son variables de configuración definidas en GitHub (no secrets) y se pasan automáticamente como variables de entrada a Terraform usando el prefijo `TF_VAR_`.

### 4. Código Terraform (`main.tf`)
```hcl
provider "azurerm" {
  features {}
}

variable "rg_name" {
  description = "Nombre del resource group"
  type        = string
}

variable "location" {
  description = "Ubicación Azure"
  type        = string
}

resource "azurerm_resource_group" "ejemplo" {
  name     = var.rg_name
  location = var.location
}
```



## Objetos complejos y versiones recientes de Terraform

Desde Terraform 1.3 en adelante, puedes pasar mapas y listas directamente como variables de entorno usando el prefijo `TF_VAR_`, sin necesidad de jsonencode/jsondecode. Terraform los interpreta automáticamente si el valor es un JSON válido.

### Ejemplo directo (Terraform >= 1.3)
```yaml
env:
  TF_VAR_tags: '{"env":"prod","owner":"devops"}'
```
```hcl
variable "tags" {
  type = map(string)
}

resource "azurerm_resource_group" "ejemplo" {
  name     = var.rg_name
  location = var.location
  tags     = var.tags
}
```
No necesitas usar `jsondecode()` si la variable ya es del tipo adecuado y el valor es JSON válido.

### ¿Y si necesitas un objeto complejo y usas versiones antiguas?
Si necesitas pasar un objeto complejo (por ejemplo, un mapa o lista de objetos) y tu versión de Terraform es anterior a 1.3, lo más habitual es usar un secret o variable en formato JSON y parsearlo en Terraform.

```yaml
env:
  TF_VAR_tags_json: ${{ secrets.TAGS_JSON }}
```
```hcl
variable "tags_json" {
  description = "Tags en formato JSON"
  type        = string
}

locals {
  tags = jsondecode(var.tags_json)
}

resource "azurerm_resource_group" "ejemplo" {
  name     = var.rg_name
  location = var.location
  tags     = local.tags
}
```
Así puedes pasar cualquier estructura compleja (mapas, listas, objetos anidados) como string JSON y usar `jsondecode()` en Terraform para convertirlo a un tipo nativo.
draft: false
date: 2025-10-23
authors:

  - rfernandezdo
categories:

  - DevOps
  - Terraform
  - GitHub Actions
tags:

  - Terraform
  - GitHub Secrets
  - Azure
---

## Buenas prácticas

- Usa federated identity (OIDC) siempre que sea posible, evita client secrets.
- Nunca subas secrets al repo ni los hardcodees en el código.
- Usa GitHub Environments para separar prod/dev y limitar acceso a secrets.
- Usa variables para parámetros no sensibles (ej: nombres, ubicaciones).
- Valida siempre con `terraform validate` antes de aplicar.
- Rota los secrets periódicamente si usas client secrets legacy.

## Referencias

- [GitHub Actions: Encrypted secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [Terraform Azure Provider Auth](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/service_principal_client_secret)
- [Automate deployments with GitHub Actions & Terraform](https://learn.microsoft.com/en-us/azure/spring-apps/enterprise/quickstart-automate-deployments-github-actions-enterprise#set-up-a-github-repository-and-authenticate)
- [Best practices Terraform](https://developer.hashicorp.com/terraform/language/style)
