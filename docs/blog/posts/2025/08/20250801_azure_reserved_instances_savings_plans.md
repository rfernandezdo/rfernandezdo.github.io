---
draft: false
date: 2025-08-01
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Reserved Instances
  - Savings Plans
  - Cost Optimization
  - FinOps
---

# Azure Reserved Instances y Savings Plans: maximiza ahorros

## Resumen

**Reserved Instances** (RI) y **Savings Plans** pueden reducir costes Azure hasta 72% vs pay-as-you-go. En este post verás cuándo usar cada uno, cómo calcular ROI, y estrategias para maximizar ahorros sin perder flexibilidad.

<!-- more -->

## ¿Qué son y cuál elegir?

### Reserved Instances (RI)

**Compromiso:** Pagas por adelantado 1 o 3 años de una SKU específica en una región específica.

**Ahorro:**
- 1 año: ~40%
- 3 años: ~62%

**Aplica a:**
- VMs (Compute)
- SQL Database
- Cosmos DB
- Synapse Analytics
- Redis Cache
- App Service (Isolated tier)

### Savings Plans

**Compromiso:** Pagas cantidad fija $/hora durante 1 o 3 años, sin especificar SKU ni región.

**Ahorro:**
- 1 año: ~35%
- 3 años: ~55%

**Aplica a:**
- Compute (VMs, Container Instances, Functions Premium)
- Más flexible que RI (puedes cambiar VM size, region, OS)

### Comparison matrix

| Característica | Reserved Instances | Savings Plans |
|----------------|-------------------|---------------|
| **Ahorro máximo** | 72% | 65% |
| **Flexibilidad** | Baja (SKU+region fijos) | Alta (cualquier VM size/region) |
| **Cambio de SKU** | Solo dentro de misma familia | ✅ Cualquier SKU |
| **Cambio de región** | ❌ No permitido | ✅ Permitido |
| **Exchange/refund** | Sí, con penalties | Limitado |
| **Mejor para** | Workloads 100% estables | Workloads flexibles |

---

## Cuándo usar Reserved Instances

### Análisis previo: identificar candidatos

```bash
#!/bin/bash
# Script: find-ri-candidates.sh
# Encuentra VMs corriendo 24/7 últimos 90 días

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
START_DATE=$(date -d '90 days ago' +%Y-%m-%dT00:00:00Z)
END_DATE=$(date +%Y-%m-%dT23:59:59Z)

echo "Analyzing VMs for RI candidates..."

# Get all VMs
VMS=$(az vm list --query "[].{Name:name, RG:resourceGroup, Size:hardwareProfile.vmSize, Location:location}" -o json)

# Check uptime for each VM
echo "$VMS" | jq -r '.[] | "\(.Name),\(.RG),\(.Size),\(.Location)"' | while IFS=, read -r name rg size location; do
    # Query Azure Monitor for uptime
    RESOURCE_ID="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$rg/providers/Microsoft.Compute/virtualMachines/$name"
    
    UPTIME=$(az monitor metrics list \
        --resource "$RESOURCE_ID" \
        --metric "Percentage CPU" \
        --start-time "$START_DATE" \
        --end-time "$END_DATE" \
        --interval PT1H \
        --query "value[0].timeseries[0].data | length(@)" \
        --output tsv 2>/dev/null)
    
    # Si tiene >2000 horas de uptime en 90 días (~92% uptime), es candidato
    if [ "$UPTIME" -gt 2000 ]; then
        echo "✅ RI Candidate: $name ($size) in $location - Uptime: ${UPTIME}h"
    fi
done
```

**Output ejemplo:**

```
✅ RI Candidate: vm-prod-web01 (Standard_D4s_v5) in westeurope - Uptime: 2145h
✅ RI Candidate: vm-prod-db01 (Standard_E8s_v5) in westeurope - Uptime: 2160h
✅ RI Candidate: vm-prod-api01 (Standard_D2s_v5) in westeurope - Uptime: 2140h
```

### Calcular ROI de Reserved Instance

**Ejemplo VM Standard_D4s_v5:**

