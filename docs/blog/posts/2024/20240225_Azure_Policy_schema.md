---
draft: false
date: 2024-02-25
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure Policy
---
# Azure Policy, defintion schema

This is the schema for the Azure Policy definition:

``` json
{
    "properties": {
        "displayName": {
            "type": "string",
            "description": "The display name of the policy definition."
        },
        "policyType": {
            "type": "string",
            "description": "The policy type of the policy definition."
        },
        "mode": {
            "type": "string",
            "description": "The mode of the policy definition."
        },
        "description": {
            "type": "string",
            "description": "The description of the policy definition."
        },
        "mode": {
            "type": "string",
            "description": "The mode of the policy definition."
        },
        "metadata": {
            "type": "object",
            "description": "The metadata of the policy definition."
        },
        "parameters": {
            "type": "object",
            "description": "The parameters of the policy definition."
        },
        "policyRule": {
            "type": "object",
            "description": "The policy rule of the policy definition. If/then rule."
        }       
        
    }
}
```

You can see other elements in the schema like id, type, and name, It's depens of how you want to deploy the policy definition.

Full schema is in [Azure Policy definition schema](https://schema.management.azure.com/schemas/2020-10-01/policyDefinition.json).

## Example

Here is an example of a policy definition:

``` json
{
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
        "policyRule": {
            "if": {
                "field": "[concat('tags[', parameters('tagName'), ']')]",
                "exists": "false"
            },
            "then": {
                "effect": "deny"
            }
        }
    }
}
```

This policy definition requires a specific tag and its value. If the tag does not exist, the policy denies the action.

How you can see, the most important part of the policy definition is the policy rule. 

!!! Note
    The policy rule is where you describe the logic that enforces the policy.


## Conclusion

Understanding the schema for Azure Policy definitions is essential for creating and managing policies effectively. By defining the necessary attributes and rules, you can enforce compliance, security, and operational standards across your Azure environment. Leveraging the Azure Policy definition schema allows you to tailor policies to your organization's specific requirements and ensure consistent governance practices.

## References

- [Azure Policy definition schema](https://schema.management.azure.com/schemas/2020-10-01/policyDefinition.json)
- [Azure Policy](https://learn.microsoft.com/en-us/azure/governance/policy/overview)
