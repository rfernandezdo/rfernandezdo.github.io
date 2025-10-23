---
draft: false
date: 2025-01-01
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure Cost Management
  - FinOps
  - Presupuestos
  - Optimización
---

# Azure Cost Management: planifica tu presupuesto 2025

## Resumen

enero es el mes para configurar **presupuestos y alertas de costes** en Azure. Con Azure Cost Management puedes establecer límites, recibir notificaciones y evitar sorpresas en la factura. En este post verás cómo crear presupuestos, configurar alertas automáticas y usar Azure Advisor para optimizar gastos desde el primer día del año.

<!-- more -->

## ¿Por qué configurar presupuestos en enero?

**Razones operativas:**

- **Año fiscal nuevo**: Mayoría de empresas renuevan presupuestos en enero
- **Cuotas de subscripción**: Azure asigna cuotas anuales que conviene monitorizar desde el inicio
- **Planificación proactiva**: Detectar desviaciones tempranas permite corregir antes del Q2
- **Compliance**: Auditorías internas requieren evidencia de control de gastos

**Beneficios inmediatos:**

- Alertas por email/SMS cuando el gasto alcanza umbrales (50%, 80%, 100%)
- Dashboards con proyección de costes para fin de mes/año
- Análisis de tendencias para identificar recursos zombies
- Recomendaciones automáticas de Azure Advisor

---

## Crear presupuestos desde Azure Portal

### Paso 1: Acceder a Cost Management

```bash
# Navega al portal
https://portal.azure.com/#view/Microsoft_Azure_CostManagement/Menu/~/overview

# O usa Azure CLI para obtener costes actuales
az consumption usage list \
  --start-date 2025-01-01 \
  --end-date 2025-01-31 \
  --query "[?contains(instanceName,'prod')].{Name:instanceName, Cost:pretaxCost}" \
  --output table
```

**Desde el portal:**

1. **Cost Management + Billing** → Tu subscription
2. **Cost Management** → **Budgets**
3. **Add** → Configurar parámetros

### Paso 2: Configurar presupuesto mensual

**Parámetros clave:**

| Campo | Valor recomendado | Notas |
|-------|-------------------|-------|
| **Name** | `Budget-Prod-2025-Monthly` | Nomenclatura clara |
| **Reset period** | Monthly | También existe Quarterly/Annually |
| **Creation date** | 2025-01-01 | Inicio del periodo fiscal |
| **Expiration date** | 2025-12-31 | Fin de año |
| **Amount** | €5,000 | Según tu presupuesto aprobado |

**Filtros avanzados:**

```yaml
# Ejemplo: presupuesto solo para recursos de producción
Scope: Subscription
Filters:
  - Tag: Environment = Production
  - Resource Group: rg-prod-*
  - Location: West Europe, North Europe
```

### Paso 3: Configurar alertas

**Umbrales típicos:**

- **50%**: Alerta informativa (email a equipo)
- **80%**: Alerta warning (email a managers + Slack webhook)
- **90%**: Alerta crítica (email a FinOps + ticket automático)
- **100%**: Alerta de exceso (bloqueo de recursos opcionales via Policy)

**Configuración de alerta:**

```json
{
  "name": "Alert-80-Percent",
  "enabled": true,
  "operator": "GreaterThan",
  "threshold": 80,
  "thresholdType": "Actual",
  "contactEmails": [
    "devops@company.com",
    "finops@company.com"
  ],
  "contactRoles": [
    "Owner",
    "Contributor"
  ],
  "contactGroups": [
    "/subscriptions/xxx/resourceGroups/rg-monitoring/providers/microsoft.insights/actionGroups/ag-cost-alerts"
  ]
}
```

---

## Automatizar presupuestos con Bicep/Terraform

### Bicep template