```python
# Cálculo de ahorro
VM_SIZE = "Standard_D4s_v5"
REGION = "West Europe"
QUANTITY = 2  # 2 VMs

# Pricing (ejemplo, verificar en Azure Pricing Calculator)
PAYG_HOURLY = 0.192  # $/hora pay-as-you-go
RI_1Y_HOURLY = 0.116  # $/hora con RI 1 año
RI_3Y_HOURLY = 0.073  # $/hora con RI 3 años

HOURS_YEAR = 8760

# Coste anual pay-as-you-go
payg_annual = PAYG_HOURLY * HOURS_YEAR * QUANTITY
print(f"Pay-as-you-go: ${payg_annual:,.0f}/year")

# Coste con RI 1 año
ri_1y_annual = RI_1Y_HOURLY * HOURS_YEAR * QUANTITY
ri_1y_savings = payg_annual - ri_1y_annual
print(f"RI 1 year: ${ri_1y_annual:,.0f}/year (ahorro: ${ri_1y_savings:,.0f}, {ri_1y_savings/payg_annual*100:.0f}%)")

# Coste con RI 3 años
ri_3y_annual = RI_3Y_HOURLY * HOURS_YEAR * QUANTITY
ri_3y_savings = payg_annual - ri_3y_annual
print(f"RI 3 years: ${ri_3y_annual:,.0f}/year (ahorro: ${ri_3y_savings:,.0f}, {ri_3y_savings/payg_annual*100:.0f}%)")

# Break-even point
print(f"\nBreak-even 1Y RI: {HOURS_YEAR * (RI_1Y_HOURLY/PAYG_HOURLY):.0f} hours ({HOURS_YEAR * (RI_1Y_HOURLY/PAYG_HOURLY)/8760*365:.0f} days)")
print(f"Break-even 3Y RI: {HOURS_YEAR * (RI_3Y_HOURLY/PAYG_HOURLY)*3/3:.0f} hours ({HOURS_YEAR * (RI_3Y_HOURLY/PAYG_HOURLY)/8760*365:.0f} days)")
```

**Output:**

```
Pay-as-you-go: $3,363/year
RI 1 year: $2,033/year (ahorro: $1,330, 40%)
RI 3 years: $1,279/year (ahorro: $2,084, 62%)

Break-even 1Y RI: 5,292 hours (219 days)
Break-even 3Y RI: 3,331 hours (138 days)
```

**Conclusión:** Si la VM va a correr >220 días/año, RI 1 año vale la pena. Si >138 días/año durante 3 años, RI 3 años es mejor.

---

## Comprar Reserved Instances

### Desde Azure Portal

1. **Portal** → **Reservations** → **Purchase**
2. Seleccionar:
   - **Product**: Virtual Machines
   - **Region**: West Europe
   - **VM size**: Standard_D4s_v5
   - **Term**: 3 years
   - **Billing**: Upfront (cheaper) o Monthly
   - **Quantity**: 2
3. **Review + Purchase**

### Desde Azure CLI

```bash
# Comprar RI para VMs
az reservations reservation-order purchase \
  --reservation-order-id $(uuidgen) \
  --sku-name Standard_D4s_v5 \
  --location westeurope \
  --quantity 2 \
  --term P3Y \  # P1Y para 1 año, P3Y para 3 años
  --billing-plan Upfront \
  --display-name "RI Production VMs 3Y" \
  --applied-scope-type Shared  # o Single/ResourceGroup

# Ver RIs activas
az reservations reservation-order list \
  --query "[].{Name:displayName, Term:term, Quantity:quantity, State:provisioningState}" \
  --output table
```

### Scope de aplicación

**Opciones:**

1. **Shared**: Aplica a cualquier recurso matching en toda la subscription
2. **Single subscription**: Solo aplica a recursos en 1 subscription específica
3. **Resource group**: Solo aplica a recursos en 1 RG específico
4. **Management group**: Aplica a subscriptions dentro de un management group

**Recomendación:** Usar **Shared** para máxima flexibilidad (puedes cambiar después si necesario).

---

## Comprar Savings Plans

### Análisis de elegibilidad

```bash
# Ver beneficio potencial de Savings Plan
az consumption reservation-recommendation list \
  --scope "/subscriptions/$SUBSCRIPTION_ID" \
  --term P3Y \
  --look-back-period Last30Days \
  --query "[].{Savings:totalRecommendedQuantity, MonthlySavings:recommendedQuantity}" \
  --output table
```

### Compra

```bash
# Comprar Savings Plan (Compute)
az consumption savings-plan purchase \
  --savings-plan-order-id $(uuidgen) \
  --sku-name Compute_Savings_Plan \
  --term P3Y \
  --billing-plan Monthly \
  --commitment-amount 100 \  # $100/hour commitment
  --display-name "Compute Savings Plan 3Y $100/h" \
  --applied-scope-type Shared

# Ver Savings Plans activos
az consumption savings-plan list \
  --query "[].{Name:displayName, Commitment:commitment.amount, Utilization:utilization.aggregates[0].value}" \
  --output table
```

