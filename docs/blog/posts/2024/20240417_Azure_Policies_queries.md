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