```bicep
param budgetName string = 'budget-prod-monthly'
param amount int = 5000
param startDate string = '2025-01-01'
param endDate string = '2025-12-31'
param contactEmails array = ['devops@company.com']

resource budget 'Microsoft.Consumption/budgets@2023-11-01' = {
  name: budgetName
  properties: {
    category: 'Cost'
    amount: amount
    timeGrain: 'Monthly'
    timePeriod: {
      startDate: startDate
      endDate: endDate
    }
    filter: {
      tags: {
        Environment: ['Production']
      }
    }
    notifications: {
      'Alert-80': {
        enabled: true
        operator: 'GreaterThan'
        threshold: 80
        contactEmails: contactEmails
        thresholdType: 'Actual'
      }
      'Alert-100': {
        enabled: true
        operator: 'GreaterThan'
        threshold: 100
        contactEmails: contactEmails
        thresholdType: 'Forecasted'
      }
    }
  }
}
```

**Deploy:**

```bash
az deployment sub create \
  --location westeurope \
  --template-file budget.bicep \
  --parameters amount=5000 contactEmails="['devops@company.com']"
```

### Terraform

```hcl
resource "azurerm_consumption_budget_subscription" "prod_monthly" {
  name            = "budget-prod-monthly"
  subscription_id = data.azurerm_subscription.current.id

  amount     = 5000
  time_grain = "Monthly"

  time_period {
    start_date = "2025-01-01T00:00:00Z"
    end_date   = "2025-12-31T23:59:59Z"
  }

  filter {
    tag {
      name = "Environment"
      values = ["Production"]
    }
  }

  notification {
    enabled   = true
    threshold = 80.0
    operator  = "GreaterThan"

    contact_emails = [
      "devops@company.com",
    ]
  }

  notification {
    enabled        = true
    threshold      = 100.0
    operator       = "GreaterThan"
    threshold_type = "Forecasted"

    contact_emails = [
      "finops@company.com",
    ]
  }
}
```

---

## Análisis de costes con Azure CLI

### Costes por servicio (últimos 30 días)

```bash
#!/bin/bash
# Script: analyze-costs.sh

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
START_DATE=$(date -d '30 days ago' +%Y-%m-%d)
END_DATE=$(date +%Y-%m-%d)

echo "Analyzing costs from $START_DATE to $END_DATE"

az consumption usage list \
  --start-date "$START_DATE" \
  --end-date "$END_DATE" \
  --query "[].{Service:consumedService, Cost:pretaxCost, ResourceGroup:instanceName}" \
  --output json | \
  jq -r 'group_by(.Service) | map({Service: .[0].Service, TotalCost: (map(.Cost | tonumber) | add)}) | sort_by(.TotalCost) | reverse | .[] | "\(.Service): $\(.TotalCost | tonumber | floor)"'
```

**Output ejemplo:**

```
Microsoft.Compute: $2,340
Microsoft.Storage: $890
Microsoft.Network: $560
Microsoft.Sql: $450
Microsoft.ContainerService: $320
```

### Top 10 recursos más caros

```bash
az consumption usage list \
  --start-date "$START_DATE" \
  --end-date "$END_DATE" \
  --query "[].{Resource:instanceId, Cost:pretaxCost}" \
  --output json | \
  jq -r 'group_by(.Resource) | map({Resource: .[0].Resource, TotalCost: (map(.Cost | tonumber) | add)}) | sort_by(.TotalCost) | reverse | .[0:10] | .[] | "\(.Resource | split("/")[-1]): $\(.TotalCost | floor)"'
```

---

## Azure Advisor: recomendaciones de ahorro

### Consultar recomendaciones de coste

```bash
# Listar todas las recomendaciones de coste
az advisor recommendation list \
  --category Cost \
  --query "[].{Impact:impact, Description:shortDescription.problem, Savings:extendedProperties.savingsAmount}" \
  --output table
```

**Recomendaciones típicas:**

