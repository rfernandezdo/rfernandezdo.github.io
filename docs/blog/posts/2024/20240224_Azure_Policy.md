---
draft: true
date: 2024-02-24
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure Policy
---
# Azure Policy

## What is Azure Policy ?

Azure Policy helps to enforce organizational standards and to assess compliance at-scale. Through its compliance dashboard, it provides an aggregated view to evaluate the overall state of the environment, with the ability to drill down to the per-resource, per-policy granularity. It also helps to bring your resources to compliance through bulk remediation for existing resources and automatic remediation for new resources.

Azure Policy implements governance for resources in Azure. It evaluates resources in Azure by comparing the properties of those resources to business rules, you can: 

- Enforce specific configurations on resources.
- Audit existing resources for compliance with business rules.
- Take actions when resources are not compliant with business rules. 

You have the following types of policies:

- Built-in policies: These are pre-configured policies that are available in the Azure portal. You can assign these policies directly to your resources.
- Custom policies: These are policies that you create to meet your specific governance needs. You can create custom policies in the Azure portal, using the Azure Policy REST API, or using the Azure CLI.


Policies are written in JSON and use the Azure Resource Manager policy definition schema. The schema defines the properties that are available for a policy definition. The schema also defines the structure of the policy rule, which is the logic that determines if a resource is compliant with the policy.

Policies can be assigned at the management group, subscription, or resource group level. When you assign a policy, it takes effect for all resources in the scope of the assignment. You can assign multiple policies to a scope, and the policies are applied in the order that you specify.

Policies can be grouped into initiatives. An initiative is a set of policies that are grouped together to address a specific scenario. Initiatives simplify the process of assigning policies to a scope. Instead of assigning each policy individually, you can assign an initiative, which assigns all the policies in the initiative.

[Azure Policy built-in policy definitions] (https://learn.microsoft.com/en-us/azure/governance/policy/samples/built-in-policies)






## Design considerations

## Pricing

Azure Policy is offered at no additional cost. You will be charged only for the underlying Azure resources consumed. For more information, see the [Azure Policy pricing page](https://azure.microsoft.com/en-us/pricing/details/azure-policy/). 

## Conclusion

Azure Policy serves as a powerful tool for implementing governance across your Azure environment. It helps ensure resource consistency, regulatory compliance, security, cost management, and efficient operations