---
draft: false
date: 2024-11-06
authors:
  - rfernandezdo
categories:
    - Azure Services
tags:
    - Azure Policy
---
# Trigger an on-demand Azure Policy compliance evaluation scan

Azure Policy is a service in Azure that you can use to create, assign, and manage policies that enforce different rules and effects over your resources. These policies can help you stay compliant with your corporate standards and service-level agreements. In this article, we will discuss how to trigger a scan with Azure Policy.

## What is a scan in Azure Policy

A scan in Azure Policy is a process that evaluates your resources against a set of policies to determine if they are compliant. When you trigger a scan, Azure Policy evaluates your resources and generates a compliance report that shows the results of the evaluation. The compliance report includes information about the policies that were evaluated, the resources that were scanned, and the compliance status of each resource.

You can trigger a scan in Azure Policy using the Azure CLI, PowerShell, or the Azure portal. When you trigger a scan, you can specify the scope of the scan, the policies to evaluate, and other parameters that control the behavior of the scan.

## Trigger a scan with the Azure CLI

To trigger a scan with the Azure CLI, you can use the `az policy state trigger-scan` command. This command triggers a policy compliance evaluation for a scope

How to trigger a scan with the Azure CLI for active subscription:

```azcli	
az policy state trigger-scan 
```

How to trigger a scan with the Azure CLI for a specific resource group:

```azcli
az policy state trigger-scan --resource-group myResourceGroup
```


## Trigger a scan with PowerShell

To trigger a scan with PowerShell, you can use the `Start-AzPolicyComplianceScan` cmdlet. This cmdlet triggers a policy compliance evaluation for a scope.

How to trigger a scan with PowerShell for active subscription:

```powershell
Start-AzPolicyComplianceScan
```

```powershell
$job = Start-AzPolicyComplianceScan -AsJob
```

How to trigger a scan with PowerShell for a specific resource group:

```powershell
Start-AzPolicyComplianceScan -ResourceGroupName 'MyRG'
```

## Conclusion

In this article, we discussed how to trigger a scan with Azure Policy. We covered how to trigger a scan using the Azure CLI and PowerShell. By triggering a scan, you can evaluate your resources against a set of policies to determine if they are compliant. This can help you ensure that your resources are compliant with your organization's standards and best practices.

## References

- [On-demand evaluation scan](https://learn.microsoft.com/en-us/azure/governance/policy/how-to/get-compliance-data#on-demand-evaluation-scan)  