1. **Right-size VMs**: VMs con CPU < 5% durante 7 días
2. **Delete unattached disks**: Discos huérfanos sin VM asociada
3. **Reserved Instances**: Compra RI para VMs que corren 24/7
4. **Shutdown dev/test VMs**: Apagar VMs no productivas fuera de horario
5. **Move to cheaper tiers**: Storage/SQL en tiers sobredimensionados

### Aplicar recomendaciones automáticamente

```bash
# Obtener VMs infrautilizadas
az advisor recommendation list \
  --category Cost \
  --query "[?contains(shortDescription.problem, 'virtual machine')].{Name:impactedValue, CurrentSKU:extendedProperties.currentSku, TargetSKU:extendedProperties.targetSku}" \
  --output json > underutilized-vms.json

# Resize VMs (con confirmación manual)
cat underutilized-vms.json | jq -r '.[] | "az vm resize --resource-group \(.Name | split("/")[4]) --name \(.Name | split("/")[-1]) --size \(.TargetSKU)"'
```

!!! warning "Confirmación manual"
    **No ejecutes resize automático sin validar**. Verifica que las VMs no tengan picos de carga en horarios específicos que Advisor no detecta.

---

## Monitorización con Azure Monitor

### Crear alerta de coste anómalo

```bash
# Crear action group para notificaciones
az monitor action-group create \
  --name ag-cost-anomaly \
  --resource-group rg-monitoring \
  --short-name cost-alert \
  --email-receiver name=devops email=devops@company.com

# Crear alerta basada en logs de Cost Management
az monitor metrics alert create \
  --name alert-cost-spike \
  --resource-group rg-monitoring \
  --scopes /subscriptions/$SUBSCRIPTION_ID \
  --condition "avg costs > 200" \
  --description "Alerta cuando el coste diario supera $200" \
  --evaluation-frequency 1d \
  --window-size 1d \
  --action ag-cost-anomaly
```

### Dashboard de costes en Workbook

**Template JSON** (importar en Azure Monitor Workbooks):

```json
{
  "version": "Notebook/1.0",
  "items": [
    {
      "type": 3,
      "content": {
        "version": "KqlItem/1.0",
        "query": "AzureActivity\n| where CategoryValue == 'Administrative'\n| where OperationNameValue contains 'Microsoft.Compute'\n| summarize Cost = sum(todouble(Properties.cost)) by bin(TimeGenerated, 1d)\n| render timechart",
        "size": 0,
        "title": "Daily Compute Costs",
        "queryType": 0
      }
    }
  ]
}
```

---

## Buenas prácticas para 2025

### 1. Estrategia de tagging

**Tags obligatorios para facturación:**

```yaml
Environment: Production | Development | Staging
CostCenter: CC-1001 | CC-1002 | CC-1003
Project: ProjectAlpha | ProjectBeta
Owner: team-devops@company.com
```

**Aplicar tags con Azure Policy:**

```bicep
resource tagPolicy 'Microsoft.Authorization/policyDefinitions@2021-06-01' = {
  name: 'require-cost-tags'
  properties: {
    displayName: 'Require cost allocation tags'
    policyType: 'Custom'
    mode: 'Indexed'
    parameters: {}
    policyRule: {
      if: {
        allOf: [
          {field: 'tags[Environment]', exists: 'false'}
          {field: 'tags[CostCenter]', exists: 'false'}
        ]
      }
      then: {
        effect: 'deny'
      }
    }
  }
}
```

### 2. Apagar recursos en horarios no productivos

```bash
# Automation runbook para apagar VMs dev/test
$VMs = Get-AzVM -ResourceGroupName "rg-dev" | Where-Object {$_.Tags["AutoShutdown"] -eq "true"}
foreach ($VM in $VMs) {
    Stop-AzVM -ResourceGroupName $VM.ResourceGroupName -Name $VM.Name -Force
}
```

**Configurar con Azure DevTest Labs:**

