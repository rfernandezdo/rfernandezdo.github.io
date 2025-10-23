---
draft: false
date: 2025-02-04
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure Kubernetes Service
---
# Test the proxy configuration in an AKS cluster

## Variables

```bash
export RESOURCE_GROUP=<your-resource-group>
export AKS_CLUSTER_NAME=<your-aks-cluster-name>
export MC_RESOURCE_GROUP_NAME=<your-mc-resource-group-name>
export VMSS_NAME=<your-vmss-name>
export HTTP_PROXYCONFIGURED="http://<your-http-proxy>:8080/"
export HTTPS_PROXYCONFIGURED="https://<your-https-proxy>:8080/"
```

## Get the VMSS instance IDs

```bash
# To get the instance IDs of all the instances in the VMSS, use the following command:
az vmss list-instances --resource-group $MC_RESOURCE_GROUP_NAME --name $VMSS_NAME --output table --query "[].instanceId"

# For one instance, you can use the following command to get the instance ID:
VMSS_INSTANCE_IDS=$(az vmss list-instances --resource-group $MC_RESOURCE_GROUP_NAME --name $VMSS_NAME --output table --query "[].instanceId" | tail -1)
```

## Use an instance ID to test connectivity from the HTTP proxy server to HTTPS

```bash
az vmss run-command invoke --resource-group $MC_RESOURCE_GROUP_NAME \
    --name $VMSS_NAME \
    --command-id RunShellScript \
    --instance-id $VMSS_INSTANCE_IDS \
    --output json \
    --scripts "curl --proxy $HTTP_PROXYCONFIGURED --head https://mcr.microsoft.com"
```

## Use an instance ID to test connectivity from the HTTPS proxy server to HTTPS

```bash
az vmss run-command invoke --resource-group $MC_RESOURCE_GROUP_NAME \
    --name $VMSS_NAME \
    --command-id RunShellScript \
    --instance-id $VMSS_INSTANCE_IDS \
    --output json \
    --scripts "curl --proxy $HTTPS_PROXYCONFIGURED --head https://mcr.microsoft.com"
```

## Use an instance ID to test DNS functionality

```bash
az vmss run-command invoke --resource-group $MC_RESOURCE_GROUP_NAME \
    --name $VMSS_NAME \
    --command-id RunShellScript \
    --instance-id $VMSS_INSTANCE_IDS \
    --output json \
    --scripts "dig mcr.microsoft.com 443"
```

## Test wagent logs

```bash
az vmss run-command invoke --resource-group $MC_RESOURCE_GROUP_NAME \
    --name $VMSS_NAME \
    --command-id RunShellScript \
    --instance-id $VMSS_INSTANCE_IDS \
    --output json \
    --scripts "cat /var/log/waagent.log"
```

## Test wagent status

```bash
az vmss run-command invoke --resource-group $MC_RESOURCE_GROUP_NAME \
    --name $VMSS_NAME \
    --command-id RunShellScript \
    --instance-id $VMSS_INSTANCE_IDS \
    --output json \
    --scripts "systemctl status waagent"
```

## Update the proxy configuration

```bash
az aks update -n $AKS_CLUSTER_NAME -g $RESOURCE_GROUP --http-proxy-config aks-proxy-config.json
az aks update --resource-group $RESOURCE_GROUP --name $AKS_CLUSTER_NAME --http-proxy-config aks-proxy-config.json
```