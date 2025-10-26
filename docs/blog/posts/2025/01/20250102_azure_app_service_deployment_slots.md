---
draft: false
date: 2025-01-02
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure App Service
  - Deployment Slots
  - DevOps
---

# Azure App Service Deployment Slots: Despliegues sin downtime

## Resumen

Los Deployment Slots en Azure App Service te permiten desplegar nuevas versiones de tu aplicación sin tiempo de inactividad. Voy al grano: es la forma más sencilla de implementar blue-green deployments en Azure.

## ¿Qué son los Deployment Slots?

Los Deployment Slots son entornos en vivo dentro de tu App Service donde puedes desplegar diferentes versiones de tu aplicación. Cada slot:

- Tiene su propia URL
- Puede tener configuración independiente
- Permite swap instantáneo entre slots
- Comparte el mismo plan de App Service

## Caso de uso típico

```bash
# Variables
RG="my-rg"
APP_NAME="my-webapp"
LOCATION="westeurope"

# Crear App Service Plan (mínimo Standard)
az appservice plan create \
  --name ${APP_NAME}-plan \
  --resource-group $RG \
  --location $LOCATION \
  --sku S1

# Crear App Service
az webapp create \
  --name $APP_NAME \
  --resource-group $RG \
  --plan ${APP_NAME}-plan

# Crear slot de staging
az webapp deployment slot create \
  --name $APP_NAME \
  --resource-group $RG \
  --slot staging
```

## Workflow de despliegue

**1. Desplegar a staging:**

```bash
# Desplegar código al slot staging
az webapp deployment source config-zip \
  --resource-group $RG \
  --name $APP_NAME \
  --slot staging \
  --src app.zip
```

**2. Validar en staging:**

URL del slot: `https://{app-name}-staging.azurewebsites.net`

**3. Hacer swap a producción:**

```bash
# Swap directo staging -> production
az webapp deployment slot swap \
  --resource-group $RG \
  --name $APP_NAME \
  --slot staging \
  --target-slot production

# Swap con preview (recomendado)
az webapp deployment slot swap \
  --resource-group $RG \
  --name $APP_NAME \
  --slot staging \
  --target-slot production \
  --action preview

# Después de validar, completar swap
az webapp deployment slot swap \
  --resource-group $RG \
  --name $APP_NAME \
  --slot staging \
  --target-slot production \
  --action swap
```

!!! warning "Proceso de swap"
    Durante el swap, Azure sigue este proceso:
    1. Aplica settings del target slot al source slot
    2. Espera a que todas las instancias se reinicien y calienten
    3. Si todas las instancias están healthy, intercambia el routing
    4. El target slot (production) queda con la nueva app sin downtime
    
    Tiempo total: 1-5 minutos dependiendo de warmup. La producción NO sufre downtime.

## Configuración sticky vs swappable

No toda la configuración se intercambia en el swap:

**Sticky (no se mueve con el código):**
- App settings marcadas como "Deployment slot setting"
- Connection strings marcadas como "Deployment slot setting"
- Custom domains
- Nonpublic certificates y TLS/SSL settings
- Scale settings
- IP restrictions
- Always On, Diagnostic settings, CORS

**Swappable (se mueve con el código):**
- General settings (framework version, 32/64-bit)
- App settings no marcadas
- Handler mappings
- Public certificates
- WebJobs content
- Hybrid connections
- Virtual network integration

**Configurar sticky settings:**

Desde el portal Azure:
1. Ir a **Configuration** → **Application settings** del slot
2. Añadir/editar app setting
3. Marcar checkbox **Deployment slot setting**
4. Apply

```bash
# Crear app setting en slot staging
az webapp config appsettings set \
  --resource-group $RG \
  --name $APP_NAME \
  --slot staging \
  --settings DATABASE_URL="staging-connection-string"

# Para hacerla sticky: usar portal o ARM template
# No hay flag CLI directo para marcar como slot-specific
```

## Auto-swap para CI/CD

```bash
# Configurar auto-swap desde staging a production
az webapp deployment slot auto-swap \
  --resource-group $RG \
  --name $APP_NAME \
  --slot staging \
  --auto-swap-slot production
```

Con auto-swap habilitado:
1. Push a staging → despliegue automático
2. Warmup automático del slot
3. Swap a producción sin intervención manual

**Customizar warmup path:**

```bash
# Configurar URL de warmup personalizada
az webapp config appsettings set \
  --resource-group $RG \
  --name $APP_NAME \
  --slot staging \
  --settings WEBSITE_SWAP_WARMUP_PING_PATH="/health/ready"

# Validar solo códigos HTTP específicos
az webapp config appsettings set \
  --resource-group $RG \
  --name $APP_NAME \
  --slot staging \
  --settings WEBSITE_SWAP_WARMUP_PING_STATUSES="200,202"
```

## Buenas prácticas

- **Usar staging para testing**: Siempre valida en staging antes del swap
- **Configurar health checks**: Azure verifica el slot antes de hacer swap
- **Mantener paridad**: Staging debe replicar producción (misma configuración, DB de test similar)
- **Rollback rápido**: Si falla, haz swap inverso inmediatamente
- **Limitar slots**: Máximo 2-3 slots por app (staging, pre-production)

!!! tip "Ahorro de costos"
    Los slots comparten recursos del App Service Plan. No pagas más por tener staging, pero requieres tier Standard o superior.

## Monitoring del swap

```bash
# Ver historial de swaps
az webapp deployment slot list \
  --resource-group $RG \
  --name $APP_NAME

# Logs durante el swap
az webapp log tail \
  --resource-group $RG \
  --name $APP_NAME \
  --slot staging
```

## Referencias

- [Set up staging environments - Azure App Service](https://learn.microsoft.com/en-us/azure/app-service/deploy-staging-slots)
- [Azure CLI - webapp deployment slot](https://learn.microsoft.com/en-us/cli/azure/webapp/deployment/slot)
