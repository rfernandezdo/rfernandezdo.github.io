---
draft: true
date: 2024-06-16
authors:
  - rfernandezdo
categories:
    - Azure Services

tags:
    - Azure Blob Storage
---
# Azure Blob Storage Cross Tenant Replication

In Azure blob Storage, you can configure Cross-Tenant Replication to replicate data between storage accounts in different tenants. This feature is useful when you need to replicate data between storage accounts in different tenants. This article explains how to enable cross-tenant replication on Azure Blob Storage.

## Prerequisites

To enable cross-tenant replication on Azure Blob Storage, you need the following:

- Two Azure subscriptions in different tenants.
- Two storage accounts in the same region.
- A service principal in each tenant with the necessary permissions to access the storage accounts.

## Configure Cross-Tenant Replication 

### Enable Cross-Tenant Replication

Here is how you can enable cross-tenant replication using the Azure CLI:

```bash
# Set variables
RESOURCE_GROUP="<resource-group>"
SOURCE_STORAGE_ACCOUNT="<source-storage-account>"
DESTINATION_STORAGE_ACCOUNT="<dest-storage-account>"

# Login to Azure
az login

# Update the source storage account with versioning and change feed enabled
az storage account blob-service-properties update \
    --resource-group $RESOURCE_GROUP \
    --account-name $SOURCE_STORAGE_ACCOUNT \
    --enable-versioning \
    --enable-change-feed

# Update the destination storage account with versioning enabled
az storage account blob-service-properties update \
    --resource-group $RESOURCE_GROUP \
    --account-name $DESTINATION_STORAGE_ACCOUNT \
    --enable-versioning

```

### Create the source and destination containers

You need to create the source and destination containers in the storage accounts. Here is how you can create the containers using the Azure CLI:

```bash
# Set variables
SOURCE_STORAGE_ACCOUNT="<source-storage-account>"
DESTINATION_STORAGE_ACCOUNT="<dest-storage-account>"
RESOURCE_GROUP="<resource-group>"
SOURCE_CONTAINER_1="source-container-1"
DESTINATION_CONTAINER_1="dest-container-1"
SOURCE_CONTAINER_2="source-container-2"
DESTINATION_CONTAINER_2="dest-container-2"


# Create containers in the source storage account
az storage container create \
    --account-name $SOURCE_STORAGE_ACCOUNT \
    --name $SOURCE_CONTAINER_1 \
    --auth-mode login

az storage container create \
    --account-name $SOURCE_STORAGE_ACCOUNT \
    --name $SOURCE_CONTAINER_2 \
    --auth-mode login

# Create containers in the destination storage account
az storage container create \
    --account-name $DESTINATION_STORAGE_ACCOUNT \
    --name $DESTINATION_CONTAINER_1 \
    --auth-mode login

az storage container create \
    --account-name $DESTINATION_STORAGE_ACCOUNT \
    --name $DESTINATION_CONTAINER_2 \
    --auth-mode login
```

Here's a detailed breakdown of the command:

- `az storage container create`: This is an Azure CLI command to create a container in a storage account.

- `--account-name $SOURCE_STORAGE_ACCOUNT`: Specifies the name of the source storage account where you want to create the container.

- `--name $SOURCE_CONTAINER_1`: Specifies the name of the container you want to create in the source storage account.

- `--auth-mode login`: Specifies that you want to use the login credentials to authenticate with the storage account.

### Create a new replication policy and associate it with the destination account

```bash
# Set variables
DESTINATION_STORAGE_ACCOUNT="<dest-storage-account>"
RESOURCE_GROUP="<resource-group>"
SOURCE_STORAGE_ACCOUNT="<source-storage-account>"
SOURCE_CONTAINER_1="source-container-1"
DESTINATION_CONTAINER_1="dest-container-1"
MIN_CREATION_TIME="2021-09-01T00:00:00Z"
PREFIX_MATCH="a"


# Create object replication policy
az storage account or-policy create \
    --account-name $DESTINATION_STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --source-account $SOURCE_STORAGE_ACCOUNT \
    --destination-account $DESTINATION_STORAGE_ACCOUNT \
    --source-container $SOURCE_CONTAINER_1 \
    --destination-container $DESTINATION_CONTAINER_1 \
    --min-creation-time $MIN_CREATION_TIME \
    --prefix-match $PREFIX_MATCH
```

Here's a detailed breakdown of the command:

- `az storage account or-policy create`: This is an Azure CLI command to create an object replication policy for a storage account.

- `--account-name $DESTINATION_STORAGE_ACCOUNT`: Specifies the name of the destination storage account where you want to replicate objects.

- `--resource-group $RESOURCE_GROUP`: Specifies the name of the resource group that contains the destination storage account.

- `--source-account $SOURCE_STORAGE_ACCOUNT`: Specifies the name of the source storage account from where you want to replicate objects.

