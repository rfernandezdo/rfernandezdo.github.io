---
draft: false
date: 2025-06-01
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure Functions
  - Performance
  - Serverless
  - Cost Optimization
---

# Azure Functions: optimización de performance y costes

## Resumen

**Azure Functions** puede ser económico o costoso según cómo configures hosting plan, cold starts, concurrency y connection pooling. En este post verás técnicas prácticas para optimizar performance (reducir latencia, eliminar cold starts) y costes (right-sizing, Flex Consumption).

<!-- more -->

## ¿Por qué optimizar Azure Functions?

**Problemas comunes:**

- **Cold starts**: Primera ejecución tarda 2-5 segundos (crítico en APIs)
- **Throttling**: Límites de concurrency causan HTTP 429
- **Costes inesperados**: Premium plan puede costar más que VMs dedicadas
- **Memory leaks**: Conexiones no cerradas agotan recursos
- **Latency spikes**: Dependency on external services sin timeouts

**Métricas clave a monitorizar:**

| Métrica | Target | Alerta si... |
|---------|--------|--------------|
| **P95 duration** | < 1s | > 3s |
| **Cold start %** | < 5% | > 20% |
| **Throttling rate** | 0% | > 1% |
| **Memory usage** | < 80% | > 90% |
| **Cost per 1M exec** | Variable | Excede budget |

---

## Hosting Plans: elegir el correcto

### Comparison matrix

| Plan | Cold Starts | Scaling | Precio | Mejor para |
|------|-------------|---------|--------|------------|
| **Consumption** | ✅ Sí (hasta 5s) | 0-200 instances | $0.20/1M exec + $0.000016/GB-s | Workloads esporádicos |
| **Flex Consumption** | ✅ Sí (reducido) | 0-1000 instances | $0.18/1M exec | High-scale con budget |
| **Premium (EP1)** | ❌ No (always-on) | Manual 1-100 | ~$150/month base | Latency-sensitive APIs |
| **Dedicated (App Service)** | ❌ No | Manual | Desde $55/month | Apps con tráfico constante |

### Cuándo usar cada plan

**Consumption:**
```bash
# Ideal para:
# - Webhooks (GitHub, Stripe)
# - Scheduled jobs (cada hora/día)
# - Event-driven processing (Storage Queue, Event Grid)

az functionapp create \
  --name func-webhook-processor \
  --resource-group rg-functions \
  --consumption-plan-location westeurope \
  --runtime node \
  --runtime-version 20 \
  --storage-account stfunctions
```

**Premium (eliminar cold starts):**
```bash
# Crear App Service Plan Premium
az functionapp plan create \
  --name plan-premium-ep1 \
  --resource-group rg-functions \
  --location westeurope \
  --sku EP1 \
  --is-linux

# Function app con always-on
az functionapp create \
  --name func-api-prod \
  --resource-group rg-functions \
  --plan plan-premium-ep1 \
  --runtime python \
  --runtime-version 3.11 \
  --storage-account stfunctions \
  --functions-version 4

# Habilitar always-on
az functionapp config set \
  --name func-api-prod \
  --resource-group rg-functions \
  --always-on true
```

**Flex Consumption (new, best balance):**
```bash
# Crear Function con Flex Consumption (preview)
az functionapp create \
  --name func-scalable-api \
  --resource-group rg-functions \
  --flexconsumption-location westeurope \
  --runtime dotnet-isolated \
  --runtime-version 8 \
  --storage-account stfunctions
```

---

## Optimización: eliminar cold starts

### Técnica 1: Application Insights availability tests

```bash
# Crear availability test que "caliente" la función cada 5 minutos
az monitor app-insights web-test create \
  --resource-group rg-monitoring \
  --name warmup-test-api \
  --app-insights app-insights-prod \
  --location westeurope \
  --kind ping \
  --web-test-name warmup-test-api \
  --locations "West Europe" "North Europe" \
  --frequency 300 \
  --timeout 30 \
  --enabled true \
  --url "https://func-api-prod.azurewebsites.net/api/health"
```

**Costo:** ~$5/month por test (más barato que Premium plan)

### Técnica 2: Warmup triggers (Premium/Dedicated)

```csharp
// function.cs - Warmup function para pre-cargar dependencias
[FunctionName("WarmUp")]
public static void Run(
    [WarmUpTrigger] WarmUpContext context,
    ILogger log)
{
    log.LogInformation("Function app is warming up...");
    
    // Pre-cargar conexiones pesadas
    var dbConnection = new SqlConnection(Environment.GetEnvironmentVariable("SqlConnectionString"));
    dbConnection.Open();
    dbConnection.Close();
    
    // Pre-cargar cache
    var redis = ConnectionMultiplexer.Connect(Environment.GetEnvironmentVariable("RedisConnection"));
    redis.GetDatabase().Ping();
}
```

