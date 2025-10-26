---
draft: false
date: 2025-04-03
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure Kubernetes Service
  - AKS
  - Kubernetes
  - Container Orchestration
---

# Azure Kubernetes Service: Cluster production-ready en 30 minutos

## Resumen

AKS elimina la complejidad de gestionar el control plane de Kubernetes. Voy al grano: aquí está el setup mínimo para producción con autoscaling, availability zones y networking correcto.

## ¿Qué es AKS?

Azure Kubernetes Service (AKS) es Kubernetes managed donde Azure gestiona:

- **Control plane** (API server, etcd, scheduler) - Sin coste
- **Actualizaciones y patches** - Automatizadas
- **Alta disponibilidad** - SLA 99.95% con uptime SLA

Tú solo pagas y gestionas los worker nodes.

## Crear cluster production-ready

### Setup básico con mejores prácticas

```bash
# Variables
RG="aks-prod-rg"
LOCATION="westeurope"
CLUSTER_NAME="aks-prod-cluster"
NODE_COUNT=2

# Crear resource group
az group create \
  --name $RG \
  --location $LOCATION

# Crear AKS con best practices
az aks create \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --node-count $NODE_COUNT \
  --node-vm-size Standard_DS2_v2 \
  --vm-set-type VirtualMachineScaleSets \
  --load-balancer-sku standard \
  --enable-cluster-autoscaler \
  --min-count 1 \
  --max-count 5 \
  --network-plugin azure \
  --generate-ssh-keys \
  --zones 1 2 3
```

!!! note "Availability Zones"
    `--zones 1 2 3` distribuye nodes entre 3 AZs para alta disponibilidad. Esto NO se puede cambiar después de crear el cluster.

### Obtener credenciales

```bash
# Configurar kubectl
az aks get-credentials \
  --resource-group $RG \
  --name $CLUSTER_NAME

# Verificar conexión
kubectl get nodes
```

## Cluster Autoscaler

El Cluster Autoscaler escala nodes automáticamente basándose en pods pendientes:

**Cómo funciona:**
1. Pod no puede ser scheduled (falta capacidad)
2. Autoscaler añade node nuevo
3. Pod se programa en el nuevo node
4. Cuando nodes están infrautilizados, autoscaler los elimina

### Configurar autoscaler profile

```bash
# Autoscaler agresivo (escala rápido, libera rápido)
az aks update \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --cluster-autoscaler-profile \
    scan-interval=30s \
    scale-down-delay-after-add=0m \
    scale-down-unneeded-time=3m \
    scale-down-unready-time=3m

# Autoscaler conservador (para workloads bursty)
az aks update \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --cluster-autoscaler-profile \
    scan-interval=20s \
    scale-down-delay-after-add=10m \
    scale-down-unneeded-time=5m \
    scale-down-unready-time=5m
```

**Parámetros clave:**
- `scan-interval`: Frecuencia de evaluación (defecto 10s)
- `scale-down-delay-after-add`: Espera después de añadir node
- `scale-down-unneeded-time`: Tiempo antes de eliminar node infrautilizado

### Actualizar límites de autoscaling

```bash
# Cambiar min/max de un node pool
az aks nodepool update \
  --resource-group $RG \
  --cluster-name $CLUSTER_NAME \
  --name nodepool1 \
  --update-cluster-autoscaler \
  --min-count 2 \
  --max-count 10
```

## Horizontal Pod Autoscaler (HPA)

Escala pods basándose en CPU/memoria o métricas custom:

```yaml
# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: my-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

```bash
kubectl apply -f hpa.yaml

# Ver estado HPA
kubectl get hpa
```

## Vertical Pod Autoscaler (VPA)

Ajusta CPU/memoria requests automáticamente:

```bash
# Habilitar VPA en el cluster
az aks update \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --enable-vpa
```

```yaml
# vpa.yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: my-app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: my-app
  updatePolicy:
    updateMode: "Auto"  # Auto | Off | Initial
```

**Modos VPA:**
- **Off**: Solo recomendaciones, no aplica cambios
- **Auto**: Actualiza resources durante pod restart
- **Initial**: Solo establece resources en creación

!!! warning "HPA + VPA"
    NO uses HPA y VPA juntos en las mismas métricas (CPU/memoria). Crea conflictos. Puedes combinar HPA en custom metrics con VPA en CPU/memoria.

## Node pools separados

```bash
# Node pool para cargas batch (spot instances)
az aks nodepool add \
  --resource-group $RG \
  --cluster-name $CLUSTER_NAME \
  --name spotpool \
  --node-count 1 \
  --priority Spot \
  --eviction-policy Delete \
  --spot-max-price -1 \
  --enable-cluster-autoscaler \
  --min-count 0 \
  --max-count 5 \
  --node-taints kubernetes.azure.com/scalesetpriority=spot:NoSchedule

