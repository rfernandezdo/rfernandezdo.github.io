---
draft: false
date: 2024-02-28
authors:
  - rfernandezdo
categories:
  - Tools
tags:
  - Azure Policy      
---
## Manage Azure Policy GitHub Action

### Overview

The **Manage Azure Policy** GitHub Action empowers you to enforce organizational standards and assess compliance at scale using Azure policies. With this action, you can seamlessly integrate policy management into your CI/CD pipelines, ensuring that your Azure resources adhere to the desired policies.

!!! Info
    This project does not have received any updates since some time, but it is still a simple option to develop your Azure Policies.
    As everything cannot be good to say that this deployment method has a major drawback, deletions must be done by hand :S

### Key Features

1. **Customizable Workflows**: GitHub workflows are highly customizable. You have complete control over the sequence in which Azure policies are rolled out. This flexibility enables you to follow safe deployment practices and catch regressions or bugs well before policies are applied to critical resources.

2. **Azure Login Integration**: The action assumes that you've already authenticated using the **Azure Login** action. Make sure you've logged in using an Azure service principal with sufficient permissions to write policies on selected scopes. Refer to the [full documentation of Azure Login Action](https://github.com/MicrosoftDocs/azure-docs/blob/main/articles/cost-management-billing/manage/ea-azure-marketplace.md) for details on permissions.

3. **Policy File Structure**: Your policy files should be organized in a specific directory structure within your GitHub repository. Here's how it should look:

    ```
    |- policies/
       |- <policy1_name>/
          |- policy.json
          |- assign.<name1>.json
          |- assign.<name2>.json
          ...
       |- <policy2_name>/
          |- policy.json
          |- assign.<name1>.json
          |- assign.<name2>.json
          ...
    ```

    - Each policy resides in a subfolder under the `policies/` directory.
    - The `policy.json` file contains the policy definition.
    - Assignment files (e.g., `assign.<name1>.json`) specify how the policy is applied.

4. **Inputs for the Action**:
    - **Paths**: Specify the mandatory path(s) to the directory containing your Azure policy files.

### Sample Workflow

Here's an example of how you can apply policies at the Management Group scope using the **Manage Azure Policy** action:

```yaml
name: 'Test Policy'
on:
  push:
    branches: 
    - "*" 
    paths: 
     - 'policies/**'
     - 'initiatives/**'
  workflow_dispatch:

jobs:
  apply-azure-policy:    
    runs-on: ubuntu-latest
    steps:
    # Azure Login
    - name: Login to Azure
      uses: azure/login@v1
      with:
        creds: ${{ secrets.AZURE_CREDENTIALS }}
        allow-no-subscriptions: true

    - name: Checkout
      uses: actions/checkout@v2 

    - name: Create or Update Azure Policies
      uses: azure/manage-azure-policy@v0
      with:      
        paths:  |                
          policies/**
          initiatives/**
        assignments:  |
          assign.*_testRG_*.json
```

Remember to replace the placeholder values (such as `secrets.AZURE_CREDENTIALS`) with your actual configuration.


### Example of use for Policy

In this example we define all our policies and initiatives at root management group level and assign to resource group, and we have a policy that requires a specific tag and its value.

You need to create a folder structure like this:

```

|- policies/
   |- require-tag-and-its-value/
      |- policy.json
      |- assign.testRG_testazurepolicy.json
|- initiatives/
   |- initiative1/
      |- policyset.json
      |- assign.testRG_testazurepolicy.json
```



#### policies

!!! info
    - The `policy.json` file contains the policy definition, and the `assign.<name>.json` file specifies how the policy is applied.  
 

##### policy.json

!!! info
    - The `id` value specifies where you are going to define the policy.

```json title=policy.json
{
    "id": "/providers/Microsoft.Management/managementGroups/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyDefinitions/requite-tag-and-its-value",
    "type": "Microsoft.Authorization/policyDefinitions",
    "name": "requite-tag-and-its-value",
    "properties": {
        "displayName": "Require a tag and its value",
        "policyType": "Custom",
        "mode": "Indexed",
        "description": "This policy requires a specific tag and its value.",
        "metadata": {
            "category": "Tags"
        },
        "parameters": {
            "tagName": {
                "type": "String",
                "metadata": {
                    "displayName": "Tag Name",
                    "description": "Name of the tag, such as 'environment'"
                }
            },
            "tagValue": {
                "type": "String",
                "metadata": {
                    "displayName": "Tag Value",
                    "description": "Value of the tag, such as 'production'"
                }
            }
        },
        },
        "policyRule": {
            "if": {
                "not": {
                    "field": "[concat('tags[', parameters('tagName'), ']')]",
                    "equals": "[parameters('tagValue')]"
                    }
                },
            "then": {
                "effect": "deny"
            }
        }
    }
```

##### assign.testRG_testazurepolicy.json

!!! info
    - Change the `id` and `scope` values in the `assign.<name>.json` file to match your Azure subscription and resource group.
    - id specifies where you are going to deploy the assignment.
    - id and name are related, name can not be any value, it should be the same as the last part of the id. You can generete a new GUID and use it as name with (1..24 | %{ '{0:x}' -f (Get-Random -Max 16) }) -join ''
    - name and id are related.
    - The `policyDefinitionId` value should match the `id` value in the `policy.json` file.

```json title=assign.testRG_testazurepolicy.json
{
    "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-testazurepolicy/providers/Microsoft.Authorization/policyAssignments/599a2c3a1a3b1f8b8e547b3e",
    "type": "Microsoft.Authorization/policyAssignments",
    "name": "599a2c3a1a3b1f8b8e547b3e",     
    "properties": {
        "description": "This policy audits the presence of a specific tag and its value.",
        "displayName": "Require a tag and its value",
        "parameters": {
            "effect": {
              "value": "Deny"
            }
          },
          "nonComplianceMessages": [
            {
              "message": "This resource is not compliant with the policy. Please apply the required tag and its value."
            }
          ],
          "enforcementMode": "Default",
          "policyDefinitionId": "/providers/Microsoft.Management/managementGroups/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyDefinitions/requite-tag-and-its-value",
          "scope": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-testazurepolicy"
    }    
}
```

#### initiatives

!!! info
    - The `policyset.json` file contains the policy definition, and the `assign.<name>.json` file specifies how the initiative is applied.

##### policyset.json

!!! info 
    - The `id` value specifies where you are going to define the initiative.
    - The `policyDefinitions` array contains the policy definitions that are part of the initiative.
    - The `parameters` object defines the parameters that can be passed to the policies within the initiative.
    - The `policyDefinitionId` value should match the `id` value in the `policy.json` file of the policy.

```json title=policyset.json
{
    "id": "/providers/Microsoft.Management/managementGroups/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policySetDefinitions/initiative1",
    "type": "Microsoft.Authorization/policySetDefinitions",
    "name": "initiative1",
    "properties": {
        "displayName": "Initiative 1",
        "description": "This initiative contains a set of policies for testing.",
        "metadata": {
            "category": "Test"
        },
        "parameters": {
            "tagName": {
                "type": "String",
                "metadata": {
                    "displayName": "Tag Name",
                    "description": "Name of the tag, such as 'environment'"
                }
            },
            "tagValue": {
                "type": "String",
                "metadata": {
                    "displayName": "Tag Value",
                    "description": "Value of the tag, such as 'production'"
                }
            }
        },
        "policyDefinitions": [
            {
                "policyDefinitionId": "/providers/Microsoft.Management/managementGroups/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policyDefinitions/requite-tag-and-its-value",
                "parameters": {
                    "tagName": {
                        "value": "[parameters('tagName')]"
                    },
                    "tagValue": {
                        "value": "[parameters('tagValue')]"
                    }
                }
            }
        ]
    }
}
```
##### assign.testRG_testazurepolicyset.json

```json title=assign.testRG_testazurepolicyset.json
{
    "id": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-testazurepolicy/providers/Microsoft.Authorization/policyAssignments/ada0f4a34b09cf6ad704cc62",
    "type": "Microsoft.Authorization/policyAssignments",
    "name": "ada0f4a34b09cf6ad704cc62",     
    "properties": {
        "description": "This initiative audits the presence of a specific tag and its value.",
        "displayName": "Require a tag and its value",
        "parameters": {
            "effect": {
              "value": "Deny"
            }
          },
          "nonComplianceMessages": [
            {
              "message": "This resource is not compliant with the policy. Please apply the required tag and its value."
            }
          ],
          "enforcementMode": "Default",
          "policyDefinitionId": "/providers/Microsoft.Management/managementGroups/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/policySetDefinitions/requite-tag-and-its-value",
          "scope": "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-testazurepolicy"
    }    
}
```

### Conclusion

By incorporating the **Manage Azure Policy** action into your GitHub workflows, you can seamlessly enforce policies, maintain compliance, and ensure the robustness of your Azure resources, although it has its drawbacks, it is one more step compared to a portal. Later we will see the deployment with a more robust tool: EPAC

Learn more about [Azure Policies](https://docs.microsoft.com/en-us/azure/governance/policy/overview) and explore the action on the [GitHub Marketplace](https://github.com/marketplace/actions/manage-azure-policy).

