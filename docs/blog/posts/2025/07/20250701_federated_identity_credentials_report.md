---
draft: false
date: 2025-07-01
authors:
  - rfernandezdo
categories:
  - Azure
  - Security
tags:
  - Azure
  - Federated Identity Credentials
  - PowerShell
  - Python
  - Security
  - Managed Identity
---

# **Scripts de Reporte para Credenciales Federadas de Azure: Visibilidad Total de tus Identidades Administradas**

¡Hola a todos! En el mundo de la seguridad en la nube, mantener un control exhaustivo sobre las credenciales federadas es fundamental para una gestión de identidades robusta. Hoy quiero compartir con vosotros una solución que he desarrollado para resolver uno de los retos más comunes: **generar reportes completos de las credenciales federadas de identidades administradas en Azure**.

Si habéis trabajado con **GitHub Actions**, **Azure DevOps**, o cualquier sistema CI/CD que se integre con Azure usando identidades administradas, sabréis lo importante que es tener visibilidad sobre qué credenciales están configuradas, dónde y cómo.

## **El Problema: Falta de Visibilidad**

Cuando gestionáis múltiples suscripciones de Azure con decenas o cientos de identidades administradas, es muy difícil responder a preguntas básicas como:

- ¿Qué credenciales federadas tengo configuradas en todas mis suscripciones?
- ¿Qué repositorios de GitHub tienen acceso a mis recursos de Azure?
- ¿Hay credenciales obsoletas que debería eliminar?
- ¿Cómo puedo auditar todas mis configuraciones de identidad federada?

El portal de Azure nos permite ver esto recurso por recurso, pero no hay una vista consolidada que nos permita tener el "big picture" de toda nuestra configuración de seguridad.

## **La Solución: Scripts de Reporte Automatizados**

He desarrollado una solución completa que incluye scripts tanto en **Python** como en **PowerShell** para generar reportes detallados de todas las credenciales federadas de identidades administradas en vuestro entorno Azure.

### **Características Principales**

✅ **Soporte Multi-Suscripción**: Procesa todas las suscripciones disponibles o las que especifiquéis  
✅ **Filtrado por Tenant**: Permite filtrar suscripciones por tenant específico  
✅ **Múltiples Formatos**: Exporta a JSON, CSV y Excel  
✅ **Logging Robusto**: Logs detallados separados de los datos de salida  
✅ **Validación de Datos**: Evita procesar identidades con datos inválidos  
✅ **Autenticación Flexible**: Soporta Managed Identity, Azure CLI, MFA, etc.  
✅ **Archivo de Tuplas**: Genera un archivo adicional con solo las tuplas de credenciales  

### **¿Qué Información Captura?**

Los scripts capturan información completa tanto de las identidades administradas como de sus credenciales federadas:

**Información de la Identidad:**
- Nombre y ID de la identidad
- Grupo de recursos y ubicación
- Principal ID y Client ID
- Tenant ID

**Información de las Credenciales Federadas:**
- Nombre e ID de la credencial
- Issuer (emisor)
- Subject (sujeto)
- Audiences (audiencias)
- Descripción y tipo

**Metadatos del Reporte:**
- ID y nombre de la suscripción
- Tenant ID
- Timestamp del reporte

## **¿Cómo Empezar?**

### **Requisitos Previos**

**Para Python:**
```bash
pip install azure-identity azure-mgmt-msi azure-mgmt-resource pandas openpyxl
```

**Para PowerShell:**
```powershell
Install-Module -Name Az.Accounts, Az.ManagedServiceIdentity, Az.Resources, ImportExcel
```

### **Ejemplos de Uso**

**Script de Python:**
```bash
# Reporte de todas las suscripciones
python federated-identity-credentials-report.py --all-subscriptions --format excel

# Reporte filtrado por tenant
python federated-identity-credentials-report.py --tenant-id "your-tenant-id" --all-subscriptions --format json

# Reporte de una suscripción específica
python federated-identity-credentials-report.py --subscription-id "12345678-1234-1234-1234-123456789012" --format csv
```

**Script de PowerShell:**
```powershell
# Reporte de todas las suscripciones
.\federated-identity-credentials-report.ps1 -AllSubscriptions -Format Excel

# Reporte filtrado por tenant
.\federated-identity-credentials-report.ps1 -TenantId "your-tenant-id" -AllSubscriptions -Format JSON

# Reporte de un grupo de recursos específico
.\federated-identity-credentials-report.ps1 -SubscriptionId "12345678-1234-1234-1234-123456789012" -ResourceGroupName "my-rg" -Format CSV
```

## **Características Avanzadas**

### **Archivo de Tuplas de Credenciales**

Además del reporte principal, los scripts generan automáticamente un archivo adicional con solo las tuplas de credenciales (`credential_issuer`, `credential_subject`, `credential_audiences`, `credential_type`). Esto es especialmente útil para:

- Análisis de patrones de configuración
- Auditorías de seguridad
- Integración con otras herramientas de análisis

