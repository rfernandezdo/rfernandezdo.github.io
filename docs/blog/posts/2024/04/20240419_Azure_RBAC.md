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

```json
{
  "Name": "Custom Role",
  "Id": "00000000-0000-0000-0000-000000000000",
  "IsCustom": true,
  "Description": "Custom role description",
  "Actions": [
    "Microsoft.Compute/virtualMachines/start/action",
    "Microsoft.Compute/virtualMachines/restart/action"
  ],
  "NotActions": [],
  "DataActions": [],
  "NotDataActions": [],
  "AssignableScopes": [
    "/subscriptions/{subscriptionId}"
  ]
}
```
Custom Roles has the same structure as built-in roles:

- **Name**: The name of the custom role.
- **Id**: A unique identifier for the custom role.
- **IsCustom**: Indicates whether the role is custom or built-in.
- **Description**: A description of the custom role.
- **Actions**: The list of actions that the role can perform.
- **NotActions**: The list of actions that the role cannot perform.
- **DataActions**: The list of data actions that the role can perform.
- **NotDataActions**: The list of data actions that the role cannot perform.
- **AssignableScopes**: The list of scopes where the role can be assigned.


You can check how to create a custom role [here](https://learn.microsoft.com/en-us/azure/role-based-access-control/custom-roles#custom-role-properties) and not forget to check limitations [here](https://learn.microsoft.com/en-us/azure/role-based-access-control/custom-roles#custom-role-limits).




## Recommendations

Here are some best practices for managing access with Azure RBAC:

- **Use the principle of least privilege**: Only grant the permissions that users need to do their jobs.
- **Use built-in roles when possible**: [Built-in roles](https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles) are already defined and tested by Microsoft. Only create custom roles when necessary.
- **Regularly review role assignments**: Make sure that users have the appropriate level of access for their job. Remove any unnecessary role assignments.


## Conclusion

Azure RBAC is a powerful tool for managing access to your Azure resources. By understanding its core concepts and how to apply them, you can ensure that users have the appropriate level of access for their job.

