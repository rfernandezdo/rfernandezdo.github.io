---
draft: false
date: 2024-04-28
authors:
  - rfernandezdo
categories:
    - DevOps
tags:
    - Terraform
---
# Terraform: Configuration Language

After deciding to use Terraform for my Infrastructure as Code (IaC) project,  Terraform configuration language must be understanded to define the desired state of my infrastructure.

!!! info
    I will update this post with more information about Terraform configuration language in the future.

Terraform uses a declarative configuration language to define the desired state of your infrastructure. This configuration language is designed to be human-readable and easy to understand, making it accessible to both developers and operations teams.

## Declarative vs. Imperative

Terraform's configuration language is declarative, meaning that you define the desired state of your infrastructure without specifying the exact steps needed to achieve that state. This is in contrast to imperative languages, where you specify the exact sequence of steps needed to achieve a desired outcome.

For example, in an imperative language, you might write a script that creates a virtual machine by executing a series of commands to provision the necessary resources. In a declarative language like Terraform, you would simply define the desired state of the virtual machine (e.g., its size, image, and network configuration) and let Terraform figure out the steps needed to achieve that state.

## Configuration Blocks

Terraform uses configuration blocks to define different aspects of your infrastructure. Each block has a specific purpose and contains configuration settings that define how that aspect of your infrastructure should be provisioned.

For example, you might use a `provider` block to define the cloud provider you want to use, a `resource` block to define a specific resource (e.g., a virtual machine or storage account), or a `variable` block to define input variables that can be passed to your configuration.

```hcl
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "East US"
}

variable "location" {
  type    = string
  default = "East US"
}
```

## Variables

Terraform allows you to define variables that can be used to parameterize your configuration. Variables can be used to pass values into your configuration, making it easier to reuse and customize your infrastructure definitions.

```hcl
variable "location" {
  type    = string
  default = "East US"
}

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = var.location
}
```

## locals

Terraform allows you to define local values that can be used within your configuration. Locals are similar to variables but are only available within the current module or configuration block.

```hcl
variable "location" {
  type    = string
  default = "East US"
}

locals {
  resource_group_name = "example-resources"
}

resource "azurerm_resource_group" "example" {
  name     = local.resource_group_name
  location = var.location
}
```
## Data Sources

Terraform allows you to define data sources that can be used to query external resources and retrieve information that can be used in your configuration. Data sources are read-only and can be used to fetch information about existing resources, such as virtual networks, storage accounts, or database instances.

```hcl
data "azurerm_resource_group" "example" {
  name = "example-resources"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  location            = data.azurerm_resource_group.example.location
  resource_group_name = data.azurerm_resource_group.example.name
}
```

## Functions

### try

The `try` function allows you to provide a default value in case an expression returns an error. This can be useful when working with optional values that may or may not be present.

```hcl
variable "optional_value" {
  type    = string
  default = null
}

locals {
  value = try(var.optional_value, "default_value")
}
```


## Debugging Terraform

You can use the `TF_LOG` environment variable to enable debug logging in Terraform. This can be useful when troubleshooting issues with your infrastructure or understanding how Terraform is executing your configuration.

```bash
export TF_LOG=DEBUG
terraform plan
```

TOu can use the following decreasing verbosity levels log:  TRACE, DEBUG, INFO, WARN or ERROR

To persist logged output logs in a file:

```bash
export TF_LOG_PATH="terraform.log"
```

To separare logs for Terraform and provider, you can use the following environment variables **TF_LOG_CORE** and **TF_LOG_PROVIDER** respectively. For example, to enable debug logging for both Terraform and the Azure provider, you can use the following environment variables:

```bash
export TF_LOG_CORE=DEBUG
export TF_LOG_PATH="terraform.log"

```

or 

```bash
export TF_LOG_PROVIDER=DEBUG
export TF_LOG_PATH="provider.log"
```	

To disable debug logging, you can unset the `TF_LOG` environment variable:

```bash
unset TF_LOG
```

## References

- [Terraform Configuration Language](https://www.terraform.io/docs/language/index.html)
- [Terraform Functions](https://www.terraform.io/docs/language/functions/index.html)
- [Terraform Debugging](https://www.terraform.io/docs/internals/debugging.html)