# Node pool para sistema (garantizado)
az aks nodepool add \
  --resource-group $RG \
  --cluster-name $CLUSTER_NAME \
  --name systempool \
  --node-count 2 \
  --node-vm-size Standard_DS3_v2 \
  --mode System \
  --zones 1 2 3
```

## Networking: Azure CNI vs Kubenet

**Azure CNI** (recomendado para producción):
- Pods tienen IPs de la VNet
- Integración directa con servicios Azure
- Soporte para Network Policies

**Kubenet** (más simple, menos IPs):
- Pods usan IPs privadas (NAT)
- Menos consumo de IPs de subnet
- No soporta Windows node pools

```bash
# Crear cluster con Azure CNI Overlay (más eficiente IPs)
az aks create \
  --resource-group $RG \
  --name aks-cni-overlay \
  --network-plugin azure \
  --network-plugin-mode overlay \
  --pod-cidr 10.244.0.0/16
```

## Upgrades de cluster

```bash
# Ver versiones disponibles
az aks get-upgrades \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --output table

# Upgrade a versión específica
az aks upgrade \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --kubernetes-version 1.28.3

# Habilitar auto-upgrade
az aks update \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --auto-upgrade-channel stable
```

**Canales auto-upgrade:**
- `none`: Manual
- `patch`: Auto-upgrade a patches (1.27.3 → 1.27.5)
- `stable`: Versión N-1 estable
- `rapid`: Última versión disponible

## Pod Disruption Budgets (PDB)

Garantiza disponibilidad durante upgrades:

```yaml
# pdb.yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: my-app-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: my-app
```

```bash
kubectl apply -f pdb.yaml

# Verificar PDB
kubectl get pdb
```

## Monitoreo con Container Insights

```bash
# Habilitar Container Insights
az aks enable-addons \
  --resource-group $RG \
  --name $CLUSTER_NAME \
  --addons monitoring

# Ver logs en tiempo real
az aks browse \
  --resource-group $RG \
  --name $CLUSTER_NAME
```

Queries útiles en Log Analytics:

```kusto
// Pods con más restarts
KubePodInventory
| where ClusterName == "aks-prod-cluster"
| summarize RestartCount = sum(PodRestartCount) by Name
| order by RestartCount desc
| take 10

// Nodes con alta CPU
Perf
| where ObjectName == "K8SNode"
| where CounterName == "cpuUsageNanoCores"
| summarize AvgCPU = avg(CounterValue) by Computer
| order by AvgCPU desc
```

## Buenas prácticas

- **Availability Zones**: Siempre usa 3 AZs para producción
- **System node pool separado**: Aísla workloads de componentes del sistema
- **Resource limits**: Define requests y limits en todos los pods
- **PodDisruptionBudgets**: Evita downtime en upgrades
- **Azure CNI**: Usa Azure CNI para integración completa
- **Autoscaling**: Combina cluster autoscaler + HPA
- **No B-series VMs**: Usa D/E/F series para workloads serios
- **Premium Disks**: Para bases de datos y cargas I/O intensivas

!!! tip "Costos"
    - Control plane: Gratis (o €0.10/hora con uptime SLA)
    - Nodes: Pagas VMs estándar (~€50-150/mes por node DS2_v2)
    - Usa Spot VMs para workloads batch (70% descuento)

## Troubleshooting común

```bash
# Ver eventos del cluster
kubectl get events --sort-by='.lastTimestamp'

# Pods que no arrancan
kubectl describe pod <pod-name>

# Logs de un pod
kubectl logs <pod-name> --previous

# Ejecutar comando en pod
kubectl exec -it <pod-name> -- /bin/bash

# Ver resource usage
kubectl top nodes
kubectl top pods
```

## Referencias

- [AKS best practices - Deployment reliability](https://learn.microsoft.com/en-us/azure/aks/best-practices-app-cluster-reliability)
- [Cluster autoscaler overview](https://learn.microsoft.com/en-us/azure/aks/cluster-autoscaler-overview)
- [Best practices for performance and scaling](https://learn.microsoft.com/en-us/azure/aks/best-practices-performance-scale)
- [AKS networking concepts](https://learn.microsoft.com/en-us/azure/aks/concepts-network)
