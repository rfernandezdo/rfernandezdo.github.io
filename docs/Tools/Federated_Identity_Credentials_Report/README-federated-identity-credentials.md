# Script de Reporte para Federated Identity Credentials

Este conjunto de scripts genera reportes completos de todas las credenciales de identidad federada asociadas a identidades administradas asignadas por el usuario en Azure (`Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials`).

## 🚀 Características

- **Autenticación segura**: Soporte para Managed Identity y Azure CLI
- **Múltiples formatos**: Exportación a JSON, CSV y Excel
- **Filtrado flexible**: Por suscripción, grupo de recursos o identidad específica
- **Soporte multi-suscripción**: Procesa todas las suscripciones disponibles con una sola ejecución
- **Filtrado por tenant**: Cuando se especifica un tenant, solo procesa suscripciones de ese tenant
- **Logging detallado**: Seguimiento completo de operaciones
- **Manejo robusto de errores**: Retry logic con exponential backoff
- **Multiplataforma**: Versiones en Python y PowerShell

## 📋 Requisitos

### Para la versión Python

```bash
# Instalar dependencias
pip install -r requirements-federated-identity-report.txt
```

**Dependencias principales:**
- `azure-identity >= 1.15.0`
- `azure-mgmt-msi >= 7.0.0`
- `azure-mgmt-resource >= 23.0.0`
- `pandas >= 2.0.0`
- `openpyxl >= 3.1.0`

### Para la versión PowerShell

```powershell
# Instalar módulos de Azure PowerShell
Install-Module Az.Accounts -Force
Install-Module Az.ManagedServiceIdentity -Force
Install-Module Az.Resources -Force

# Para exportar a Excel (opcional)
Install-Module ImportExcel -Force
```

> **Nota**: En PowerShell, el parámetro `-Verbose` es proporcionado automáticamente por el framework de PowerShell cuando se usa `[CmdletBinding()]`. No necesitas definirlo manualmente.

## Files

- [federated-identity-credentials-report.py](./federated-identity-credentials-report.py): Script en Python para generar reportes de credenciales federadas.
- [federated-identity-credentials-report.ps1](./federated-identity-credentials-report.ps1): Script en PowerShell para generar reportes de credenciales federadas.
- [requirements-federated-identity-report.txt](./requirements-federated-identity-report.txt): Archivo de dependencias para la versión Python.

## 🔐 Autenticación

### Managed Identity (Recomendado para Azure)
```bash
# Python
python federated-identity-credentials-report.py --subscription-id "12345678-1234-1234-1234-123456789012"

# PowerShell
.\federated-identity-credentials-report.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012"
```

### Azure CLI
```bash
# Primero hacer login
az login

# Python
python federated-identity-credentials-report.py --subscription-id "12345678-1234-1234-1234-123456789012" --use-cli-auth

# PowerShell
.\federated-identity-credentials-report.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012" -UseCliAuth
```

## 🏢 Filtrado por Tenant

Cuando especificas un `tenant-id` (Python) o `TenantId` (PowerShell), los scripts automáticamente:

1. **Filtran las suscripciones** para procesar únicamente las que pertenecen al tenant especificado
2. **Establecen el contexto** de autenticación en el tenant correcto
3. **Incluyen información del tenant** en los metadatos del reporte

```bash
# Python - Solo suscripciones del tenant específico
python federated-identity-credentials-report.py --all-subscriptions --tenant-id "df1b7014-cf34-4f82-81dc-f4c1364b9cfc"

# PowerShell - Solo suscripciones del tenant específico  
.\federated-identity-credentials-report.ps1 -AllSubscriptions -TenantId "df1b7014-cf34-4f82-81dc-f4c1364b9cfc"
```

> **⚠️ Nota importante**: Sin el parámetro de tenant, el script procesará suscripciones de todos los tenants a los que tienes acceso.

## 📖 Uso

### Ejemplos Python

```bash
# Reporte básico de una suscripción específica
python federated-identity-credentials-report.py \
    --subscription-id "12345678-1234-1234-1234-123456789012"

# Reporte de TODAS las suscripciones disponibles
python federated-identity-credentials-report.py \
    --all-subscriptions

# Especificar tenant específico
python federated-identity-credentials-report.py \
    --all-subscriptions \
    --tenant-id "your-tenant-id"

# Filtrar por grupo de recursos en todas las suscripciones
python federated-identity-credentials-report.py \
    --all-subscriptions \
    --resource-group "mi-resource-group"

# Filtrar por identidad específica en una suscripción
python federated-identity-credentials-report.py \
    --subscription-id "12345678-1234-1234-1234-123456789012" \
    --identity-name "mi-managed-identity"

# Exportar a Excel todas las suscripciones
python federated-identity-credentials-report.py \
    --all-subscriptions \
    --format excel \
    --output "reporte-completo.xlsx"

# Modo verbose para debugging
python federated-identity-credentials-report.py \
    --all-subscriptions \
    --verbose
```

### Ejemplos PowerShell

