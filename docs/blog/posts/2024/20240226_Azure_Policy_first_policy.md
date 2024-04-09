---
draft: false
date: 2024-02-26
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure Policy
---
# Writing Your First Policy in Azure with Portal

Azure Policy is a service in Azure that you use to create, assign and manage policies. These policies enforce different rules and effects over your resources, so those resources stay compliant with your corporate standards and service level agreements.

In this post, we'll walk through the steps of creating your first policy in Azure.

## Prerequisites
1. An active Azure subscription.
2. Access to Azure portal.

## Step 1: Open Azure Policy
- Login to the [Azure Portal](https://portal.azure.com/).
- In the left-hand menu, click on `All services`.
- In the `All services` blade, search for `Policy`.

## Step 2: Create a New Policy Definition
- Click on `Definitions` under the `Authoring` section.
- Click on `+ Policy definition`.

## Step 3: Fill Out the Policy Definition
You will need to fill out several fields:

- **Definition location**: The location where the policy is stored.
- **Name**: This is a unique name for your policy.
- **Description**: A detailed description of what the policy does.
- **Category**: You can categorize your policy for easier searching and filtering.

The most important part of the policy definition is the policy rule itself. The policy rule is where you describe the logic that enforces the policy. 

Here's an example of a simple policy rule that ensures all indexed resources have tags and deny creation or update if they do not.

```json
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

But, in portal, you can add properties directly in the form but you can't add displayName, policyType and metadata because they are added by portal itself, so you can add only mode,parameters and policyRule, Policy definition could be like this:

- Definition location: `Tenant Root Group`
- Name: `Require a tag and its value`
- Description: `This policy requires a specific tag and its value.`
- Category: `Tags`
- POLICY RULE:

```json
{

        "mode": "Indexed", 
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


Once you've filled out all the fields and written your policy rule, click on `Save`.

## Step 4: Assign the Policy
- Go back to the `Policy` service in the Azure portal.
- Click on `Assignments` under the `Authoring` section.
- Click on `+ Assign Policy`.
- In **Basics**, fill out the following fields:
    - **Scope**
        - **Scope**: Select the scope where you want to assign the policy.
        - **Exclusions**: Add any exclusions if needed.
    - **Basics**
        - **Policy definition**: Select the policy you created.
        - **Assignment name**: A unique name for the assignment.
        - **Description**: A detailed description of the assignment.
        - **Policy enforcement**: `Enabled`.
- In **Parameters**: Fill out any parameters needed for the policy.
- In **Non-compliance message**: A message to display when a resource is non-compliant.
- Click on `Review + create`: Review the assignment and click on `Create`.



Congratulations! You've just created and assigned your first policy in Azure. It will now evaluate any new or existing resources within its scope.

Remember, Azure Policy is a powerful tool for maintaining compliance and managing your resources at scale. Happy coding!