- Horario de apagado automático: 19:00-08:00 (lunes-viernes)
- Sin apagado: sábados-domingos (para pruebas largas)
- Ahorro estimado: **~65% en costes de VMs dev**

### 3. Reserved Instances para workloads estables

**Análisis de candidatos:**

```bash
# VMs corriendo 24/7 últimos 30 días
az vm list --query "[].{Name:name, RG:resourceGroup, Size:hardwareProfile.vmSize}" -o json | \
  jq -r '.[] | "\(.Name) (\(.Size))"' | \
  while read vm; do
    uptime=$(az monitor metrics list --resource $vm --metric "Percentage CPU" --start-time $(date -d '30 days ago' +%Y-%m-%dT00:00:00Z) --query "value[0].timeseries[0].data | length")
    if [ $uptime -gt 700 ]; then echo "$vm - Candidate for RI"; fi
  done
```

**ROI de Reserved Instances:**

| Compromiso | Descuento | Break-even |
|------------|-----------|------------|
| 1 año | ~40% | 9 meses de uso |
| 3 años | ~60% | 18 meses de uso |

### 4. Usar Azure Hybrid Benefit

**Si tienes licencias On-Premises:**

```bash
# Activar Azure Hybrid Benefit para VMs Windows
az vm update \
  --resource-group rg-prod \
  --name vm-prod-01 \
  --license-type Windows_Server

# Ahorro: hasta 40% en costes de licencias Windows
```

### 5. Revisar snapshots y backups antiguos

```bash
# Listar snapshots mayores de 90 días
az snapshot list --query "[?timeCreated<'$(date -d '90 days ago' +%Y-%m-%d)'].{Name:name, Created:timeCreated, Size:diskSizeGb}" -o table

# Delete snapshots antiguos (con confirmación)
az snapshot list --query "[?timeCreated<'$(date -d '90 days ago' +%Y-%m-%d)'].id" -o tsv | \
  xargs -I {} az snapshot delete --ids {}
```

---

## Checklist para enero 2025

- [ ] Crear presupuestos mensuales/anuales para cada subscripción
- [ ] Configurar alertas en 50%, 80%, 90%, 100%
- [ ] Aplicar tags obligatorios (Environment, CostCenter, Project, Owner)
- [ ] Revisar recomendaciones de Azure Advisor
- [ ] Analizar costes del Q4 2024 para proyectar 2025
- [ ] Identificar candidatos para Reserved Instances
- [ ] Configurar auto-shutdown para VMs dev/test
- [ ] Limpiar recursos huérfanos (disks, snapshots, NICs)
- [ ] Activar Azure Hybrid Benefit si aplica
- [ ] Documentar baseline de costes enero para comparar mensualmente

---

## Herramientas complementarias

### Azure Cost CLI

```bash
# Instalar
npm install -g azure-cost-cli

# Uso
azure-cost-cli \
  --subscription-id $SUBSCRIPTION_ID \
  --start-date 2025-01-01 \
  --end-date 2025-01-31 \
  --output table
```

### Terraform Cost Estimation

```bash
# Pre-deployment cost analysis
terraform plan -out=plan.tfplan
terraform show -json plan.tfplan | \
  infracost breakdown --path=-
```

### Power BI Dashboard

**Conectar Cost Management a Power BI:**

1. Exportar datos históricos a Storage Account
2. Crear dataflow desde Blob Storage
3. Usar template de Power BI para Cost Analysis

[Descargar template oficial](https://aka.ms/AzureCostManagementPowerBITemplate)

---

## Referencias

- [Azure Cost Management Documentation](https://learn.microsoft.com/azure/cost-management-billing/)
- [Azure Advisor Cost Recommendations](https://learn.microsoft.com/azure/advisor/advisor-cost-recommendations)
- [FinOps Foundation Best Practices](https://www.finops.org/framework/)
- [Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [Reserved Instances Documentation](https://learn.microsoft.com/azure/cost-management-billing/reservations/)
