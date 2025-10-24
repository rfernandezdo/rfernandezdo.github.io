---
draft: false
date: 2025-04-07
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure Service Bus
  - Messaging
  - Queues
  - Topics
---

# Azure Service Bus: Mensajería confiable entre servicios

## Resumen

Service Bus es el servicio de mensajería enterprise de Azure. Queues para comunicación punto a punto, Topics para pub/sub. Voy al grano: setup completo con dead-letter queues y sessions.

## ¿Qué es Azure Service Bus?

Service Bus es un message broker managed para desacoplar aplicaciones. Garantiza entrega de mensajes con:

- **At-least-once delivery**: El mensaje llega mínimo 1 vez
- **FIFO ordering**: Con sessions
- **Transactions**: Operaciones atómicas
- **Dead-letter queues**: Manejo de mensajes problemáticos

**Casos de uso:**
- Desacoplar microservicios
- Order processing (ecommerce)
- Event-driven architectures
- Integration with on-premises systems

## Crear namespace y queue

```bash
# Variables
RG="messaging-rg"
LOCATION="westeurope"
NAMESPACE="sb-prod-$(date +%s)"
QUEUE_NAME="orders"

# Crear resource group
az group create \
  --name $RG \
  --location $LOCATION

# Crear Service Bus namespace (Standard tier)
az servicebus namespace create \
  --name $NAMESPACE \
  --resource-group $RG \
  --location $LOCATION \
  --sku Standard

# Crear queue con dead-lettering
az servicebus queue create \
  --name $QUEUE_NAME \
  --namespace-name $NAMESPACE \
  --resource-group $RG \
  --enable-dead-lettering-on-message-expiration true \
  --default-message-time-to-live PT1H \
  --max-delivery-count 10
```

**SKUs disponibles:**
- **Basic**: €0.05/million ops - Sin topics, sessions ni transactions
- **Standard**: €10/mes + ops - Topics, sessions, auto-forward
- **Premium**: €550/mes - Recursos dedicados, VNet integration

## Queues vs Topics

### Queues (punto a punto)

```
Sender → [Queue] → Receiver (solo 1)
```

- Un solo consumer procesa cada mensaje
- FIFO si usas sessions
- Ideal para task queues

```bash
# Crear queue simple
az servicebus queue create \
  --name tasks \
  --namespace-name $NAMESPACE \
  --resource-group $RG
```

### Topics (pub/sub)

```
Sender → [Topic] → Subscription 1 → Receiver A
                 → Subscription 2 → Receiver B
                 → Subscription 3 → Receiver C
```

- Múltiples subscriptions
- Cada subscription recibe copia del mensaje
- Filters para routing

```bash
# Crear topic
az servicebus topic create \
  --name events \
  --namespace-name $NAMESPACE \
  --resource-group $RG

# Crear subscriptions con filtros
az servicebus topic subscription create \
  --name mobile-orders \
  --namespace-name $NAMESPACE \
  --topic-name events \
  --resource-group $RG \
  --enable-session true

az servicebus topic subscription create \
  --name web-orders \
  --namespace-name $NAMESPACE \
  --topic-name events \
  --resource-group $RG
```

## Dead-Letter Queue (DLQ)

Mensajes van al DLQ cuando:
- **TTL expira** (Time-to-Live)
- **MaxDeliveryCount excedido** (defecto 10 reintentos)
- **Filtros no coinciden**
- **Aplicación marca mensaje como dead-letter**

```bash
# Habilitar DLQ en queue existente
az servicebus queue update \
  --name $QUEUE_NAME \
  --namespace-name $NAMESPACE \
  --resource-group $RG \
  --enable-dead-lettering-on-message-expiration true

# DLQ para subscription
az servicebus topic subscription update \
  --name mobile-orders \
  --namespace-name $NAMESPACE \
  --topic-name events \
  --resource-group $RG \
  --enable-dead-lettering-on-message-expiration true
```

### Procesar mensajes del DLQ

Path del DLQ:
```
Queue: myqueue/$deadletterqueue
Topic: mytopic/subscriptions/mysub/$deadletterqueue
```

Código C# para leer DLQ:

```csharp
using Azure.Messaging.ServiceBus;

string connectionString = "<connection-string>";
string queueName = "orders";

await using var client = new ServiceBusClient(connectionString);
var receiver = client.CreateReceiver(queueName, new ServiceBusReceiverOptions
{
    SubQueue = SubQueue.DeadLetter
});

var messages = await receiver.ReceiveMessagesAsync(maxMessages: 10);
foreach (var msg in messages)
{
    Console.WriteLine($"DLQ Reason: {msg.DeadLetterReason}");
    Console.WriteLine($"DLQ Description: {msg.DeadLetterErrorDescription}");
    Console.WriteLine($"Body: {msg.Body}");
    
    // Procesar y completar
    await receiver.CompleteMessageAsync(msg);
}
```

## Message Sessions (FIFO)

Sessions garantizan orden FIFO para mensajes relacionados:

```bash
# Crear queue con sessions
az servicebus queue create \
  --name ordered-tasks \
  --namespace-name $NAMESPACE \
  --resource-group $RG \
  --enable-session true
```

Código C# con sessions:

```csharp
// Enviar mensajes con SessionId
var sender = client.CreateSender("ordered-tasks");
await sender.SendMessageAsync(new ServiceBusMessage("Order 1")
{
    SessionId = "session-customer-123"
});

// Recibir por session
var sessionReceiver = await client.AcceptNextSessionAsync("ordered-tasks");
var messages = await sessionReceiver.ReceiveMessagesAsync(10);
```

## Auto-forwarding

Encadena queues/topics automáticamente:

```bash
# Queue A → Queue B (auto-forward)
az servicebus queue create \
  --name process-later \
  --namespace-name $NAMESPACE \
  --resource-group $RG \
  --forward-to completed-tasks

# Topic subscription → Queue
az servicebus topic subscription create \
  --name archive \
  --namespace-name $NAMESPACE \
  --topic-name events \
  --resource-group $RG \
  --forward-to archive-queue
```

**Caso de uso:** Filtrar mensajes del DLQ a otra queue para reprocesamiento.

## Scheduled delivery

```csharp
// Enviar mensaje para procesarse en 1 hora
var message = new ServiceBusMessage("Reminder");
message.ScheduledEnqueueTime = DateTimeOffset.UtcNow.AddHours(1);

await sender.SendMessageAsync(message);
```

Útil para:
- Recordatorios
- Retry con backoff exponencial
- Batch processing diferido

## Seguridad: Managed Identity

```bash
# Crear managed identity
az identity create \
  --name app-identity \
  --resource-group $RG

IDENTITY_ID=$(az identity show \
  --name app-identity \
  --resource-group $RG \
  --query principalId -o tsv)

# Asignar rol Service Bus Data Sender
az role assignment create \
  --role "Azure Service Bus Data Sender" \
  --assignee $IDENTITY_ID \
  --scope /subscriptions/{sub}/resourceGroups/$RG/providers/Microsoft.ServiceBus/namespaces/$NAMESPACE

# Asignar rol Service Bus Data Receiver
az role assignment create \
  --role "Azure Service Bus Data Receiver" \
  --assignee $IDENTITY_ID \
  --scope /subscriptions/{sub}/resourceGroups/$RG/providers/Microsoft.ServiceBus/namespaces/$NAMESPACE
```

Código sin connection strings:

```csharp
using Azure.Identity;

var credential = new DefaultAzureCredential();
var client = new ServiceBusClient(
    "<namespace>.servicebus.windows.net",
    credential
);
```

## Monitoreo

```bash
# Ver count de mensajes en queue
az servicebus queue show \
  --name $QUEUE_NAME \
  --namespace-name $NAMESPACE \
  --resource-group $RG \
  --query "messageCount"

# Ver mensajes en DLQ
az servicebus queue show \
  --name $QUEUE_NAME \
  --namespace-name $NAMESPACE \
  --resource-group $RG \
  --query "deadLetterMessageCount"

# Metrics en Log Analytics
az monitor metrics list \
  --resource /subscriptions/{sub}/resourceGroups/$RG/providers/Microsoft.ServiceBus/namespaces/$NAMESPACE \
  --metric "ActiveMessages" \
  --interval PT1H
```

Queries útiles:

```kusto
// Mensajes en DLQ por queue
AzureMetrics
| where ResourceProvider == "MICROSOFT.SERVICEBUS"
| where MetricName == "DeadletteredMessages"
| summarize DeadLetterCount = max(Maximum) by Resource
| order by DeadLetterCount desc

// Latencia de procesamiento
ServiceBusLogs
| where OperationName == "CompleteMessage"
| extend Duration = DurationMs
| summarize AvgDuration = avg(Duration), P95 = percentile(Duration, 95)
```

## Buenas prácticas

- **MaxDeliveryCount**: Ajusta según tu lógica de retry (defecto 10)
- **TTL realista**: No uses TTL infinito, causa acumulación
- **Procesa DLQ**: Monitorea y alertea en DLQ > 0
- **Sessions solo si necesitas**: Añade overhead
- **Managed Identity**: Nunca uses connection strings en código
- **Prefetch**: Habilita prefetch en receivers para throughput
- **Batch**: Envía mensajes en batch (hasta 100)

!!! warning "Quota exceeded"
    Si ves `QuotaExceeded`, revisa DLQ. Mensajes no procesados acumulan y bloquean nuevos envíos.

## Troubleshooting común

```bash
# Error: Queue not found
# Solución: Verifica namespace correcto
az servicebus queue list \
  --namespace-name $NAMESPACE \
  --resource-group $RG

# Error: Max message size exceeded (256KB Standard, 1MB Premium)
# Solución: Reduce payload o usa Premium tier

# Mensajes no llegan
# 1. Verifica receiver activo
# 2. Revisa DLQ
# 3. Comprueba TTL no expiró
```

## Referencias

- [Service Bus dead-letter queues](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-dead-letter-queues)
- [Enable dead lettering](https://learn.microsoft.com/en-us/azure/service-bus-messaging/enable-dead-letter)
- [Advanced features overview](https://learn.microsoft.com/en-us/azure/service-bus-messaging/advanced-features-overview)
- [Service Bus messaging overview](https://learn.microsoft.com/en-us/azure/service-bus-messaging/service-bus-messaging-overview)
