---
draft: false
date: 2024-05-04
authors:
  - rfernandezdo
categories:
    - Azure Services
    - Snowflake    
tags:
    - Azure Private Link    
---
# Reduce your attack surface in Snowflake when using from Azure

When it comes to data security, reducing your attack surface is a crucial step. This post will guide you on how to minimize your attack surface when using Snowflake with Azure or Power BI.

## What is Snowflake?

Snowflake is a cloud-based data warehousing platform that allows you to store and analyze large amounts of data. It is known for its scalability, performance, and ease of use. Snowflake is popular among organizations that need to process large volumes of data quickly and efficiently.

## What is an Attack Surface?

An attack surface refers to the number of possible ways an attacker can get into a system and potentially extract data. The larger the attack surface, the more opportunities there are for attackers. Therefore, reducing the attack surface is a key aspect of securing your systems.

How to Reduce Your Attack Surface in Snowflake:

1. Use Azure Private Link
Azure Private Link provides private connectivity from a virtual network to Snowflake, isolating your traffic from the public internet. It significantly reduces the attack surface by ensuring that traffic between Azure and Snowflake doesn't traverse over the public internet.

2. Implement Network Policies
Snowflake allows you to define network policies that restrict access based on IP addresses. By limiting access to trusted IP ranges, you can reduce the potential points of entry for an attacker.

3. Enable Multi-Factor Authentication (MFA)
MFA adds an extra layer of security by requiring users to provide at least two forms of identification before accessing the Snowflake account. This makes it harder for attackers to gain unauthorized access, even if they have your password.


In this blog post, we will show you how to reduce your attack surface when using Snowflake from Azure or Power BI by using Azure Private Link

## Default Snowflake architecture

By default, Snowflake is accessible from the public internet. This means that anyone with the right credentials can access your Snowflake account from anywhere in the world, you can limit access to specific IP addresses, but this still exposes your Snowflake account to potential attackers. 

This is a security risk because it exposes your Snowflake account to potential attackers.


## Using Azure Private Link with Snowflake

### Simple Architecture Diagram of Azure Private Link with Snowflake

The architecture of using Azure Private Link with Snowflake is as follows:

```mermaid	

graph TD
    A[Virtual Network] -->|Private Endpoint| B[Snowflake]
    B -->|Private Link Service| C[Private Link Resource]
    C -->|Private Connection| D[Virtual Network]
    D -->|Subnet| E[Private Endpoint]
    Azure Private DNS
```

### Architecture Components



### Requirements

Before you can use Azure Private Link with Snowflake, you need to have the following requirements in place:

- A Snowflake account with ACCOUNTADMIN privileges
- Business Critical or higher Snowflake edition
- An Azure subscription with a Resource Group  and privileges to create:
    - Virtual Network
    - Subnet
    - Private Endpoint

### Step-by-Step Guide

!!! Info "Note"
    Replace the placeholders with your actual values, that is a orientation guide.

#### Step 1: Retrieve Dedailts of your Snowflake Account

```sql	
USE ROLE ACCOUNTADMIN;
select select SYSTEM$GET_PRIVATELINK_CONFIG();
```

#### Step 2: Create a Virtual Network

A virtual network is a private network that allows you to securely connect your resources in Azure. To create a virtual network with azcli, follow these steps:

```bash
az network vnet create \
  --name myVnet \
  --resource-group myResourceGroup \
  --address-prefix
  --subnet-name mySubnet \
  --subnet-prefix
  --enable-private-endpoint-network-policies true
```

#### Step 3: Create a Private Endpoint

The first step is to create a private endpoint in Azure. A private endpoint is a network interface that connects your virtual network to the Snowflake service. This allows you to access Snowflake using a private IP address, rather than a public one.

To create a private endpoint with azcli, follow these steps:

```bash
az network private-endpoint create \
  --name mySnowflakeEndpoint \
  --resource-group myResourceGroup \
  --vnet-name myVnet \
  --subnet mySubnet \
  --private-connection-resource-id /subscriptions/<subscription-id>/resourceGroups/<resource-group>/providers/Microsoft.Network/privateLinkServices/<Snowflake-service-name> \
  --connection-name mySnowflakeConnection
```


Check the status of the private endpoint:

```bash
az network private-endpoint show \
  --name mySnowflakeEndpoint \
  --resource-group myResourceGroup
```

#### Step 4: Authorize the Private Endpoint

The next step is to authorize the private endpoint to access the Snowflake service. 

Retrieve the Resource ID of the private endpoint:

```bash
az network private-endpoint show \
  --name mySnowflakeEndpoint \
  --resource-group myResourceGroup
```

Create a temporary access token that Snowflake can use to authorize the private endpoint:

```bash
az account get-access-token --subscription <subscription-id>
```

Authorize the private endpoint in Snowflake:

```sql
USE ROLE ACCOUNTADMIN;
select SYSTEM$AUTHORIZE_PRIVATELINK('<resource-id>', '<access-token>');
``` 

### Step 5: Block Public Access

To further reduce your attack surface, you can block public access to your Snowflake account. This ensures that all traffic to and from Snowflake goes through the private endpoint, reducing the risk of unauthorized access.

To block public access to your Snowflake account, you need to use Network Policy, follow these steps:

```sql
USE ROLE ACCOUNTADMIN;
CREATE NETWORK RULE allow_access_rule
  MODE = INGRESS
  TYPE = IPV4
  VALUE_LIST = ('192.168.1.99/24');

CREATE NETWORK RULE block_access_rule
  MODE = INGRESS
  TYPE = IPV4
  VALUE_LIST = ('0.0.0.0/0');

CREATE NETWORK POLICY public_network_policy
  ALLOWED_NETWORK_RULE_LIST = ('allow_access_rule')
  BLOCKED_NETWORK_RULE_LIST=('block_access_rule');
```


It's highly recommended to follow the best practices for network policies in Snowflake. You can find more information here:  https://docs.snowflake.com/en/user-guide/network-policies#best-practices

### Step 6: Test the Connection

To test the connection between your virtual network and Snowflake, you can use the SnowSQL client. 

```bash
snowsql -a <account_name> -u <username> -r <role> -w <warehouse> -d <database> -s <schema>
```



## Internal Stages with Azure Blob Private Endpoints

If you are using Azure Blob Storage as an internal stage in Snowflake, you can also use Azure Private Link to secure the connection between Snowflake and Azure Blob Storage.

It's recommended to use Azure Blob Storage with Private Endpoints to ensure that your data is secure and that you are reducing your attack surface, you can check the following documentation for more information: [Azure Private Endpoints for Internal Stages](https://docs.snowflake.com/en/user-guide/private-internal-stages-azure) to learn how to configure Azure Blob Storage with Private Endpoints in Snowflake.


## Conclusion

Reducing your attack surface is a critical aspect of securing your systems. By using Azure Private Link with Snowflake, you can significantly reduce the risk of unauthorized access and data breaches. Follow the steps outlined in this blog post to set up Azure Private Link with Snowflake and start securing your data today.

## References

- [Azure Private Link documentation](https://docs.microsoft.com/en-us/azure/private-link/)
- [Snowflake Editions](https://docs.snowflake.com/en/user-guide/intro-editions)
- [$GET_PRIVATELINK_CONFIG();](https://docs.snowflake.com/en/sql-reference/functions/system_get_privatelink)
- [Snowflake Network Policies](https://docs.snowflake.com/en/user-guide/network-policies)
- [Azure Private Endpoints for Internal Stages](https://docs.snowflake.com/en/user-guide/private-internal-stages-azure)

