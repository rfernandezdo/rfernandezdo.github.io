---
draft: false
date: 2025-01-22
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure Container Registry
  - Docker
  - Security
---

# Azure Container Registry: Geo-replication y webhook automation

## Resumen

Azure Container Registry (ACR) no es solo un registro Docker. Con geo-replication consigues latencia mínima global y con webhooks automatizas despliegues. Aquí el setup avanzado.

## ¿Cuándo usar ACR vs Docker Hub?

**Usa ACR si:**
- ✅ Necesitas registry privado en Azure
- ✅ Quieres integración nativa con AKS, App Service, Container Apps
- ✅ Compliance requiere datos en región específica
- ✅ Necesitas geo-replication

**Usa Docker Hub si:**
- Imágenes públicas open source
- Proyectos personales sin requisitos enterprise

## Crear ACR con Premium SKU

```bash
# Variables
RG="my-rg"
ACR_NAME="myacr$(date +%s)"
LOCATION="westeurope"

# Crear ACR Premium (requerido para geo-replication)
az acr create \
  --resource-group $RG \
  --name $ACR_NAME \
  --sku Premium \
  --location $LOCATION \
  --admin-enabled false
```

SKUs disponibles:
- **Basic**: €4.4/mes - Sin geo-replication, webhooks limitados
- **Standard**: €22/mes - Webhooks, mejor throughput
- **Premium**: €44/mes - Geo-replication, Content Trust, Private Link

## Geo-replication

Replica tu registry a múltiples regiones para:
- Reducir latencia de pull
- Alta disponibilidad
- Cumplir data residency

```bash
# Replicar a East US
az acr replication create \
  --resource-group $RG \
  --registry $ACR_NAME \
  --location eastus

# Replicar a Southeast Asia
az acr replication create \
  --resource-group $RG \
  --registry $ACR_NAME \
  --location southeastasia

# Listar réplicas
az acr replication list \
  --resource-group $RG \
  --registry $ACR_NAME \
  --output table
```

Ahora tu imagen `myacr.azurecr.io/app:v1` está disponible en 3 regiones con un solo push.

## Push de imágenes

```bash
# Login a ACR
az acr login --name $ACR_NAME

# Tag imagen
docker tag my-app:latest ${ACR_NAME}.azurecr.io/my-app:v1.0

# Push
docker push ${ACR_NAME}.azurecr.io/my-app:v1.0

# Listar imágenes
az acr repository list --name $ACR_NAME --output table

# Ver tags
az acr repository show-tags \
  --name $ACR_NAME \
  --repository my-app \
  --output table
```

## ACR Tasks: Build en Azure

Build imágenes sin Docker local:

```bash
# Build desde Dockerfile en repo Git
az acr build \
  --resource-group $RG \
  --registry $ACR_NAME \
  --image my-app:{{.Run.ID}} \
  --image my-app:latest \
  https://github.com/myorg/myapp.git#main

# Build desde directorio local
az acr build \
  --resource-group $RG \
  --registry $ACR_NAME \
  --image my-app:v1.1 \
  .
```

## Webhooks para CI/CD

Trigger despliegue automático cuando hay nuevo push:

```bash
# Crear webhook
az acr webhook create \
  --resource-group $RG \
  --registry $ACR_NAME \
  --name deployWebhook \
  --actions push \
  --uri https://my-function-app.azurewebsites.net/api/deploy \
  --scope my-app:*
```

Payload del webhook:

```json
{
  "id": "unique-id",
  "timestamp": "2025-01-22T10:00:00Z",
  "action": "push",
  "target": {
    "mediaType": "application/vnd.docker.distribution.manifest.v2+json",
    "size": 1234,
    "digest": "sha256:abc123...",
    "repository": "my-app",
    "tag": "v1.2"
  },
  "request": {
    "id": "req-id",
    "host": "myacr.azurecr.io",
    "method": "PUT",
    "useragent": "docker/20.10.12"
  }
}
```

## Azure Function para auto-deploy

