---
draft: false
date: 2025-02-13
authors:
  - rfernandezdo
categories:
  - DevOps
tags:
  - GitHub Actions
  - CI/CD
  - Azure
---

# GitHub Actions: Deploy a Azure con Workload Identity Federation

## Resumen

Olv

ídate de guardar service principal secrets en GitHub. Con Workload Identity Federation, GitHub Actions se autentica a Azure sin credenciales almacenadas. Más seguro y cero rotación de secrets.

## ¿Qué es Workload Identity Federation?

Permite que GitHub Actions obtenga un access token de Azure usando OIDC (OpenID Connect). Azure confía en los tokens de GitHub basándose en:
- Repositorio específico
- Branch específico
- Environment específico

## Setup completo

### 1. Crear service principal

```bash
# Variables
APP_NAME="github-actions-federation"
RG="my-rg"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Crear app registration
APP_ID=$(az ad app create \
  --display-name $APP_NAME \
  --query appId -o tsv)

# Crear service principal
az ad sp create --id $APP_ID

SP_OBJECT_ID=$(az ad sp show --id $APP_ID --query id -o tsv)

# Asignar rol Contributor
az role assignment create \
  --role Contributor \
  --assignee $APP_ID \
  --scope /subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RG
```

### 2. Configurar Federated Credential

```bash
# Para branch main
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-main-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:myorg/myrepo:ref:refs/heads/main",
    "description": "GitHub Actions - main branch",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Para environment production
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-prod-environment",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:myorg/myrepo:environment:production",
    "description": "GitHub Actions - production environment",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# Para pull requests
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "github-pull-requests",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:myorg/myrepo:pull_request",
    "description": "GitHub Actions - pull requests",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### 3. Configurar GitHub Secrets

En tu repositorio → Settings → Secrets:

```
AZURE_CLIENT_ID = {APP_ID}
AZURE_TENANT_ID = {TENANT_ID}
AZURE_SUBSCRIPTION_ID = {SUBSCRIPTION_ID}
```

### 4. GitHub Actions Workflow

`.github/workflows/deploy.yml`:

```yaml
name: Deploy to Azure

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

permissions:
  id-token: write  # Required for OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production  # Si usas federated credential por environment
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Azure Login with OIDC
        uses: azure/login@v1
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      
      - name: Deploy to Azure Web App
        uses: azure/webapps-deploy@v2
        with:
          app-name: my-web-app
          package: ./dist
      
      - name: Azure CLI commands
        run: |
          az group list
          az webapp list --resource-group ${{ env.RG }}
```

## Ventajas vs Service Principal Secrets

| Aspecto | Service Principal Secret | Workload Identity |
|---------|-------------------------|-------------------|
| Secrets en GitHub | Sí (password) | No (solo IDs) |
| Rotación | Manual cada 90 días | Automática |
| Scope | Amplio | Granular (repo/branch/env) |
| Audit trail | Limitado | Completo (OIDC claims) |
| Expiración | Hasta 2 años | Token expira en minutos |

## Debugging

```yaml
- name: Debug OIDC Token
  run: |
    curl -H "Authorization: bearer $ACTIONS_ID_TOKEN_REQUEST_TOKEN" \
         "$ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" \
         | jq -R 'split(".") | .[1] | @base64d | fromjson'
```

Claims del token:

```json
{
  "iss": "https://token.actions.githubusercontent.com",
  "sub": "repo:myorg/myrepo:ref:refs/heads/main",
  "aud": "api://AzureADTokenExchange",
  "ref": "refs/heads/main",
  "sha": "abc123...",
  "repository": "myorg/myrepo",
  "repository_owner": "myorg",
  "run_id": "123456789",
  "workflow": "Deploy to Azure"
}
```

## Buenas prácticas

- **Usa environments**: Requiere aprobaciones manuales para producción
- **Scope mínimo**: Asigna roles solo al resource group necesario
- **Multiple credentials**: Diferentes para dev/staging/prod
- **Branch protection**: Solo permite deploy desde branches protegidos
- **Audit logs**: Revisa sign-in logs en Azure AD regularmente

## Referencias

- [Workload identity federation](https://learn.microsoft.com/en-us/entra/workload-id/workload-identity-federation)
- [GitHub Actions OIDC with Azure](https://docs.github.com/en/actions/deployment/security-hardening-your-deployments/configuring-openid-connect-in-azure)
