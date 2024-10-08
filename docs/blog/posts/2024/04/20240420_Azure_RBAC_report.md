---
draft: false
date: 2024-04-20
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


##  Role assignment report in Excel

This is the PowerShell script that generates the role assignment reports:

```powershell
<#
.SYNOPSIS
A script to get role assignments for Azure subscriptions and management groups.

.DESCRIPTION
This script gets role assignments for specified or all Azure subscriptions and management groups,
and exports them to Excel files. It uses the ImportExcel module to create the Excel files.

.PARAMETER SubscriptionId
The ID of the Azure subscription. If not provided, the script gets role assignments for all subscriptions.

.PARAMETER ManagementGroupName
The name of the Azure management group. If not provided, the script gets role assignments for all management groups.

.PARAMETER GetSubscriptions
Specifies whether to get role assignments for subscriptions. Default is false.

.PARAMETER GetManagementGroups
Specifies whether to get role assignments for management groups. Default is true.

.EXAMPLE
.\get-azroleassigments.ps1 -SubscriptionId "sub-id"

This example gets role assignments for the specified subscription and management group.

.\get-azroleassigments.ps1 -ManagementGroupName "mg-name" -GetSubscriptions $true -GetManagementGroups $false

This example gets role assignments for the specified management group.

.\get-azroleassigments.ps1  -GetSubscriptions $true -GetManagementGroups $true

This example gets role assignments for all subscriptions and management groups.

.NOTES
You can not provide both SubscriptionId and GetSubscriptions parameters at the same time.
You can not provide both ManagementGroupName and GetManagementGroups parameters at the same time.

#>

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

# The rest of your script...

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

if ($GetManagementGroups) {
    # Check if ManagementGroupName is provided
    if ($ManagementGroupName) {
        # Get role assignments for the specified management group
        $roleAssignments = Get-AzRoleAssignment -Scope "/providers/Microsoft.Management/managementGroups/$ManagementGroupName"

        # Add these role assignments to the management group role assignments array
        $managementGroupRoleAssignments += $roleAssignments

        # Add 'GroupName' and 'IsInherited' properties to each role assignment object
        $roleAssignments | ForEach-Object {
            $_ | Add-Member -NotePropertyName 'GroupDisplayName' -NotePropertyValue (Get-AzManagementGroup -GroupName $ManagementGroupName).DisplayName
            $_ | Add-Member -NotePropertyName 'GroupName' -NotePropertyValue $ManagementGroupName
            # If the Scope of the role assignment is equal to the Id of the management group,
            # then the role assignment is not inherited; otherwise, it is inherited.
            if ($_.Scope -eq "/providers/Microsoft.Management/managementGroups/$ManagementGroupName") {
                $_ | Add-Member -NotePropertyName 'IsInherited' -NotePropertyValue $false
            } else {
                $_ | Add-Member -NotePropertyName 'IsInherited' -NotePropertyValue $true
            }
        }

        # Export the role assignments to a new sheet in the Excel file
        $roleAssignments | Export-Excel -Path $managementGroupPath -WorksheetName (Get-AzManagementGroup -GroupName $ManagementGroupName).DisplayName -AutoSize -AutoFilter
    } else {
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
    }
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
                if ($_.Scope -eq "/subscriptions/$($sub.SubscriptionId)") {
                    $_ | Add-Member -NotePropertyName 'IsInherited' -NotePropertyValue $false
                } else {
                    $_ | Add-Member -NotePropertyName 'IsInherited' -NotePropertyValue $true
                }
            }

            # Export the role assignments to a new sheet in the Excel file
            $roleAssignments | Export-Excel -Path $subscriptionPath -WorksheetName $sub.Name -AutoSize -AutoFilter
        }
    }
}
```

This script takes the following parameters:

- `GetSubscriptions`: A switch parameter that specifies whether to generate reports for subscriptions. The default value is `$false`.
- `GetManagementGroups`: A switch parameter that specifies whether to generate reports for management groups. The default value is `$true`.
- `SubscriptionId`: The ID of the subscription for which you want to generate the report. If this parameter is not provided, the script will generate reports for all subscriptions.
- `ManagementGroupName`: The name of the management group for which you want to generate the report. If this parameter is not provided, the script will generate reports for all management groups.

## Role definition report in Excel 1

You can also generate a report for role definitions in Azure using the following PowerShell script:

```powershell

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('Console', 'Excel')]
    [string]$OutputType = 'Console',

    [Parameter(Mandatory=$false)]
    [string]$ExcelFilePath = ".\AzRoleDefinition.xlsx"
)

# Install the ImportExcel module if not already installed
if (!(Get-Module -ListAvailable -Name ImportExcel)) {
    Install-Module -Name ImportExcel -Scope CurrentUser
}

# Install the  AzureRM module if not already installed
if (!(Get-Module -ListAvailable -Name  Az)) {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
    Install-Module -Name  Az -Scope CurrentUser
}

# Get all role definitions
$roleDefinitions = Get-AzRoleDefinition | ForEach-Object {
    # Create a custom object with ordered properties
    $customObject = New-Object PSObject -Property @{
        Name = $_.Name
        Id = $_.Id
        IsCustom = $_.IsCustom
        Description = $_.Description
        Actions = ($_.Actions -join ', ').Replace(',', ",`n")
        NotActions = ($_.NotActions -join ', ').Replace(',', ",`n")
        DataActions = ($_.DataActions -join ', ').Replace(',', ",`n")
        NotDataActions = ($_.NotDataActions -join ', ').Replace(',', ",`n")
        AssignableScopes = ($_.AssignableScopes -join ', ').Replace(',', ",`n")
    } | Select-Object Name, Id, IsCustom, Description, Actions, NotActions, DataActions, NotDataActions, AssignableScopes

    return $customObject
}

if ($OutputType -eq 'Console') {
    # Output to console
    $roleDefinitions | Format-Table -AutoSize
} else {
    # Export to Excel
    $roleDefinitions | Export-Excel -Path $ExcelFilePath -WorksheetName 'Role Definitions' -AutoSize -AutoFilter    
}
```

This script takes the following parameters:

- `OutputType`: A string parameter that specifies the output type. The default value is `'Console'`. You can also specify `'Excel'` to export the report to an Excel file.
- `ExcelFilePath`: The path to the Excel file where you want to export the report. The default value is `".\AzRoleDefinition.xlsx"`.

In the Excel report, you will see the following columns for each role definition: `Name`, `Id`, `IsCustom`, `Description`, `Actions`, `NotActions`, `DataActions`, `NotDataActions`, and `AssignableScopes`.

## Conclusion

In this article, we have shown you how to create reports for role assignments and role definitions in Azure using PowerShell and the ImportExcel module. These reports can help you better understand the permissions assigned to users, groups, and applications in your Azure environment and ensure that they are configured correctly. You can customize the scripts to include additional information or export the reports in different formats to suit your needs.

