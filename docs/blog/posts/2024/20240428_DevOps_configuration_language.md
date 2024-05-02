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

!!! info
    I will update this post with more information about Terraform configuration language in the future.

Terraform uses a declarative configuration language to define the desired state of your infrastructure. This configuration language is designed to be human-readable and easy to understand, making it accessible to both developers and operations teams.

## Declarative vs. Imperative

Terraform's configuration language is declarative, meaning that you define the desired state of your infrastructure without specifying the exact steps needed to achieve that state. This is in contrast to imperative languages, where you specify the exact sequence of steps needed to achieve a desired outcome.

For example, in an imperative language, you might write a script that creates a virtual machine by executing a series of commands to provision the necessary resources. In a declarative language like Terraform, you would simply define the desired state of the virtual machine (e.g., its size, image, and network configuration) and let Terraform figure out the steps needed to achieve that state.

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