```powershell
# Reporte básico de una suscripción específica
.\federated-identity-credentials-report.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012"

# Reporte de TODAS las suscripciones disponibles
.\federated-identity-credentials-report.ps1 -AllSubscriptions

# Especificar tenant específico
.\federated-identity-credentials-report.ps1 `
    -AllSubscriptions `
    -TenantId "your-tenant-id"

# Filtrar por grupo de recursos en todas las suscripciones
.\federated-identity-credentials-report.ps1 `
    -AllSubscriptions `
    -ResourceGroupName "mi-resource-group"

# Filtrar por identidad específica en una suscripción
.\federated-identity-credentials-report.ps1 `
    -SubscriptionId "12345678-1234-1234-1234-123456789012" `
    -IdentityName "mi-managed-identity"

# Exportar a Excel todas las suscripciones
.\federated-identity-credentials-report.ps1 `
    -AllSubscriptions `
    -Format Excel `
    -OutputFile "reporte-completo.xlsx"

# Modo verbose para debugging
.\federated-identity-credentials-report.ps1 `
    -AllSubscriptions `
    -Verbose
```

## 📊 Estructura del Reporte

El reporte incluye la siguiente información para cada credencial de identidad federada:

### Información de la Identidad Administrada
- `identity_name`: Nombre de la identidad administrada
- `identity_id`: ID de recurso completo de la identidad
- `identity_resource_group`: Grupo de recursos de la identidad
- `identity_location`: Región de Azure donde está la identidad
- `identity_principal_id`: Principal ID de la identidad
- `identity_client_id`: Client ID de la identidad
- `identity_tenant_id`: Tenant ID de la identidad

### Información de la Credencial Federada
- `credential_name`: Nombre de la credencial federada
- `credential_id`: ID de recurso completo de la credencial
- `credential_issuer`: Issuer de la credencial (ej: GitHub, OIDC provider)
- `credential_subject`: Subject claim de la credencial
- `credential_audiences`: Audiencias de la credencial
- `credential_description`: Descripción de la credencial
- `credential_type`: Tipo de recurso de la credencial

### Metadatos del Reporte
- `subscription_id`: ID de la suscripción de Azure
- `subscription_name`: Nombre de la suscripción de Azure
- `tenant_id`: ID del tenant de Azure
- `report_timestamp`: Timestamp de generación del reporte

## 🎯 Casos de Uso

### 1. Auditoría de Seguridad
Identifica todas las credenciales federadas en tu entorno Azure para auditorías de seguridad y compliance.

### 2. Gestión de Accesos
Revisa qué identidades externas (GitHub Actions, OIDC providers) tienen acceso a tus recursos de Azure.

### 3. Inventario de Recursos
Mantén un inventario actualizado de todas las configuraciones de identidad federada.

### 4. Troubleshooting
Diagnostica problemas de autenticación identificando configuraciones incorrectas o faltantes.

### 5. Compliance y Governance
Genera reportes regulares para demostrar compliance con políticas de seguridad corporativas.

## 🔍 Formatos de Salida

### JSON
```json
{
  "identity_name": "github-actions-identity",
  "identity_id": "/subscriptions/.../resourcegroups/rg/providers/Microsoft.ManagedIdentity/userAssignedIdentities/github-actions-identity",
  "credential_issuer": "https://token.actions.githubusercontent.com",
  "credential_subject": "repo:myorg/myrepo:ref:refs/heads/main",
  "credential_audiences": ["api://AzureADTokenExchange"]
}
```

### CSV
Formato tabular ideal para análisis en Excel o herramientas de BI.

### Excel
Incluye formato automático, anchos de columna ajustados y hojas organizadas.

## 🚨 Troubleshooting

### Error de Autenticación
```bash
# Verificar login de Azure CLI
az account show

# Verificar permisos
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

### Error de Permisos
Asegúrate de tener los siguientes permisos:
- `Microsoft.ManagedIdentity/userAssignedIdentities/read`
- `Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials/read`
- `Microsoft.Resources/subscriptions/resourceGroups/read`

### Dependencias Faltantes
```bash
# Python
pip install --upgrade azure-identity azure-mgmt-msi pandas openpyxl

# PowerShell
Update-Module Az -Force
```

## 📝 Logging

Los scripts generan logs detallados en `federated_identity_report.log` que incluyen:
- Timestamps de operaciones
- Errores y advertencias
- Progreso de procesamiento
- Información de autenticación

## 🔒 Mejores Prácticas de Seguridad

1. **Usa Managed Identity** cuando sea posible en lugar de Service Principals
2. **Rota credenciales** regularmente si usas autenticación basada en secretos
3. **Aplica principio de menor privilegio** para los permisos de RBAC
4. **Audita regularmente** las credenciales federadas usando estos reportes
5. **Mantén logs seguros** y considera usar Azure Monitor para logging centralizado

## 🤝 Contribuciones

Este script sigue las mejores prácticas de Azure y está diseñado para ser extensible. Sugerencias de mejora:

- Soporte para filtros adicionales
- Integración con Azure Monitor
- Exportación a otros formatos (XML, YAML)
- Configuración desde archivos de configuración
- Integración con pipelines de CI/CD

## 📄 Licencia

Este script es proporcionado como ejemplo educativo y debe ser revisado y adaptado según las necesidades específicas de tu organización antes de usar en producción.

---

**Nota**: Este script fue generado siguiendo las mejores prácticas de desarrollo de Azure, incluyendo el uso de Managed Identity, manejo robusto de errores, y logging comprehensivo.
