---
draft: false
date: 2025-02-17
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure SQL
  - Database
  - Performance
---

# Azure SQL Elastic Pools: Optimiza costos con DBs compartidos

## Resumen

Los Elastic Pools te permiten compartir recursos (eDTUs o vCores) entre múltiples bases de datos SQL. Voy al grano: es la solución cuando tienes muchas DBs con picos de uso en diferentes momentos y quieres pagar por el pool en lugar de sobreaprovisionar cada DB individual.

## ¿Qué problema resuelven los Elastic Pools?

**Escenario típico SaaS:**
- Tienes 100 bases de datos (una por cliente)
- Cada cliente usa su DB en momentos diferentes
- Picos máximos: 100 DTUs por DB
- Uso promedio: 10 DTUs por DB

**Sin Elastic Pool:**
- 100 DBs × 100 DTUs = 10,000 DTUs provisionadas
- Costo: ~€7,000/mes
- Utilización real: <20%

**Con Elastic Pool:**
- Pool de 1,000 eDTUs compartidas
- Costo: ~€1,200/mes
- Utilización: 70-80%
- **Ahorro: 83%**

## Crear Elastic Pool

```bash
# Variables
RG="my-rg"
LOCATION="westeurope"
SERVER="my-sql-server"
POOL_NAME="my-elastic-pool"

# Crear SQL Server
az sql server create \
  --resource-group $RG \
  --name $SERVER \
  --location $LOCATION \
  --admin-user sqladmin \
  --admin-password 'P@ssw0rd1234!'

# Crear Elastic Pool (modelo vCore - recomendado)
az sql elastic-pool create \
  --resource-group $RG \
  --server $SERVER \
  --name $POOL_NAME \
  --edition GeneralPurpose \
  --family Gen5 \
  --capacity 4 \
  --db-min-capacity 0 \
  --db-max-capacity 2 \
  --max-size 512GB
```

!!! note "eDTU vs vCore"
    - **DTU model**: Más simple, bundle de CPU+RAM+IO. Ideal para workloads predecibles.
    - **vCore model**: Más flexible, escala CPU y memoria independientemente. Recomendado para nuevos despliegues.

## Añadir bases de datos al pool

```bash
# Crear DB directamente en el pool
az sql db create \
  --resource-group $RG \
  --server $SERVER \
  --name customer-001-db \
  --elastic-pool $POOL_NAME

# Mover DB existente al pool
az sql db update \
  --resource-group $RG \
  --server $SERVER \
  --name existing-db \
  --elastic-pool $POOL_NAME
```

## Configuración óptima de recursos

### Límites por DB (evita noisy neighbor)

```bash
# Establecer mín/máx vCores por DB
az sql elastic-pool update \
  --resource-group $RG \
  --server $SERVER \
  --name $POOL_NAME \
  --db-min-capacity 0.25 \  # Mínimo garantizado
  --db-max-capacity 2        # Máximo permitido (evita monopolizar pool)
```

**Recomendaciones:**
- `db-min-capacity`: 0 para DBs inactivas, 0.25-0.5 para DBs críticas
- `db-max-capacity`: 50-75% del total del pool para evitar que una DB acapare todos los recursos

### Escalado del pool

```bash
# Escalar verticalmente (más vCores)
az sql elastic-pool update \
  --resource-group $RG \
  --server $SERVER \
  --name $POOL_NAME \
  --capacity 8 \
  --max-size 1TB

# Escalar storage independiente
az sql elastic-pool update \
  --resource-group $RG \
  --server $SERVER \
  --name $POOL_NAME \
  --max-size 2TB
```

## Casos de uso ideales

### 1. Aplicaciones SaaS multi-tenant

```
Cliente A: Pico 9am-12pm (50 DTUs)
Cliente B: Pico 2pm-5pm (60 DTUs)
Cliente C: Pico 8pm-11pm (40 DTUs)

Pool necesario: 60 DTUs (máximo pico)
vs
Sin pool: 150 DTUs (50+60+40)
```

### 2. Entornos dev/test

```bash
# Pool compartido para todos los devs
az sql elastic-pool create \
  --resource-group dev-rg \
  --server dev-sql-server \
  --name dev-pool \
  --edition Standard \
  --dtu 100 \
  --db-dtu-min 0 \
  --db-dtu-max 20

# Cada dev tiene su DB
for dev in alice bob charlie; do
  az sql db create \
    --resource-group dev-rg \
    --server dev-sql-server \
    --name ${dev}-dev-db \
    --elastic-pool dev-pool
done
```

### 3. Aplicaciones con variación estacional

- E-commerce: Picos en Black Friday, navidad
- Educación: Picos durante matrículas
- Fiscal: Picos fin de trimestre/año

## Monitoreo de recursos

```bash
# Métricas del pool
az monitor metrics list \
  --resource /subscriptions/{sub-id}/resourceGroups/$RG/providers/Microsoft.Sql/servers/$SERVER/elasticPools/$POOL_NAME \
  --metric "cpu_percent" "dtu_consumption_percent" "storage_percent" \
  --start-time 2025-02-17T00:00:00Z \
  --end-time 2025-02-17T23:59:59Z \
  --interval PT1H

# Top databases consumiendo recursos
az sql elastic-pool list-dbs \
  --resource-group $RG \
  --server $SERVER \
  --name $POOL_NAME \
  --query "[].{Name:name, MaxSize:maxSizeBytes, Status:status}"
```

