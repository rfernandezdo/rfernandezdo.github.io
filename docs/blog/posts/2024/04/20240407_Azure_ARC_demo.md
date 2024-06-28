---
draft: false
date: 2024-04-07
authors:
  - rfernandezdo
categories:
    - Azure Services
tags:
    - Azure ARC
---

# How to use Azue ARC-enabled servers with managed identity to access to Azure Storage Account

In this demo we will show how to use Azure ARC-enabled servers with managed identity to access to Azure Storage Account.

## Prerequisites

- An Azure subscription. If you don't have an Azure subscription, create a [free account](https://azure.microsoft.com/en-us/free/) before you begin.

## Required permissions

You'll need the following Azure built-in roles for different aspects of managing connected machines:

-   To onboard machines, you must have the [Azure Connected Machine Onboarding](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-connected-machine-onboarding) or [Contributor](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#contributor) role for the resource group where you're managing the servers.
-   To read, modify, and delete a machine, you must have the [Azure Connected Machine Resource Administrator](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#azure-connected-machine-resource-administrator) role for the resource group.
-   To select a resource group from the drop-down list when using the **Generate script** method, you'll also need the [Reader](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles#reader) role for that resource group (or another role that includes **Reader** access).

## Register Azure resource providers

To use Azure Arc-enabled servers with managed identity, you need to register the following resource providers:

```bash
az account set --subscription "{Your Subscription Name}"
az provider register --namespace 'Microsoft.HybridCompute'
az provider register --namespace 'Microsoft.GuestConfiguration'
az provider register --namespace 'Microsoft.HybridConnectivity'
az provider register --namespace 'Microsoft.AzureArcData'
```

!!! Info
    Microsoft.AzureArcData (if you plan to Arc-enable SQL Servers)
    Microsoft.Compute (for Azure Update Manager and automatic extension upgrades)

## Networking requirements

The Azure Connected Machine agent for Linux and Windows communicates outbound securely to Azure Arc over TCP port 443. In this demo, we have use [Azure Private Link](https://learn.microsoft.com/en-us/azure/azure-arc/servers/private-link-security#network-configuration). 


## Azure ARC-enabled enabled server

We use  [Use Azure Private Link to securely connect networks to Azure Arc-enabled servers](https://azurearcjumpstart.io/azure_arc_jumpstart/azure_arc_servers/day2/arc_privatelink) to achieve this.

Some tips:

- If you have any issue registerin de VM: generate a script to register a machine with Azure Arc following that instructions [here](https://learn.microsoft.com/en-us/azure/azure-arc/servers/learn/quick-enable-hybrid-vm#generate-installation-script)

- If you have an error that says "Path C:\ProgramData\AzureConnectedMachineAgent\Log\himds.log is busy. Retrying..." you can use the following command to resolve it if you know that you are doing:

```powershell
 (get-wmiobject -class win32_product | where {$_.name -like "Azure *"}).uninstall() 
```
- Review /etc/hosts file and add the following entries:

```powershell
$Env:PEname = "myprivatelink"
$Env:resourceGroup = "myResourceGroup"
$file = "C:\Windows\System32\drivers\etc\hosts"

$gisfqdn = (az network private-endpoint dns-zone-group list --endpoint-name $Env:PEname --resource-group $Env:resourceGroup -o json --query '[0].privateDnsZoneConfigs[0].recordSets[0].fqdn' -o json).replace('.privatelink','').replace("`"","")
$gisIP = (az network private-endpoint dns-zone-group list --endpoint-name $Env:PEname --resource-group $Env:resourceGroup -o json --query [0].privateDnsZoneConfigs[0].recordSets[0].ipAddresses[0] -o json).replace("`"","")
$hisfqdn = (az network private-endpoint dns-zone-group list --endpoint-name $Env:PEname --resource-group $Env:resourceGroup -o json --query [0].privateDnsZoneConfigs[0].recordSets[1].fqdn -o json).replace('.privatelink','').replace("`"","")
$hisIP = (az network private-endpoint dns-zone-group list --endpoint-name $Env:PEname --resource-group $Env:resourceGroup -o json --query [0].privateDnsZoneConfigs[0].recordSets[1].ipAddresses[0] -o json).replace('.privatelink','').replace("`"","")
$agentfqdn = (az network private-endpoint dns-zone-group list --endpoint-name $Env:PEname --resource-group $Env:resourceGroup -o json --query [0].privateDnsZoneConfigs[1].recordSets[0].fqdn -o json).replace('.privatelink','').replace("`"","")
$agentIp = (az network private-endpoint dns-zone-group list --endpoint-name $Env:PEname --resource-group $Env:resourceGroup -o json --query [0].privateDnsZoneConfigs[1].recordSets[0].ipAddresses[0] -o json).replace('.privatelink','').replace("`"","")
$gasfqdn = (az network private-endpoint dns-zone-group list --endpoint-name $Env:PEname --resource-group $Env:resourceGroup -o json --query [0].privateDnsZoneConfigs[1].recordSets[1].fqdn -o json).replace('.privatelink','').replace("`"","")
$gasIp = (az network private-endpoint dns-zone-group list --endpoint-name $Env:PEname --resource-group $Env:resourceGroup -o json --query [0].privateDnsZoneConfigs[1].recordSets[1].ipAddresses[0] -o json).replace('.privatelink','').replace("`"","")
$dpfqdn = (az network private-endpoint dns-zone-group list --endpoint-name $Env:PEname --resource-group $Env:resourceGroup -o json --query [0].privateDnsZoneConfigs[2].recordSets[0].fqdn -o json).replace('.privatelink','').replace("`"","")
$dpIp = (az network private-endpoint dns-zone-group list --endpoint-name $Env:PEname --resource-group $Env:resourceGroup -o json --query [0].privateDnsZoneConfigs[2].recordSets[0].ipAddresses[0] -o json).replace('.privatelink','').replace("`"","")

$hostfile += "$gisIP $gisfqdn"
$hostfile += "$hisIP $hisfqdn"
$hostfile += "$agentIP $agentfqdn"
$hostfile += "$gasIP $gasfqdn"
$hostfile += "$dpIP $dpfqdn"
```



## Storage Account configuration

### Create a Storage Account with static website enabled

```powershell
$resourceGroup = "myResourceGroup"
$location = "eastus"
$storageAccount = "mystorageaccount"
$indexDocument = "index.html"
az group create --name $resourceGroup --location $location
az storage account create --name $storageAccount --resource-group $resourceGroup --location $location --sku Standard_LRS
az storage blob service-properties update --account-name $storageAccount --static-website --index-document $indexDocument
```

### Add private endpoints to the storage accoun for blob and static website

```powershell
$resourceGroup = "myResourceGroup"
$storageAccount = "mystorageaccount"
$privateEndpointName = "myprivatelink"
$location = "eastus"
$vnetName = "myVnet"
$subnetName = "mySubnet"
$subscriptionId = "{subscription-id}"
az network private-endpoint create --name $privateEndpointName --resource-group $resourceGroup --vnet-name $vnetName --subnet $subnetName --private-connection-resource-id "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccount" --group-id blob --connection-name $privateEndpointName --location $location
az network private-endpoint create --name $privateEndpointName --resource-group $resourceGroup --vnet-name $vnetName --subnet $subnetName --private-connection-resource-id "/subscriptions/$subscriptionId/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccount" --group-id web --connection-name $privateEndpointName --location $location
```

### Disable public access to the storage account except for your ip

```powershell
$resourceGroup = "myResourceGroup"
$storageAccount = "mystorageaccount"
$ipAddress = "myIpAddress"
az storage account update --name $storageAccount --resource-group $resourceGroup --bypass "AzureServices,Logging,Metrics" --default-action Deny
az storage account network-rule add --account-name $storageAccount --resource-group $resourceGroup --ip-address $ipAddress
```


### Assign the Storage Blob Data Contributor role to the managed identity of the Azure ARC-enabled server

```powershell
$resourceGroup = "myResourceGroup"
$storageAccount = "mystorageaccount"
$serverName = "myserver"
$managedIdentity = az resource show --resource-group $resourceGroup --name $serverName --resource-type "Microsoft.HybridCompute/machines" --query "identity.principalId" --output tsv
az role assignment create --role "Storage Blob Data Contributor" --assignee-object-id $managedIdentity --scope "/subscriptions/{subscription-id}/resourceGroups/$resourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccount"
```


## Download azcopy,  install it and copy something to $web in the storage account

### Download azcopy in the vm

```powershell

Invoke-WebRequest -Uri "https://aka.ms/downloadazcopy-v10-windows" -OutFile AzCopy.zip

Expand-Archive AzCopy.zip -DestinationPath $env:ProgramFiles

$env:Path += ";$env:ProgramFiles\azcopy"
```

### Copy something to $web in the storage account

```powershell
$storageAccount = "mystorageaccount"
$source = "C:\Users\Public\Documents\myFile.txt"
$destination = "https://$storageAccount.blob.core.windows.net/\$web/myFile.txt"
azcopy login --identity
azcopy copy $source $destination
```


Now you can check the file in the static website of the storage account.