```python
import azure.functions as func
import json
import subprocess

def main(req: func.HttpRequest) -> func.HttpResponse:
    # Parse webhook payload
    webhook_data = req.get_json()
    
    repository = webhook_data['target']['repository']
    tag = webhook_data['target']['tag']
    image = f"myacr.azurecr.io/{repository}:{tag}"
    
    # Trigger deployment (ejemplo: kubectl)
    subprocess.run([
        'kubectl', 'set', 'image',
        'deployment/my-app',
        f'app={image}',
        '--record'
    ])
    
    return func.HttpResponse(f"Deployed {image}", status_code=200)
```

## Security: Managed Identity

```bash
# Asignar managed identity a AKS
AKS_PRINCIPAL_ID=$(az aks show \
  --resource-group $RG \
  --name my-aks \
  --query identityProfile.kubeletidentity.objectId -o tsv)

# Dar permiso AcrPull
az role assignment create \
  --assignee $AKS_PRINCIPAL_ID \
  --role AcrPull \
  --scope $(az acr show --resource-group $RG --name $ACR_NAME --query id -o tsv)
```

Ahora AKS puede pullear sin passwords:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-app
spec:
  template:
    spec:
      containers:
      - name: app
        image: myacr.azurecr.io/my-app:v1.0
        # No imagePullSecrets needed!
```

## Content Trust (image signing)

```bash
# Habilitar Content Trust
az acr config content-trust update \
  --resource-group $RG \
  --registry $ACR_NAME \
  --status enabled

# Docker content trust
export DOCKER_CONTENT_TRUST=1
export DOCKER_CONTENT_TRUST_SERVER=https://${ACR_NAME}.azurecr.io

# Push firmado
docker push ${ACR_NAME}.azurecr.io/my-app:v1.0-signed
```

## Vulnerability scanning

```bash
# Habilitar Microsoft Defender for Container Registries
az security pricing create \
  --name ContainerRegistry \
  --tier Standard

# Ver vulnerabilidades
az acr repository show \
  --name $ACR_NAME \
  --repository my-app \
  --query "metadata.vulnerabilities"
```

## Retention policy (cleanup automático)

```bash
# Retener solo últimos 30 días
az acr config retention update \
  --registry $ACR_NAME \
  --status enabled \
  --days 30 \
  --type UntaggedManifests

# Borrar tags viejos manualmente
az acr repository show-tags \
  --name $ACR_NAME \
  --repository my-app \
  --orderby time_asc \
  --output tsv \
  | head -n 10 \
  | xargs -I {} az acr repository delete \
      --name $ACR_NAME \
      --image my-app:{} \
      --yes
```

## Import imágenes desde Docker Hub

```bash
# Importar imagen pública
az acr import \
  --name $ACR_NAME \
  --source docker.io/library/nginx:latest \
  --image nginx:latest

# Importar desde otro ACR
az acr import \
  --name $ACR_NAME \
  --source otheracr.azurecr.io/app:v1 \
  --image app:v1 \
  --username <user> \
  --password <password>
```

## Buenas prácticas

- **Tagging strategy**: Usa semver (`v1.2.3`) + `latest` + commit SHA
- **Multi-arch images**: Build para amd64 y arm64
- **Scan antes de deploy**: Integra vulnerability scanning en CI
- **Cleanup periódico**: Retención de 30-90 días
- **Private endpoint**: No expongas ACR a Internet
- **Geo-replication**: Mínimo 2 regiones para producción

!!! tip "Costos"
    - Storage: €0.08/GB/mes
    - Geo-replication: €44/mes por región
    - Build minutes: €0.0008/segundo
    
    Ejemplo: ACR Premium + 50GB + 2 réplicas = ~€140/mes

## Referencias

- [Azure Container Registry documentation](https://learn.microsoft.com/en-us/azure/container-registry/)
- [ACR geo-replication](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-geo-replication)
- [ACR webhooks](https://learn.microsoft.com/en-us/azure/container-registry/container-registry-webhook)