### **Logging Separado**

Una característica importante es que los logs nunca se mezclan con los datos de salida. Los logs van a `stderr` y a un archivo de log separado, mientras que los datos puros van a `stdout` o al archivo especificado. Esto es crucial para la automatización y integración con pipelines de CI/CD.

### **Validación de Datos**

Los scripts incluyen validación robusta para evitar procesar identidades con nombres vacíos o nulos, lo que puede ocurrir en ciertos escenarios de configuración incompleta.

## **Casos de Uso Reales**

### **1. Auditoría de Seguridad**
```bash
# Generar reporte completo en Excel para auditoría
python federated-identity-credentials-report.py --all-subscriptions --format excel --output security-audit-$(date +%Y%m%d).xlsx
```

### **2. Cleanup de Credenciales Obsoletas**
```bash
# Exportar a CSV para análisis con herramientas de datos
python federated-identity-credentials-report.py --all-subscriptions --format csv | grep "old-repo-name"
```

### **3. Monitoreo Continuo**
```bash
# Integrar en pipeline de CI/CD para monitoreo continuo
python federated-identity-credentials-report.py --tenant-id "$TENANT_ID" --all-subscriptions --format json > daily-report.json
```

## **Estructura de Archivos Generados**

**Archivo Principal** (`federated_identity_credentials_report_YYYYMMDD_HHMMSS.json/csv/xlsx`):
```json
[
  {
    "identity_name": "github-actions-identity",
    "identity_id": "/subscriptions/.../userAssignedIdentities/github-actions-identity",
    "identity_resource_group": "security-rg",
    "identity_location": "eastus",
    "credential_name": "GitHub-Main-Branch",
    "credential_issuer": "https://token.actions.githubusercontent.com",
    "credential_subject": "repo:myorg/myrepo:ref:refs/heads/main",
    "credential_audiences": "api://AzureADTokenExchange",
    "subscription_name": "Production",
    "tenant_id": "12345678-1234-1234-1234-123456789012",
    "report_timestamp": "2025-07-01T10:30:00"
  }
]
```

**Archivo de Tuplas** (`credential_tuples_YYYYMMDD_HHMMSS.json/csv/xlsx`):
```json
[
  {
    "credential_issuer": "https://token.actions.githubusercontent.com",
    "credential_subject": "repo:myorg/myrepo:ref:refs/heads/main",
    "credential_audiences": "api://AzureADTokenExchange",
    "credential_type": "Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials"
  }
]
```

## **Mejores Prácticas de Uso**

### **1. Automatización**
Integrad estos scripts en vuestros pipelines de CI/CD para generar reportes automáticos:

```yaml
# GitHub Actions ejemplo
- name: Generate Federated Credentials Report
  run: |
    python federated-identity-credentials-report.py --all-subscriptions --format json --output report-${{ github.run_number }}.json
    
- name: Upload Report as Artifact
  uses: actions/upload-artifact@v3
  with:
    name: federated-credentials-report
    path: report-*.json
```

### **2. Monitoreo Regular**
Ejecutad los scripts de forma regular (diaria o semanal) para detectar cambios no autorizados:

```bash
# Cron job ejemplo
0 6 * * 1 /usr/bin/python3 /path/to/federated-identity-credentials-report.py --all-subscriptions --format excel --output /reports/weekly-$(date +\%Y\%m\%d).xlsx
```

### **3. Análisis de Drift**
Comparad reportes de diferentes fechas para detectar cambios de configuración:

```bash
# Comparar reportes para detectar cambios
diff <(jq -S . report-20250701.json) <(jq -S . report-20250708.json)
```

## **Consideraciones de Seguridad**

⚠️ **Permisos Mínimos**: Los scripts requieren permisos de lectura sobre las identidades administradas y sus credenciales federadas  
⚠️ **Datos Sensibles**: Los reportes contienen información de configuración sensible - almacenadlos de forma segura  
⚠️ **Logs**: Revisad los logs regularmente para detectar errores de autenticación o acceso  

## **Conclusión**

Tener visibilidad completa sobre las credenciales federadas de vuestras identidades administradas es fundamental para mantener una postura de seguridad sólida en Azure. Estos scripts os permitirán:

- **Reducir el riesgo de seguridad** mediante auditorías regulares
- **Cumplir con requisitos de compliance** generando reportes detallados
- **Optimizar la gestión** identificando credenciales obsoletas o mal configuradas
- **Automatizar el monitoreo** integrando los scripts en vuestros procesos existentes

Los scripts están disponibles en mi repositorio y son completamente gratuitos y de código abierto. Si os resultan útiles, no dudéis en contribuir con mejoras o reportar issues.

¡Espero que esta herramienta os ayude a mantener vuestros entornos Azure más seguros y mejor documentados!

**Enlaces útiles:**
- 📖 [Documentación completa y scripts](https://rfernandezdo.github.io/Tools/Federated_Identity_Credentials_Report/README-federated-identity-credentials/)

---
