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

# How to create assigment Reports for Azure RBAC

Role-Based Access Control (RBAC) is a key feature of Azure that allows you to manage access to Azure resources. With RBAC, you can grant permissions to users, groups, and applications at a certain scope, such as a subscription, resource group, or resource. RBAC uses role assignments to determine what actions a user, group, or application can perform on a resource.

In this article, we will show you how to create reports for role assignments in Azure using PowerShell and the ImportExcel module. We will generate separate Excel files for role assignments at the subscription and management group levels, including information such as the role, principal, scope, and whether the assignment is inherited.

This is the PowerShell script that generates the role assignment reports:

```powershell
# Parameters setup
param (
    [Parameter(Mandatory=$false)]
    [string]$SubscriptionId,

    [Parameter(Mandatory=$false)]
    [string]$ManagementGroupName,

    [Parameter(Mandatory=$false)]
    [bool]$GetSubscriptions = $false,

    [Parameter(Mandatory=$false)]
    [bool]$GetManagementGroups = $true
)


# Install the ImportExcel module if not already installed
if (!(Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Scope CurrentUser
}

# Define the path to your Excel file for Managing Group role assignments
$managementGroupPath = ".\AzRoleAssignmentMg.xlsx"
# Define the path to your Excel file for Subscription role assignments
$subscriptionPath = ".\AzRoleAssignmentSub.xlsx"

# Initialize an empty array to hold all role assignments
$subscriptionRoleAssignments = @()
$managementGroupRoleAssignments = @()

# Get all management groups
$managementGroups = Get-AzManagementGroup

# Loop through each management group
foreach ($mg in $managementGroups) {
    # Get role assignments for the current management group
    $roleAssignments = Get-AzRoleAssignment -Scope "/providers/Microsoft.Management/managementGroups/$($mg.Name)"

    # Add these role assignments to the management group role assignments array
    $managementGroupRoleAssignments += $roleAssignments

    # Add 'GroupName' and 'IsInherited' properties to each role assignment object
    $roleAssignments | ForEach-Object { 
        $_ | Add-Member -NotePropertyName 'GroupDisplayName' -NotePropertyValue $mg.DisplayName
        $_ | Add-Member -NotePropertyName 'GroupName' -NotePropertyValue $mg.Name 
        # If the Scope of the role assignment is equal to the Id of the management group,
        # then the role assignment is not inherited; otherwise, it is inherited.
        if ($_.Scope -eq $mg.Id) {
            $_ | Add-Member -NotePropertyName 'IsInherited' -NotePropertyValue $false
        } else {
            $_ | Add-Member -NotePropertyName 'IsInherited' -NotePropertyValue $true
        }
    }

    # Export the role assignments to a new sheet in the Excel file
    $roleAssignments | Export-Excel -Path $managementGroupPath -WorksheetName $mg.DisplayName -AutoSize -AutoFilter
}

if ($GetSubscriptions) {   
    # Check if SubscriptionId is provided
    if ($SubscriptionId) {
        # Get role assignments for the specified subscription
        $roleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$SubscriptionId"

        # Add these role assignments to the subscription role assignments array
        $subscriptionRoleAssignments += $roleAssignments

        # Add 'SubscriptionName' and 'IsInherited' properties to each role assignment object
        $roleAssignments | ForEach-Object { 
            $_ | Add-Member -NotePropertyName 'SubscriptionName' -NotePropertyValue (Get-AzSubscription -SubscriptionId $SubscriptionId).Name 
            $_ | Add-Member -NotePropertyName 'IsInherited' -NotePropertyValue $false
        }

        # Export the role assignments to a new sheet in the Excel file
        $roleAssignments | Export-Excel -Path $subscriptionPath -WorksheetName (Get-AzSubscription -SubscriptionId $SubscriptionId).Name -AutoSize -AutoFilter
    } else {
        # Get all subscriptions
        $subscriptions = Get-AzSubscription

        # Loop through each subscription
        foreach ($sub in $subscriptions) {
            # Get role assignments for the current subscription
            $roleAssignments = Get-AzRoleAssignment -Scope "/subscriptions/$($sub.SubscriptionId)"

            # Add these role assignments to the subscription role assignments array
            $subscriptionRoleAssignments += $roleAssignments

            # Add 'SubscriptionName' and 'IsInherited' properties to each role assignment object
            $roleAssignments | ForEach-Object { 
                $_ | Add-Member -NotePropertyName 'SubscriptionName' -NotePropertyValue $sub.Name
                 # If the Scope of the role assignment is equal to the subscription Id,
                 # then the role assignment is not inherited; otherwise, it is inherited.
                if ($_.Scope -eq "/subscriptions/$($sub.Id)") {
                    $_ | Add-Member -NotePropertyName 'IsInherited' -NotePropertyValue $false
                } else {
                    $_ | Add-Member -NotePropertyName 'IsInherited' -NotePropertyValue $true                }
                
            }

            # Export the role assignments to a new sheet in the Excel file
            $roleAssignments | Export-Excel -Path $subscriptionPath -WorksheetName $sub.Name -AutoSize -AutoFilter
        }
    }
}
```