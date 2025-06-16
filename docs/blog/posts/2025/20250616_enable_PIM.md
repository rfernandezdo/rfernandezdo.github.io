---
draft: false
date: 2025-06-16
authors:
  - rfernandezdo
categories:
  - Microsoft Entra
tags:
  - Microsoft Entra Privileged Identity Management
---
# Streamline Your Workflow: Activate All Your PIM Roles with a Single Script Using the JAz.PIM Module

For professionals working with Azure, Privileged Identity Management (PIM) is a cornerstone of robust security hygiene. PIM enables just-in-time access to privileged roles, but manually activating multiple roles each morning can quickly become a repetitive and time-consuming task.

Fortunately, the PowerShell community provides powerful tools to automate such processes. This article introduces a script leveraging the **`JAz.PIM`** module, an excellent solution developed by [Justin Grote](https://github.com/JustinGrote/), to simplify and accelerate role activation.

While the script is straightforward, its effectiveness is remarkable.

```powershell
# Check if the JAz.PIM module is installed; if not, install it
if (-not (Get-module -ListAvailable -Name JAz.PIM)) {
    Install-Module -Name JAz.PIM -Force -Scope CurrentUser
}

# Import the JAz.PIM module if it is not already loaded in the session
if (-not (Get-module -Name JAz.PIM)) {
    Import-module JAz.PIM
}

# Verify Azure login status; if not logged in, initiate login
if (-not (Get-AzContext)) {
    Connect-AzAccount
}

# Set the default activation duration for roles to 8 hours
$PSDefaultParameterValues['Enable-JAz*Role:Hours'] = 8

# Retrieve and activate all eligible roles (Azure Resource and/or Azure AD roles)
Get-JAzRole | Enable-JAzRole -Justification "Administrative task"
```

This script ensures the `JAz.PIM` module is installed, connects to Azure if necessary, and activates all your eligible roles in a single command.

Key components:
* `Get-JAzRole`: This cmdlet from the `JAz.PIM` module retrieves all roles for which you are eligible.
* `Enable-JAzRole`: This command processes each role in the list, submitting an activation request with the specified justification.

Notably, **`JAz.PIM` can manage both Azure Resource roles (Owner, Contributor, etc.) and Azure AD roles (Global Administrator, etc.)**.

## Conclusion

Automation is essential for optimizing daily administrative tasks. This script, powered by the community-driven `JAz.PIM` module, exemplifies how a manual, repetitive process can be transformed into a quick and efficient command. Adopting such tools not only saves time but also helps maintain PIM security best practices with minimal friction.

If you found this article helpful, consider sharing it with your colleagues and continue exploring the capabilities of PowerShell and Azure. Your time is valuable—make every second count.

For more information about the `JAz.PIM` module, visit its [GitHub repository](https://github.com/JustinGrote/JAz.PIM).
