---
draft: false
date: 2025-02-03
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure Kubernetes Service
  - AKS
  - Kubernetes
---

# AKS: Autoscaling con KEDA para event-driven workloads

## Resumen

KEDA (Kubernetes Event-Driven Autoscaling) escala tus pods basado en eventos externos: colas de Service Bus, métricas de Prometheus, HTTP requests, etc. Mucho más flexible que HPA estándar.

## ¿Qué es KEDA?

KEDA extiende Kubernetes con scalers específicos para:
- Azure Service Bus queues/topics
- Azure Storage queues
- Kafka topics
- Redis lists
- Prometheus metrics
- HTTP traffic
- Cron schedules

## Instalación en AKS

```bash
# Habilitar KEDA addon (managed)
az aks update \
  --resource-group $RG \
  --name my-aks \
  --enable-keda

# Ver pods de KEDA
kubectl get pods -n kube-system | grep keda
```

## Ejemplo 1: Escalar con Azure Service Bus

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: servicebus-scaler
spec:
  scaleTargetRef:
    name: message-processor  # Deployment a escalar
  minReplicaCount: 0  # Scale to zero cuando no hay mensajes
  maxReplicaCount: 10
  triggers:
  - type: azure-servicebus
    metadata:
      queueName: myqueue
      namespace: myservicebus
      messageCount: "5"  # 1 pod por cada 5 mensajes
    authenticationRef:
      name: servicebus-auth
---
apiVersion: v1
kind: Secret
metadata:
  name: servicebus-connection
stringData:
  connection: "Endpoint=sb://myservicebus.servicebus.windows.net/;..."
---
apiVersion: keda.sh/v1alpha1
kind: TriggerAuthentication
metadata:
  name: servicebus-auth
spec:
  secretTargetRef:
  - parameter: connection
    name: servicebus-connection
    key: connection
```

## Ejemplo 2: Escalar con métricas Prometheus

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: prometheus-scaler
spec:
  scaleTargetRef:
    name: api-server
  minReplicaCount: 2
  maxReplicaCount: 20
  triggers:
  - type: prometheus
    metadata:
      serverAddress: http://prometheus:9090
      metricName: http_requests_per_second
      threshold: '100'
      query: sum(rate(http_requests_total[2m]))
```

## Ejemplo 3: Escalar con HTTP traffic

```bash
# Instalar HTTP Add-on
az aks addon enable \
  --resource-group $RG \
  --name my-aks \
  --addon http_application_routing
```

```yaml
apiVersion: keda.sh/v1alpha1
kind: HTTPScaledObject
metadata:
  name: http-scaler
spec:
  scaleTargetRef:
    name: web-app
    kind: Deployment
  minReplicaCount: 1
  maxReplicaCount: 50
  targetPendingRequests: 100  # Escalar cuando hay >100 requests pendientes
```

## Ejemplo 4: Cron-based scaling

```yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: cron-scaler
spec:
  scaleTargetRef:
    name: batch-processor
  minReplicaCount: 0
  maxReplicaCount: 10
  triggers:
  - type: cron
    metadata:
      timezone: Europe/Madrid
      start: 0 8 * * 1-5  # Lunes a viernes a las 8:00
      end: 0 18 * * 1-5   # Lunes a viernes a las 18:00
      desiredReplicas: "5"
```

## Monitore de KEDA

```bash
# Ver scaled objects
kubectl get scaledobjects

# Ver estado detallado
kubectl describe scaledobject servicebus-scaler

# Logs de KEDA operator
kubectl logs -n kube-system deployment/keda-operator
```

## Buenas prácticas

- **Scale to zero**: Solo para workloads que toleran cold start
- **Min replicas**: Al menos 2 para alta disponibilidad
- **Cooldown period**: Evita flapping con `cooldownPeriod: 300`
- **Managed Identity**: Usa workload identity para autenticación
- **Monitoring**: Integra con Prometheus para métricas de scaling

## Referencias

- [KEDA documentation](https://keda.sh/)
- [AKS KEDA addon](https://learn.microsoft.com/en-us/azure/aks/keda-about)
