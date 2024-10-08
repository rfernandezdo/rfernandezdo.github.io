---
draft: false
date: 2024-10-03
authors:
  - rfernandezdo
categories:
    - DevOps


tags:
    - terraform
---

# terraform import block

Sometimes you need to import existing infrastructure into Terraform. This is useful when you have existing resources that you want to manage with Terraform, or when you want to migrate from another tool to Terraform.

Other times, you may need to import resources that were created outside of Terraform, such as manually created resources or resources created by another tool. For example: 

"Error: unexpected status 409 (409 Conflict) with error: RoleDefinitionWithSameNameExists: A custom role with the same name already exists in this directory. Use a different name"


In my case, I had to import a custom role that was created outside of Terraform. Here's how I did it:

1. Create a new Terraform configuration file for the resource you want to import. In my case, I created a new file called `custom_role.tf` with the following content:

```hcl
resource "azurerm_role_definition" "custom_role" {
  name        = "CustomRole"
  scope       = "/providers/Microsoft.Management/managementGroups/00000000-0000-0000-0000-000000000000"
  permissions {
    actions     = [
      "Microsoft.Storage/storageAccounts/listKeys/action",
      "Microsoft.Storage/storageAccounts/read"
    ]
    
    data_actions = []

    not_data_actions = []
  }
  assignable_scopes = [
    "/providers/Microsoft.Management/managementGroups/00000000-0000-0000-0000-000000000000"
  ]
}
```

2. Add a import block to the configuration file with the resource type and name you want to import. In my case, I added the following block to the `custom_role.tf` file:

```hcl
import {
  to = azurerm_role_definition.custom_role
  id = "/providers/Microsoft.Authorization/roleDefinitions/11111111-1111-1111-1111-111111111111|/providers/Microsoft.Management/managementGroups/00000000-0000-0000-0000-000000000000"
  
}
```


3. Run the `terraform `plan` command to see the changes that Terraform will make to the resource. In my case, the output looked like this:

```bash
.
.
.
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  ~ update in-place
.
.
.
```

4. Run the `terraform apply` command to import the resource into Terraform. In my case, the output looked like this after a long 9 minutes:

```bash
...
Apply complete! Resources: 1 imported, 0 added, 1 changed, 0 destroyed.
```

5. Verify that the resource was imported successfully by running the `terraform show` command. In my case, the output looked like this:

```bash
terraform show
```


You can use the `terraform import` command to import existing infrastructure into Terraform too but I prefer to use the `import` block because it's more readable and easier to manage.

With terraform import the command would look like this:

```bash
terraform import azurerm_role_definition.custom_role "/providers/Microsoft.Authorization/roleDefinitions/11111111-1111-1111-1111-111111111111|/providers/Microsoft.Management/managementGroups/00000000-0000-0000-0000-000000000000"
```


## Conclusion

That's it! You've successfully imported an existing resource into Terraform. Now you can manage it with Terraform just like any other resource.

Happy coding! 🚀