### Técnica 3: Pre-warmed instances (Premium)

```bash
# Configurar mínimo de instancias pre-calentadas
az functionapp plan update \
  --name plan-premium-ep1 \
  --resource-group rg-functions \
  --min-instances 2 \
  --max-burst 20
```

**Trade-off:** Pagar por 2 instancias 24/7 (~$300/month) vs cold starts

---

## Optimización: Concurrency y scaling

### Configurar max concurrency por instancia

```json
// host.json - Configuración óptima
{
  "version": "2.0",
  "extensions": {
    "http": {
      "maxConcurrentRequests": 100,
      "maxOutstandingRequests": 200,
      "routePrefix": "api"
    },
    "serviceBus": {
      "maxConcurrentCalls": 16,
      "prefetchCount": 0
    },
    "queues": {
      "batchSize": 32,
      "maxDequeueCount": 5,
      "newBatchThreshold": 8
    }
  },
  "functionTimeout": "00:05:00",
  "logging": {
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true,
        "maxTelemetryItemsPerSecond": 20
      }
    }
  }
}
```

**Explicación parámetros:**

- `maxConcurrentRequests: 100`: Cada instancia maneja 100 requests simultáneos
- `newBatchThreshold: 8`: Trigger nueva instancia cuando quedan 8 mensajes sin procesar
- `maxTelemetryItemsPerSecond: 20`: Reducir costes App Insights (sampling)

### Durable Functions para workflows largos

```csharp
// Orchestrator pattern para workflow > 5 minutos
[FunctionName("ProcessOrderOrchestrator")]
public static async Task<object> RunOrchestrator(
    [OrchestrationTrigger] IDurableOrchestrationContext context)
{
    var orderId = context.GetInput<string>();
    
    // Step 1: Validate order (30s)
    var isValid = await context.CallActivityAsync<bool>("ValidateOrder", orderId);
    if (!isValid) return "Order invalid";
    
    // Step 2: Process payment (puede tardar minutos si hay retry)
    var paymentResult = await context.CallActivityAsync<string>("ProcessPayment", orderId);
    
    // Step 3: Ship order (activity que llama API externa)
    await context.CallActivityAsync("ShipOrder", orderId);
    
    return "Order completed";
}

[FunctionName("ValidateOrder")]
public static bool ValidateOrder([ActivityTrigger] string orderId, ILogger log)
{
    // Lógica de validación rápida
    return orderId.Length > 0;
}
```

**Ventaja:** Orchestrator no consume execution time mientras espera activities

---

## Optimización: Connection pooling

### ❌ Anti-pattern: Crear conexión por ejecución

```python
# BAD: Connection leak
import azure.functions as func
import pyodbc

def main(req: func.HttpRequest) -> func.HttpResponse:
    # ❌ Nueva conexión cada invocación
    conn = pyodbc.connect(
        'DRIVER={ODBC Driver 18 for SQL Server};'
        'SERVER=myserver.database.windows.net;'
        'DATABASE=mydb;'
        'UID=user;PWD=pass'
    )
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM Products")
    results = cursor.fetchall()
    # ❌ Conexión no cerrada explícitamente
    return func.HttpResponse(str(results))
```

**Problema:** Después de 100 ejecuciones, agotas connections disponibles → `SqlException: Timeout expired`

### ✅ Pattern correcto: Connection reuse

```python
# GOOD: Singleton connection
import azure.functions as func
import pyodbc
import os

# Global connection pool (reutilizada entre invocaciones)
_connection_pool = None

def get_connection():
    global _connection_pool
    if _connection_pool is None:
        _connection_pool = pyodbc.connect(
            os.environ["SqlConnectionString"],
            autocommit=True
        )
    return _connection_pool

def main(req: func.HttpRequest) -> func.HttpResponse:
    conn = get_connection()
    cursor = conn.cursor()
    try:
        cursor.execute("SELECT * FROM Products")
        results = cursor.fetchall()
        return func.HttpResponse(str(results))
    finally:
        cursor.close()  # Cerrar cursor, NO conexión
```

### Entity Framework Core con pooling