Query en SQL para ver consumo por DB:

```sql
SELECT 
    DB_NAME(database_id) AS DatabaseName,
    AVG(avg_cpu_percent) AS AvgCPU,
    AVG(avg_data_io_percent) AS AvgDataIO,
    AVG(avg_log_write_percent) AS AvgLogWrite,
    MAX(max_worker_percent) AS MaxWorkers,
    MAX(max_session_percent) AS MaxSessions
FROM sys.dm_db_resource_stats
WHERE end_time > DATEADD(hour, -1, GETUTCDATE())
GROUP BY DB_NAME(database_id)
ORDER BY AvgCPU DESC;
```

## Alertas automáticas

```bash
# Alerta si pool > 80% CPU
az monitor metrics alert create \
  --name elastic-pool-high-cpu \
  --resource-group $RG \
  --scopes /subscriptions/{sub-id}/resourceGroups/$RG/providers/Microsoft.Sql/servers/$SERVER/elasticPools/$POOL_NAME \
  --condition "avg cpu_percent > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action /subscriptions/{sub-id}/resourceGroups/$RG/providers/Microsoft.Insights/actionGroups/dba-team

# Alerta si storage > 90%
az monitor metrics alert create \
  --name elastic-pool-storage-full \
  --resource-group $RG \
  --scopes /subscriptions/{sub-id}/resourceGroups/$RG/providers/Microsoft.Sql/servers/$SERVER/elasticPools/$POOL_NAME \
  --condition "avg storage_percent > 90" \
  --window-size 15m \
  --evaluation-frequency 5m \
  --action /subscriptions/{sub-id}/resourceGroups/$RG/providers/Microsoft.Insights/actionGroups/dba-team
```

## Cuando NO usar Elastic Pools

❌ **Una sola DB grande**: No tiene sentido pool de un solo tenant
❌ **Picos simultáneos**: Si todas las DBs pican a la vez, no ahorras
❌ **Requisitos de aislamiento estricto**: Compliance que requiere dedicación física
❌ **DBs con patrones muy diferentes**: OLTP + DW no mezclan bien

## Estrategia de migración

**Paso 1: Análisis de consumo**

```sql
-- Ejecutar en cada DB durante 7 días
SELECT 
    DATEPART(hour, end_time) AS Hour,
    AVG(avg_cpu_percent) AS AvgCPU,
    MAX(avg_cpu_percent) AS MaxCPU
FROM sys.dm_db_resource_stats
WHERE end_time > DATEADD(day, -7, GETUTCDATE())
GROUP BY DATEPART(hour, end_time)
ORDER BY Hour;
```

**Paso 2: Sizing del pool**

Regla del pulgar:
```
Pool eDTUs = MAX(SUM(avg_dtu_per_db), MAX(concurrent_peak_dtu))

Ejemplo:
20 DBs × 10 DTU promedio = 200 DTU
Pico máximo simultáneo = 150 DTU
→ Pool de 200 eDTUs
```

**Paso 3: Migración gradual**

```bash
# Migrar en ventana de mantenimiento
for db in $(az sql db list --resource-group $RG --server $SERVER --query "[?!elasticPoolName].name" -o tsv); do
  echo "Migrando $db..."
  az sql db update \
    --resource-group $RG \
    --server $SERVER \
    --name $db \
    --elastic-pool $POOL_NAME
done
```

## Buenas prácticas

- **Homogeneidad**: Agrupa DBs con workloads similares (OLTP con OLTP, no con DW)
- **Naming convention**: `pool-{env}-{tier}` (ej: `pool-prod-gp`, `pool-dev-std`)
- **Límites por DB**: Siempre configura `db-max-capacity` para evitar noisy neighbors
- **Monitoring**: Habilita diagnostic logs a Log Analytics
- **Escalado proactivo**: Escala antes de llegar al 80% de utilización
- **Backups**: Los backups se gestionan por DB, no por pool

## Costos (West Europe, Feb 2025)

**vCore model:**
- General Purpose, 4 vCores: ~€550/mes
- Business Critical, 4 vCores: ~€1,700/mes

**DTU model:**
- Standard 100 eDTUs: ~€120/mes
- Premium 125 eDTUs: ~€450/mes

**Storage adicional:** €0.115/GB/mes

!!! tip "Ahorro con Reserved Capacity"
    Reserva 1 o 3 años → hasta 65% descuento en vCores.

## Referencias

- [Elastic pools in Azure SQL Database](https://learn.microsoft.com/en-us/azure/azure-sql/database/elastic-pool-overview)
- [Manage elastic pools - Azure SQL Database](https://learn.microsoft.com/en-us/azure/azure-sql/database/elastic-pool-manage)
- [Resource limits - elastic pools](https://learn.microsoft.com/en-us/azure/azure-sql/database/resource-limits-vcore-elastic-pools)
