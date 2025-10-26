---
draft: false
date: 2025-01-12
authors:
  - rfernandezdo
categories:
  - DevOps
tags:
  - Terraform
  - Azure Storage
  - Infrastructure as Code
---

# Terraform Backend en Azure Storage: Setup completo

## Resumen

Guardar el estado de Terraform en local es peligroso y no escala. Azure Storage con state locking es la solución estándar para equipos. Aquí el setup completo en 5 minutos.

## ¿Por qué usar remote backend?

**Problemas con backend local:**
- ❌ Estado se pierde si borras tu laptop
- ❌ Imposible colaborar en equipo
- ❌ No hay locking → corrupciones en despliegues simultáneos
- ❌ Secretos en plaintext en disco local

**Ventajas con Azure Storage:**
- ✅ Estado centralizado y versionado
- ✅ Locking automático con blob lease
- ✅ Encriptación at-rest
- ✅ Acceso controlado con RBAC

## Setup del backend

### 1. Crear Storage Account

```bash
# Variables
RG="terraform-state-rg"
LOCATION="westeurope"
STORAGE_ACCOUNT="tfstate$(date +%s)"  # Nombre único
CONTAINER="tfstate"

# Crear resource group
az group create \
  --name $RG \
  --location $LOCATION

# Crear storage account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RG \
  --location $LOCATION \
  --sku Standard_LRS \
  --encryption-services blob \
  --min-tls-version TLS1_2

# Crear container
az storage container create \
  --name $CONTAINER \
  --account-name $STORAGE_ACCOUNT \
  --auth-mode login
```

!!! tip "Naming convention"
    Storage account solo acepta lowercase y números, máximo 24 caracteres. Usa un sufijo único para evitar colisiones.

### 2. Configurar backend en Terraform

`backend.tf`:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate1234567890"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
  }
}
```

### 3. Inicializar

```bash
# Login a Azure
az login

# Inicializar backend
terraform init

# Migrar estado existente (si aplica)
terraform init -migrate-state
```

## State locking

Azure usa blob leases para locking automático:

```bash
# Ver si hay lock activo
az storage blob show \
  --container-name $CONTAINER \
  --name prod.terraform.tfstate \
  --account-name $STORAGE_ACCOUNT \
  --query "properties.lease.status"
```

Si alguien está ejecutando `terraform apply`, verás:

```
"locked"
```

## Multi-entorno con workspaces

```bash
# Crear workspace por entorno
terraform workspace new dev
terraform workspace new staging  
terraform workspace new prod

# Listar workspaces
terraform workspace list

# Cambiar entre entornos
terraform workspace select prod
```

Cada workspace crea su propio state file:
```
prod.terraform.tfstate
dev.terraform.tfstate
staging.terraform.tfstate
```

## Seguridad: Managed Identity

Evita usar access keys en pipelines:

```bash
# Crear managed identity
az identity create \
  --resource-group $RG \
  --name terraform-identity

# Asignar rol Storage Blob Data Contributor
IDENTITY_ID=$(az identity show \
  --resource-group $RG \
  --name terraform-identity \
  --query principalId -o tsv)

az role assignment create \
  --role "Storage Blob Data Contributor" \
  --assignee $IDENTITY_ID \
  --scope /subscriptions/{sub-id}/resourceGroups/$RG/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT
```

Backend config con managed identity:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstate1234567890"
    container_name       = "tfstate"
    key                  = "prod.terraform.tfstate"
    use_msi              = true
    subscription_id      = "00000000-0000-0000-0000-000000000000"
    tenant_id            = "00000000-0000-0000-0000-000000000000"
  }
}
```

## Versionado del estado

```bash
# Habilitar versioning en el container
az storage blob service-properties update \
  --account-name $STORAGE_ACCOUNT \
  --enable-versioning true

# Ver versiones anteriores
az storage blob list \
  --container-name $CONTAINER \
  --account-name $STORAGE_ACCOUNT \
  --include v \
  --query "[?name=='prod.terraform.tfstate'].{Version:versionId, LastModified:properties.lastModified}"
```

## Pipeline CI/CD con Azure DevOps

`azure-pipelines.yml`:

```yaml
trigger:
  - main

pool:
  vmImage: 'ubuntu-latest'

variables:
  - group: terraform-variables

stages:
  - stage: Plan
    jobs:
      - job: TerraformPlan
        steps:
          - task: AzureCLI@2
            displayName: 'Terraform Init & Plan'
            inputs:
              azureSubscription: 'Azure Service Connection'
              scriptType: 'bash'
              scriptLocation: 'inlineScript'
              inlineScript: |
                terraform init
                terraform plan -out=tfplan
          
          - publish: '$(System.DefaultWorkingDirectory)/tfplan'
            artifact: tfplan

  - stage: Apply
    dependsOn: Plan
    condition: succeeded()
    jobs:
      - deployment: TerraformApply
        environment: 'production'
        strategy:
          runOnce:
            deploy:
              steps:
                - download: current
                  artifact: tfplan
                
                - task: AzureCLI@2
                  displayName: 'Terraform Apply'
                  inputs:
                    azureSubscription: 'Azure Service Connection'
                    scriptType: 'bash'
                    scriptLocation: 'inlineScript'
                    inlineScript: |
                      terraform init
                      terraform apply tfplan
```

## Troubleshooting

**Error: "Failed to lock state"**

```bash
# Forzar unlock (solo si estás seguro)
terraform force-unlock <LOCK_ID>

# O romper lease manualmente
az storage blob lease break \
  --container-name $CONTAINER \
  --blob-name prod.terraform.tfstate \
  --account-name $STORAGE_ACCOUNT
```

**Error: "storage account not found"**

```bash
# Verificar permisos
az storage account show \
  --name $STORAGE_ACCOUNT \
  --resource-group $RG
```

## Buenas prácticas

- **State file por proyecto**: No mezcles infraestructuras diferentes
- **Soft delete**: Habilita soft delete en storage account
- **Network security**: Restringe acceso desde VNet específicas
- **Audit logs**: Habilita diagnostic settings para compliance
- **Backup externo**: Exporta estados críticos a otro storage account

!!! warning "Never commit state files"
    Añade `*.tfstate*` a `.gitignore`. El state contiene secretos en plaintext.

## Referencias

- [Store Terraform state in Azure Storage](https://learn.microsoft.com/en-us/azure/developer/terraform/store-state-in-azure-storage)
- [Terraform azurerm backend](https://developer.hashicorp.com/terraform/language/settings/backends/azurerm)