```csharp
// Startup.cs
public class Startup : FunctionsStartup
{
    public override void Configure(IFunctionsHostBuilder builder)
    {
        var connectionString = Environment.GetEnvironmentVariable("SqlConnectionString");
        
        // DbContext con pooling
        builder.Services.AddDbContextPool<MyDbContext>(options =>
            options.UseSqlServer(connectionString, sqlOptions =>
            {
                sqlOptions.EnableRetryOnFailure(
                    maxRetryCount: 3,
                    maxRetryDelay: TimeSpan.FromSeconds(5),
                    errorNumbersToAdd: null);
            }));
        
        // HTTP client con SocketsHttpHandler
        builder.Services.AddHttpClient("external-api", client =>
        {
            client.BaseAddress = new Uri("https://api.external.com");
            client.Timeout = TimeSpan.FromSeconds(10);
        })
        .ConfigurePrimaryHttpMessageHandler(() => new SocketsHttpHandler
        {
            PooledConnectionLifetime = TimeSpan.FromMinutes(15),
            MaxConnectionsPerServer = 50
        });
    }
}
```

---

## Optimización: Memory y CPU

### Profiling con Application Insights

```bash
# Ver top funciones por memory usage
az monitor app-insights query \
  --app app-insights-prod \
  --analytics-query "
    requests
    | where timestamp > ago(1h)
    | join kind=inner (performanceCounters | where name == 'Private Bytes') on operation_Id
    | summarize AvgMemoryMB = avg(value/1024/1024) by operation_Name
    | order by AvgMemoryMB desc
    | take 10
  " \
  --offset 1h
```

### Configurar memory limits

```bash
# Limitar memory por function (evita OOM)
az functionapp config appsettings set \
  --name func-api-prod \
  --resource-group rg-functions \
  --settings "WEBSITE_MEMORY_LIMIT_MB=512"
```

### Right-sizing con monitoring

```kusto
// Query Application Insights
performanceCounters
| where timestamp > ago(7d)
| where name == "% Processor Time" or name == "Available Bytes"
| summarize 
    AvgCPU = avgif(value, name == "% Processor Time"),
    AvgMemoryMB = avgif(value/1024/1024, name == "Available Bytes"),
    P95CPU = percentile(value, 95)
| project AvgCPU, P95CPU, AvgMemoryMB
```

**Decisión:**

- CPU < 30% y Memory < 50% → Reducir SKU (EP1 → Consumption)
- CPU > 80% → Aumentar `maxConcurrentRequests` o scale out
- Memory > 90% → Memory leak (revisar código)

---

## Optimización: Costes

### Análisis de costes por función

```bash
# Cost analysis con Azure CLI
az consumption usage list \
  --start-date 2025-05-01 \
  --end-date 2025-05-31 \
  --query "[?contains(instanceName, 'func-api-prod')].{Function:instanceName, Cost:pretaxCost}" \
  --output table
```

### Técnicas de reducción

**1. Reducir telemetry sampling**

```json
// host.json
{
  "logging": {
    "applicationInsights": {
      "samplingSettings": {
        "isEnabled": true,
        "maxTelemetryItemsPerSecond": 5,  // Reducir de 20 a 5
        "excludedTypes": "Request;Exception"  // No samplear requests/exceptions
      }
    }
  }
}
```

**Ahorro:** ~40% en costes App Insights

**2. Usar Blob/Table Storage en vez de CosmosDB**

```python
# CARO: CosmosDB para datos simples
from azure.cosmos import CosmosClient
client = CosmosClient(url, key)
database = client.get_database_client("mydb")
container = database.get_container_client("logs")
container.create_item({"id": "123", "message": "log entry"})  # $0.03 per 100k writes

# BARATO: Table Storage para logs no críticos
from azure.data.tables import TableServiceClient
service = TableServiceClient.from_connection_string(conn_str)
table = service.get_table_client("logs")
table.create_entity({"PartitionKey": "2025", "RowKey": "123", "message": "log"})  # $0.10 per 1M writes
```

**Ahorro:** 99% en storage costs

**3. Batch processing con Queue triggers**

```csharp
// Procesar mensajes en batch (reduce executions)
[FunctionName("ProcessOrdersBatch")]
public static void Run(
    [QueueTrigger("orders", Connection = "StorageConnection")] string[] messages,
    ILogger log)
{
    // Procesar hasta 32 mensajes juntos (configurado en host.json batchSize: 32)
    foreach (var message in messages)
    {
        // Process each order
    }
}
```

**Ahorro:** 96% menos executions (procesar 32 vs 1 a la vez)

---

## Monitoring y alertas

