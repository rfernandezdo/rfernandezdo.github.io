---
draft: false
date: 2024-04-17
authors:
  - rfernandezdo
categories:
    - Azure Services
tags:
    - Azure Policy
---

# Azure Policy useful queries

## Policy assignments and information about each of its respective definitions

```kusto
// Policy assignments and information about each of its respective definitions
// Gets policy assignments in your environment with the respective assignment name,definition associated, category of definition (if applicable), as well as whether the definition type is an initiative or a single policy.

policyResources
| where type =~'Microsoft.Authorization/PolicyAssignments'
| project policyAssignmentId = tolower(tostring(id)), policyAssignmentDisplayName = tostring(properties.displayName), policyAssignmentDefinitionId = tolower(properties.policyDefinitionId)
| join kind=leftouter(
 policyResources
 | where type =~'Microsoft.Authorization/PolicySetDefinitions' or type =~'Microsoft.Authorization/PolicyDefinitions'
 | project definitionId = tolower(id), category = tostring(properties.metadata.category), definitionType = iff(type =~ 'Microsoft.Authorization/PolicysetDefinitions', 'initiative', 'policy')
) on $left.policyAssignmentDefinitionId == $right.definitionId
```

- [Original Gist](https://https://gist.github.com/timothywarner/8e5b6dea296f506871223883eb33059e)

## List SubscriptionId and SubscriptionName


```kusto
ResourceContainers
| where type =~ 'microsoft.resources/subscriptions'
| project subscriptionId, subscriptionName=name
```

## List ManagementGroupId and ManagementGroupName

```kusto
ResourceContainers
| where type =~ 'microsoft.management/managementgroups'
| project mgname = name, displayName = properties.displayName
```
## Policy assignments and information about each of its respective definitions displaying the scope of the assignment, the subscription display name, the management group id, the resource group name, the definition type, the assignment name, the category of the definition, and the policy assignment ID.

```kusto
policyResources
| where type =~'Microsoft.Authorization/PolicyAssignments'
| project policyAssignmentId = tolower(tostring(id)), policyAssignmentDisplayName = tostring(properties.displayName), policyAssignmentDefinitionId = tolower(properties.policyDefinitionId), subscriptionId = tostring(subscriptionId),resourceGroup=tostring(resourceGroup), AssignmentDefinition=properties
| join kind=leftouter(
    policyResources
    | where type =~'Microsoft.Authorization/PolicySetDefinitions' or type =~'Microsoft.Authorization/PolicyDefinitions'
    | project definitionId = tolower(id), category = tostring(properties.metadata.category), definitionType = iff(type =~ 'Microsoft.Authorization/PolicysetDefinitions', 'initiative', 'policy'),PolicyDefinition=properties
) on $left.policyAssignmentDefinitionId == $right.definitionId
| extend scope = iff(policyAssignmentId contains '/subscriptions/', 'Subscription', iff(policyAssignmentId contains '/providers/microsoft.management/managementgroups', 'Management Group', 'Resource Group'))
| join kind=leftouter (ResourceContainers
| where type =~ 'microsoft.resources/subscriptions'
| project subscriptionId, subscriptionName=name) on $left.subscriptionId == $right.subscriptionId
| extend SubscriptionDisplayName = iff(isnotempty(subscriptionId), subscriptionName, '')
| extend ManagementGroupName = iff(policyAssignmentId contains '/providers/microsoft.management/', split(policyAssignmentId, '/')[4],'')
| extend resourceGroupDisplayName = iff(isnotempty(resourceGroup), resourceGroup, '')
| project ManagementGroupName,SubscriptionDisplayName,resourceGroupDisplayName, scope,definitionType,policyAssignmentDisplayName, category,policyAssignmentId, AssignmentDefinition, PolicyDefinition
```

- [ ] Add Management Group Display Name