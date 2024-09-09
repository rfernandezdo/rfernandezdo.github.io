---
draft: false
date: 2024-06-13
authors:
  - rfernandezdo
categories:
    - Azure Services
    - Security
tags:
    - Azure Managed Disks    
    
---
# Restrict managed disks from being imported or exported

In this post, I will show you how to restrict managed disks from being imported or exported in Azure.

## What are managed disks?

Azure Managed Disks are block-level storage volumes that are managed by Azure and used with Azure Virtual Machines. Managed Disks are designed for high availability and durability, and they provide a simple and scalable way to manage your storage.

If you don't know anything about Azue Managed Disks, grab a cup of coffee( it will take you a while), you can read the [official documentation](https://docs.microsoft.com/en-us/azure/virtual-machines/managed-disks-overview) to learn more about them.

## Why restrict managed disks from being imported or exported?

There are several reasons to restrict managed disks from being imported or exported:

- **Security**: By restricting managed disks from being imported or exported, you can reduce the risk of unauthorized access to your data.
- **Compliance**: By restricting managed disks from being imported or exported, you can help ensure that your organization complies with data protection regulations.

## How to restrict managed disks from being imported or exported

### At deployment time

An example with azcli:

#### Create a managed disk with public network access disabled

```azcli
## Create a managed disk with public network access disabled
az disk create --resource-group myResourceGroup --name myDisk --size-gb 128 --location eastus --sku Standard_LRS --no-wait --public-network-access disabled 
```

#### Create a managed disk with public network access disabled and private endpoint enabled

Follow [Azure CLI - Restrict import/export access for managed disks with Private Links](https://learn.microsoft.com/en-us/azure/virtual-machines/linux/disks-export-import-private-links-cli#log-in-into-your-subscription-and-set-your-variables)


### At Scale

If you want to restrict managed disks from being imported or exported, you can use Azure Policy to enforce this restriction. Azure Policy is a service in Azure that you can use to create, assign, and manage policies that enforce rules and effects over your resources. By using Azure Policy, you can ensure that your resources comply with your organization's standards and service-level agreements.

To restrict managed disks from being imported or exported using Azure Policy, you can use or create a policy definition that specifies the conditions under which managed disks can be imported or exported. You can then assign this policy definition to a scope, such as a management group, subscription, or resource group, to enforce the restriction across your resources.

In this case we have a Built-in policy definition that restricts managed disks from being imported or exported [Configure disk access resources with private endpoints](https://portal.azure.com/#blade/Microsoft_Azure_Policy/PolicyDetailBlade/definitionId/%2Fproviders%2FMicrosoft.Authorization%2FpolicyDefinitions%2F582bd7a6-a5f6-4dc6-b9dc-9cb81fe0d4c5)


## Conclusion

In this post, I showed you how to restrict managed disks from being imported or exported in Azure. By restricting managed disks from being imported or exported, you can reduce the risk of unauthorized access to your data and help ensure that your organization complies with data protection regulations. 

Curiosly, restrict managed disks from being imported or exported, it's not a compliance check in the Microsoft cloud security benchmark but it's a good practice to follow.