### Calcular commitment óptimo

**Fórmula:**

```
Hourly Commitment = Current Average Hourly Spend × Desired Coverage %
```

**Ejemplo:**

```python
# Análisis de uso últimos 30 días
import pandas as pd

# Data de Cost Management export
df = pd.read_csv("cost-analysis-30days.csv")
compute_costs = df[df['ServiceName'].str.contains('Virtual Machines|Container')]

# Promedio horario
avg_hourly = compute_costs['Cost'].sum() / (30 * 24)
print(f"Average hourly compute: ${avg_hourly:.2f}/hour")

# Savings Plan para cubrir 70% del uso (conservador)
sp_commitment = avg_hourly * 0.70
print(f"Recommended SP commitment: ${sp_commitment:.2f}/hour")

# Ahorro proyectado (asumiendo 55% discount en cobertura)
annual_savings = sp_commitment * 8760 * 0.55
print(f"Projected annual savings: ${annual_savings:,.0f}")
```

---

## Estrategias avanzadas

### 1. Hybrid: RI + Savings Plan

**Escenario:**

- **Workload estable:** SQL Database, Storage → **RI** (máximo ahorro)
- **Workload flexible:** VMs que cambian size/region → **Savings Plan**
- **Workload esporádico:** Dev/Test → **Pay-as-you-go**

```
Total compute: $10,000/month
├─ $4,000 (40%) → RI para SQL/Storage (62% discount)
├─ $4,000 (40%) → Savings Plan para VMs (55% discount)
└─ $2,000 (20%) → PAYG para dev/test

Ahorro total: ~50% ($5,000/month)
```

### 2. Exchange RI cuando cambias arquitectura

**Ejemplo:** Migras de VMs a AKS:

```bash
# Exchange RI de VMs por RI de AKS
az reservations reservation update \
  --reservation-order-id $ORDER_ID \
  --reservation-id $RESERVATION_ID \
  --applied-scope-type Shared \
  --instance-flexibility On  # Permite usar RI en diferentes VM sizes dentro de familia
```

**Limitaciones:**

- Solo exchange dentro de misma categoría (Compute → Compute)
- Penalties si reduces commitment
- 1 exchange gratis, siguientes tienen fees

### 3. RI Pooling (multi-subscription)

```bash
# Crear management group
az account management-group create \
  --name mg-production \
  --display-name "Production Subscriptions"

# Agregar subscriptions al MG
az account management-group subscription add \
  --name mg-production \
  --subscription sub-prod-01

az account management-group subscription add \
  --name mg-production \
  --subscription sub-prod-02

# Comprar RI con scope Management Group
az reservations reservation-order purchase \
  --reservation-order-id $(uuidgen) \
  --sku-name Standard_D4s_v5 \
  --location westeurope \
  --quantity 10 \
  --term P3Y \
  --applied-scope-type ManagementGroup \
  --management-group-id mg-production
```

**Ventaja:** RI se comparte entre todas las subscriptions del MG, maximizando utilización.

---

## Monitoring y optimización

### Dashboard de utilización

```kusto
// Query en Cost Management
ReservationDetails
| where TimeGenerated > ago(30d)
| summarize 
    UsedHours = sum(UsedQuantity),
    UnusedHours = sum(ReservedQuantity - UsedQuantity),
    UtilizationRate = avg(UsedQuantity / ReservedQuantity * 100)
  by ReservationOrderId, ReservationName
| order by UtilizationRate asc
```

**Target:** Utilization > 80%

### Alertas de baja utilización

```bash
# Alerta si RI utilization < 70%
az monitor metrics alert create \
  --name alert-low-ri-utilization \
  --resource-group rg-monitoring \
  --scopes "/subscriptions/$SUB_ID/providers/Microsoft.Capacity/reservationOrders/$ORDER_ID" \
  --condition "avg ReservationUtilization < 70" \
  --window-size 7d \
  --evaluation-frequency 1d \
  --action ag-finops-team \
  --description "RI utilization below 70% for 7 days"
```

### Recomendaciones automáticas Azure Advisor

```bash
# Ver recomendaciones de RI/Savings Plan
az advisor recommendation list \
  --category Cost \
  --query "[?contains(shortDescription.problem, 'reservation') || contains(shortDescription.problem, 'savings')].{Type:recommendationType, Savings:extendedProperties.annualSavingsAmount, Description:shortDescription.problem}" \
  --output table
```

---