### Dashboards críticos

```bash
# Crear dashboard de performance
az portal dashboard create \
  --resource-group rg-monitoring \
  --name dashboard-functions-performance \
  --input-path dashboard-functions.json
```

**dashboard-functions.json:**

```json
{
  "lenses": {
    "0": {
      "parts": {
        "0": {
          "metadata": {
            "type": "Extension/AppInsightsExtension/PartType/AnalyticsLineChartPart",
            "query": "requests | where timestamp > ago(1h) | summarize avg(duration) by bin(timestamp, 5m) | render timechart"
          }
        }
      }
    }
  }
}
```

### Alertas automáticas

```bash
# Alerta: Cold start rate > 20%
az monitor metrics alert create \
  --name alert-high-cold-starts \
  --resource-group rg-functions \
  --scopes /subscriptions/$SUB_ID/resourceGroups/rg-functions/providers/Microsoft.Web/sites/func-api-prod \
  --condition "avg coldstarts > 20" \
  --description "Cold starts exceeding threshold" \
  --evaluation-frequency 5m \
  --window-size 15m \
  --action ag-functions-alerts

# Alerta: P95 duration > 3s
az monitor metrics alert create \
  --name alert-high-latency \
  --resource-group rg-functions \
  --scopes /subscriptions/$SUB_ID/resourceGroups/rg-functions/providers/Microsoft.Web/sites/func-api-prod \
  --condition "percentile(duration, 95) > 3000" \
  --evaluation-frequency 5m \
  --action ag-functions-alerts
```

---

## Buenas prácticas checklist

### Performance
- [ ] Usar Premium/Dedicated si latency < 1s es crítico
- [ ] Configurar `maxConcurrentRequests` según CPU disponible
- [ ] Connection pooling para DB/HTTP clients
- [ ] Implementar circuit breaker para dependencias externas
- [ ] Usar Durable Functions para workflows > 5 min
- [ ] Habilitar always-on o warmup triggers
- [ ] Async/await en todas las operaciones I/O

### Costes
- [ ] Empezar con Consumption, migrar a Premium solo si necesario
- [ ] Monitoring con Application Insights sampling configurado
- [ ] Batch processing para Queue/Service Bus triggers
- [ ] Usar Table Storage para logs no críticos
- [ ] Reserved Instances si Premium plan 24/7
- [ ] Revisar costes semanalmente con Cost Analysis

### Reliability
- [ ] Timeouts configurados en `host.json`
- [ ] Retry policies con exponential backoff
- [ ] Dead-letter queues para mensajes fallidos
- [ ] Health check endpoint (`/api/health`)
- [ ] Alertas en P95 duration, throttling, failures
- [ ] Disaster recovery con multi-region deployment

---

## Troubleshooting común

### Problema: Throttling (HTTP 429)

**Síntoma:** `System.Private.CoreLib: Exception while executing function: Functions.ProcessOrder. Microsoft.Azure.WebJobs.Host: Exceeded maximum function execution count`

**Solución:**

```bash
# Aumentar max instances
az functionapp config set \
  --name func-api-prod \
  --resource-group rg-functions \
  --max-instances 100

# Verificar plan tiene capacidad
az functionapp plan show \
  --name plan-premium-ep1 \
  --resource-group rg-functions \
  --query "maximumElasticWorkerCount"
```

### Problema: Memory leaks

**Síntoma:** Performance degrada con tiempo, requiere restart

**Debug:**

```bash
# Memory profiling con dotnet-dump
az webapp create-remote-connection --resource-group rg-functions --name func-api-prod
dotnet-dump collect -p <PID>
dotnet-dump analyze <dump-file>
dumpheap -stat
```

**Fix típico:** Cerrar conexiones, dispose objetos IDisposable

---

## Herramientas útiles

- **Azure Functions Core Tools**: Local debugging con `func start`
- **Azure Load Testing**: Stress test pre-producción
- **Application Insights Profiler**: Identificar bottlenecks
- **Durable Functions Monitor**: UI para visualizar orchestrations
- **Azure Functions University**: Tutoriales community-driven

---

## Referencias

- [Azure Functions Best Practices](https://learn.microsoft.com/azure/azure-functions/functions-best-practices)
- [Performance and Scale](https://learn.microsoft.com/azure/azure-functions/functions-scale)
- [Durable Functions Patterns](https://learn.microsoft.com/azure/azure-functions/durable/durable-functions-overview)
- [Pricing Calculator](https://azure.microsoft.com/pricing/details/functions/)
