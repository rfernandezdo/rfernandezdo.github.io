---
draft: false
date: 2024-04-19
authors:
  - rfernandezdo
categories:
    - Azure
tags:
    - Role-Based Access Control    
---    

# Azure Role-Based Access Control (RBAC)

Azure Role-Based Access Control (RBAC) is a system that provides fine-grained access management of resources in Azure. This allows administrators to grant only the amount of access that users need to perform their jobs.

## Overview

In Azure RBAC, you can assign roles to user accounts, groups, service principals, and managed identities at different scopes. The scope could be a management group, subscription, resource group, or a single resource. 

Here are some key terms you should know:

- **Role**: A collection of permissions. For example, the "Virtual Machine Contributor" role allows the user to create and manage virtual machines.
- **Scope**: The set of resources that the access applies to. 
- **Assignment**: The act of granting a role to a security principal at a particular scope.

## Built-in Roles

Azure provides several built-in roles that you can assign to users, groups, service principals, and managed identities. Here are a few examples:

- **Owner**: Has full access to all resources including the right to delegate access to others.
- **Contributor**: Can create and manage all types of Azure resources but can’t grant access to others.
- **Reader**: Can view existing Azure resources.

```json
{
  "Name": "Contributor",
  "Id": "b24988ac-6180-42a0-ab88-20f7382dd24c",
  "IsCustom": false,
  "Description": "Lets you manage everything except access to resources.",
  "Actions": [
    "*"
  ],
  "NotActions": [
    "Microsoft.Authorization/*/Delete",
    "Microsoft.Authorization/*/Write",
    "Microsoft.Authorization/elevateAccess/Action"
  ],
  "DataActions": [],
  "NotDataActions": [],
  "AssignableScopes": [
    "/"
  ]
}
```

## Custom Roles

If the built-in roles don't meet your specific needs, you can create your own custom roles. Just like built-in roles, you can assign permissions to custom roles and then assign those roles to users.

## Conclusion

Azure RBAC is a powerful tool for managing access to your Azure resources. By understanding its core concepts and how to apply them, you can ensure that users have the appropriate level of access for their job.