- `--destination-account $DESTINATION_STORAGE_ACCOUNT`: Specifies the name of the destination storage account. This is typically the same as `--account-name`.

- `--source-container $SOURCE_CONTAINER_1`: Specifies the name of the source container in the source storage account from where you want to replicate objects.

- `--destination-container $DESTINATION_CONTAINER_1`: Specifies the name of the destination container in the destination storage account where you want to replicate objects.

- `--min-creation-time $MIN_CREATION_TIME`: Specifies the minimum creation time of the objects that you want to replicate. In this case, it's set to September 1, 2021.

- `--prefix-match $PREFIX_MATCH`: Specifies that only objects with names that start with 'a' should be replicated.

This command creates an object replication policy that replicates objects from `$SOURCE_CONTAINER` in the source storage account to `$DESTINATION_CONTAINER` in the destination storage account. It only replicates objects that were created after September 1, 2021 and have names that start with 'a'.


### Add a new replication policy to an existing object replication policy

```bash
# Set variables
DESTINATION_STORAGE_ACCOUNT="<dest-storage-account>"
RESOURCE_GROUP="<resource-group>"
SOURCE_STORAGE_ACCOUNT="<source-storage-account>"
SOURCE_CONTAINER_2="source-container-2"
DESTINATION_CONTAINER_2="dest-container-2"
POLICY_ID="<policy-id>"
PREFIX_MATCH="b"

az storage account or-policy rule add \
    --account-name $DESTINATION_STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --source-container $SOURCE_CONTAINER \
    --destination-container $DESTINATION_CONTAINER \
    --policy-id $POLICY_ID \
    --prefix-match $PREFIX_MATCH

```	

Here's a detailed breakdown of the command:

- `az storage account or-policy rule add`: This is an Azure CLI command to add a new rule to an existing object replication policy.

- `--account-name $DESTINATION_STORAGE_ACCOUNT`: Specifies the name of the destination storage account where you want to replicate objects.

- `--resource-group $RESOURCE_GROUP`: Specifies the name of the resource group that contains the destination storage account.

- `--source-container $SOURCE_CONTAINER_2`: Specifies the name of the source container in the source storage account from where you want to replicate objects.

- `--destination-container $DESTINATION_CONTAINER_2`: Specifies the name of the destination container in the destination storage account where you want to replicate objects.

- `--policy-id $POLICY_ID`: Specifies the ID of the object replication policy to which you want to add the new rule.

- `--prefix-match $PREFIX_MATCH`: Specifies that only objects with names that start with 'b' should be replicated.

### Create the policy on the source account using the policy ID

```bash
# Set variables
SOURCE_STORAGE_ACCOUNT="<source-storage-account>"
RESOURCE_GROUP="<resource-group>"
POLICY_ID="<policy-id>"
DESTINATION_STORAGE_ACCOUNT="<dest-storage-account>"

az storage account or-policy show \
    --resource-group $RESOURCE_GROUP \
    --account-name DESTINATION_STORAGE_ACCOUNT \
    --policy-id $POLICY_ID |
    az storage account or-policy create --resource-group  RESOURCE_GROUP \   
     --account-name $SOURCE_STORAGE_ACCOUNT \
    --policy "@-"
```    

### Monitor the replication status

You can monitor the replication status using the Azure CLI:

```bash
#!/bin/bash

# Define your variables
SOURCE_ACCOUNT_NAME="<source-account-name>"
SOURCE_CONTAINER_NAME="<source-container-name>"
SOURCE_BLOB_NAME="<source-blob-name>"

# Use the variables in the command
az storage blob show --account-name $SOURCE_ACCOUNT_NAME --container-name $SOURCE_CONTAINER_NAME --name $SOURCE_BLOB_NAME --query 'objectReplicationSourceProperties[].rules[].status' --output tsv --auth-mode login
```


## How to check if Cross-Tenant Replication is enabled in storage accounts

You can use the Azure Resource Graph to query the storage accounts and check if cross-tenant replication is enabled. Here's an example query that lists the storage accounts and if cross-tenant replication is enabled:

```KQL
resources
| where type "microsoft.storage/storageaccounts"
| extend properties= parse json(properties)
| extend crossTenantRep1ication = properties.allowCrossTenantRep1ication
project name, location, crossTenantRep1ication

```

crossTenantRep1ication 

- **true**: This means that cross-tenant replication is enabled.
- **false**: This means that cross-tenant replication is not enabled.
- **null**: This means that the property is not set. This can happen if the storage account was created before  15/12/2023. Storage accounts with null values will have cross-tenant replication enabled.


## How to check replication destination

You can use the Azure CLI to check the replication destination status. Here's an example command that lists the replication destination status for a storage account:

```bash
az storage account or-policy show --account-name <storage-account-name> --resource-group <resource-group> --policy-id <policy-id>
```