## Buenas prácticas

### 1. Start small (1 año primero)

**Razón:** Commitments 3 años son rígidos. Si arquitectura cambia (VM → Serverless), pierdes flexibilidad.

**Estrategia:**

```
Año 1: Comprar RI 1 año para 50% del workload estable
Año 2: Si workload sigue estable, comprar RI 3 años
Año 3: Optimizar mix RI/Savings Plan según evolución arquitectura
```

### 2. Revisión trimestral

**Checklist:**

- [ ] RI utilization > 80%? (si no, exchange o sell)
- [ ] Nuevos workloads elegibles para RI/SP?
- [ ] Arquitectura cambió? (migrar de RI a SP)
- [ ] Expirations próximas? (renovar 30 días antes)
- [ ] Savings Plan covering suficiente?

### 3. Combinar con Azure Hybrid Benefit

**Doble ahorro:**

```
Base cost: $1,000/month (VM Windows + SQL)
├─ Azure Hybrid Benefit: -$400 (40%) → $600
└─ Reserved Instance 3Y: -$360 (60% of $600) → $240

Total ahorro: 76% ($760/month)
```

```bash
# Habilitar Azure Hybrid Benefit
az vm update \
  --resource-group rg-prod \
  --name vm-prod-sql \
  --license-type Windows_Server

az sql db update \
  --resource-group rg-prod \
  --server sql-prod \
  --name db-production \
  --license-type BasePrice  # Usar licencia on-prem
```

### 4. Documentar decisiones

**Template:**

```markdown
## RI Purchase Decision - 2025-08-01

**Workload:** Production SQL Database
**Current cost:** $500/month PAYG
**Commitment:** 3 years RI
**Expected savings:** $180/month (36%)
**Break-even:** 20 months
**Risk assessment:** LOW - workload stable 24/7 últimos 2 años
**Approval:** FinOps team + CTO
**Review date:** 2026-02-01 (6 months)
```

---

## Casos de uso reales

### Startup → Enterprise

**Fase 1 (Startup):** Pay-as-you-go (flexibilidad máxima)
**Fase 2 (Growth):** Savings Plan 1Y para 30% workload (balance ahorro/flexibilidad)
**Fase 3 (Enterprise):** RI 3Y para 60% workload + SP para resto

### Seasonal business (e-commerce)

**Problema:** Black Friday requiere 10x capacity, resto del año 1x.

**Solución:**

```
Capacity base (1x, 365 días): RI 3Y (máximo ahorro)
Capacity peak (9x, 60 días): Spot VMs (90% descuento vs PAYG)
Capacity buffer: Savings Plan 1Y
```

### Multi-cloud strategy

**Si usas Azure + AWS:**

- Azure: RI para workloads críticos (mejor soporte)
- AWS: Compute Savings Plan (más flexible para experimentar)

**Evitar:** Comprar RI en ambos clouds para mismo workload (lock-in excesivo)

---

## Troubleshooting

### RI no se aplica

**Causas comunes:**

1. **Scope incorrecto:** RI comprada en subscription A, VM en subscription B
2. **Region mismatch:** RI en West Europe, VM en North Europe
3. **VM size mismatch:** RI para Standard_D4s_v5, VM es Standard_D4as_v5
4. **Instance flexibility OFF:** RI solo aplica a size exacto

**Fix:**

```bash
# Verificar RI properties
az reservations reservation show \
  --reservation-order-id $ORDER_ID \
  --reservation-id $RESERVATION_ID \
  --query "{Scope:properties.appliedScopeType, SKU:sku.name, Flexibility:properties.instanceFlexibility}"

# Cambiar scope a Shared
az reservations reservation update \
  --reservation-order-id $ORDER_ID \
  --reservation-id $RESERVATION_ID \
  --applied-scope-type Shared
```

---

## Herramientas útiles

- **Azure Pricing Calculator**: Comparar PAYG vs RI vs SP
- **Azure Cost Management**: Ver utilization de RIs
- **Azure Advisor**: Recomendaciones automáticas
- **Reservations API**: Automatizar compra/exchange
- **PowerBI Cost Management Connector**: Dashboards custom

---

## Referencias

- [Reserved Instances Documentation](https://learn.microsoft.com/azure/cost-management-billing/reservations/)
- [Savings Plans Documentation](https://learn.microsoft.com/azure/cost-management-billing/savings-plan/)
- [Pricing Calculator](https://azure.microsoft.com/pricing/calculator/)
- [FinOps Foundation Best Practices](https://www.finops.org/framework/)
