---
draft: false
date: 2024-10-04
authors:
  - rfernandezdo
categories:
    - Azure Services

tags:
    - Azure RBAC
    - Terraform
    
---

# How to check if a role permission is good or bad in Azure RBAC

Do you need to check if a role permission is good or bad or just don't know what actions a provider has in Azure RBAC?

Get-AzProviderOperation * is your friend and you can always export everything to csv:

```powershell
Get-AzProviderOperation | select Operation , OperationName , ProviderNamespace , ResourceName , Description , IsDataAction | Export-csv AzProviderOperation.csv
```

This command will give you a list of all the operations that you can perform on Azure resources, including the operation name, provider namespace, resource name, description, and whether it is a data action or not. You can use this information to check if a role permission is good or bad, or to find out what actions a provider has in Azure RBAC.

## Script to check if a role permission is good or bad on tf files

You can use the following script to check if a role permission is good or bad on tf files:

```powershell
<#
.SYNOPSIS
Script to check if a role permission is good or bad in Azure RBAC using Terraform files.

.DESCRIPTION
This script downloads Azure provider operations to a CSV file, reads the CSV file, extracts text from Terraform (.tf and .tfvars) files, and compares the extracted text with the CSV data to find mismatches.

.PARAMETER csvFilePath
The path to the CSV file where Azure provider operations will be downloaded.

.PARAMETER tfFolderPath
The path to the folder containing Terraform (.tf and .tfvars) files.

.PARAMETER DebugMode
Switch to enable debug mode for detailed output.

.EXAMPLE
.\Check-RBAC.ps1 -csvFilePath ".\petete.csv" -tfFolderPath ".\"

.EXAMPLE
.\Check-RBAC.ps1 -csvFilePath ".\petete.csv" -tfFolderPath ".\" -DebugMode

.NOTES
For more information, refer to the following resources:
- Azure RBAC Documentation: https://docs.microsoft.com/en-us/azure/role-based-access-control/
- Get-AzProviderOperation Cmdlet: https://docs.microsoft.com/en-us/powershell/module/az.resources/get-azprovideroperation
- Export-Csv Cmdlet: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/export-csv
#>

param(
    [string]$csvFilePath = ".\petete.csv",
    [string]$tfFolderPath = ".\",
    [switch]$DebugMode
)

# Download petete.csv using Get-AzProviderOperation
function Download-CSV {
    param(
        [string]$filename,
        [switch]$DebugMode
    )
    if ($DebugMode) { Write-Host "Downloading petete.csv using Get-AzProviderOperation" }
    Get-AzProviderOperation | select Operation, OperationName, ProviderNamespace, ResourceName, Description, IsDataAction | Export-Csv -Path $filename -NoTypeInformation
    if ($DebugMode) { Write-Host "CSV file downloaded: $filename" }
}

# Function to read the CSV file
function Read-CSV {
    param(
        [string]$filename,
        [switch]$DebugMode
    )
    if ($DebugMode) { Write-Host "Reading CSV file: $filename" }
    $csv = Import-Csv -Path $filename
    $csvData = $csv | ForEach-Object {
        [PSCustomObject]@{
            Provider = $_.Operation.Split('/')[0].Trim()
            Operation = $_.Operation
            OperationName = $_.OperationName
            ProviderNamespace = $_.ProviderNamespace
            ResourceName = $_.ResourceName
            Description = $_.Description
            IsDataAction = $_.IsDataAction
        }
    }
    if ($DebugMode) { Write-Host "Data read from CSV:"; $csvData | Format-Table -AutoSize }
    return $csvData
}

# Function to extract text from the Terraform files
function Extract-Text-From-TF {
    param(
        [string]$folderPath,
        [switch]$DebugMode
    )
    if ($DebugMode) { Write-Host "Reading TF and TFVARS files in folder: $folderPath" }
    $tfTexts = @()
    $files = Get-ChildItem -Path $folderPath -Filter *.tf,*.tfvars
    foreach ($file in $files) {
        $content = Get-Content -Path $file.FullName
        $tfTexts += $content | Select-String -Pattern '"Microsoft\.[^"]*"' -AllMatches | ForEach-Object { $_.Matches.Value.Trim('"').Trim() }
        $tfTexts += $content | Select-String -Pattern '"\*"' -AllMatches | ForEach-Object { $_.Matches.Value.Trim('"').Trim() }
        $tfTexts += $content | Select-String -Pattern '^\s*\*/' -AllMatches | ForEach-Object { $_.Matches.Value.Trim() }
    }
    if ($DebugMode) { Write-Host "Texts extracted from TF and TFVARS files:"; $tfTexts | Format-Table -AutoSize }
    return $tfTexts
}

# Function to compare extracted text with CSV data
function Compare-Text-With-CSV {
    param(
        [array]$csvData,
        [array]$tfTexts,
        [switch]$DebugMode
    )
    $mismatches = @()
    foreach ($tfText in $tfTexts) {
        if ($tfText -eq "*" -or $tfText -match '^\*/') {
            continue
        }
        $tfTextPattern = $tfText -replace '\*', '.*'
        if (-not ($csvData | Where-Object { $_.Operation -match "^$tfTextPattern$" })) {
            $mismatches += $tfText
        }
    }
    if ($DebugMode) { Write-Host "Mismatches found:"; $mismatches | Format-Table -AutoSize }
    return $mismatches
}

# Main script execution
Download-CSV -filename $csvFilePath -DebugMode:$DebugMode
$csvData = Read-CSV -filename $csvFilePath -DebugMode:$DebugMode
$tfTexts = Extract-Text-From-TF -folderPath $tfFolderPath -DebugMode:$DebugMode
$mismatches = Compare-Text-With-CSV -csvData $csvData -tfTexts $tfTexts -DebugMode:$DebugMode

if ($mismatches.Count -eq 0) {
    Write-Host "All extracted texts match the CSV data."
} else {
    Write-Host "Mismatches found:"
    $mismatches | Format-Table -AutoSize
}
```

This script downloads Azure provider operations to a CSV file, reads the CSV file, extracts text from Terraform files, and compares the extracted text with the CSV data to find mismatches. You can use this script to check if a role permission is good or bad in Azure RBAC using Terraform files.

I hope this post has given you a good introduction to how you can check if a role permission is good or bad in Azure RBAC and how you can use Terraform files to automate this process. 

Happy coding! 🚀

