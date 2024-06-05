---
draft: false
date: 2024-05-02
authors:
  - rfernandezdo
categories:
    - DevOps
tags:
    - IaC
    - Terraform
    - OpenTofu
---
# Nested Structures with Optional Attributes and Dynamic Blocks

In this post, I will explain how to define nested structures with optional attributes and it's use dynamic blocks in Terraform.

## Nested Structures

Terraform allows you to define nested structures to represent complex data types in your configuration. Nested structures are useful when you need to group related attributes together or define a data structure that contains multiple fields.

For example, you might define a nested structure to represent a virtual machine with multiple attributes, such as size, image, and network configuration:

```hcl
variable "vm" {
  type = object({
    size     = string
    image    = string
    network  = object({
      subnet = string
      security_group = string
    })
  })
}

resource "azurerm_virtual_machine" "example" {
  name     = "example-vm"
  size     = var.vm.size
  image    = var.vm.image
  subnet   = var.vm.network.subnet
  security_group = var.vm.network.security_group
}
```

In this example, the `vm` variable defines a nested structure with three attributes: `size`, `image`, and `network`. The `network` attribute is itself a nested structure with two attributes: `subnet` and `security_group`.

## Optional Attributes

Terraform allows you to define optional attributes in your configuration by setting the attribute's type to `any` and using the `default` argument to specify a default value. Optional attributes are useful when you want to provide a default value for an attribute but allow users to override it if needed.

For example, you might define an optional attribute for the `security_group` in the `network` structure:

```hcl

variable "vm" {
  type = object({
    size     = string
    image    = string
    network  = object({
      subnet = string
      security_group = string
    })
  })
}


resource "azurerm_virtual_machine" "example" {
  name     = "example-vm"
  size     = var.vm.size
  image    = var.vm.image
  subnet   = var.vm.network.subnet
  security_group = var.vm.network.security_group
}
```

In this example, the `security_group` attribute in the `network` structure is defined as an optional attribute with a default value of `null`. This allows users to provide a custom security group if needed, or use the default value if no value is provided.

## Dynamic Blocks

Terraform allows you to use dynamic blocks to define multiple instances of a block within a resource or module. Dynamic blocks are useful when you need to create multiple instances of a block based on a list or map of values.

For example, you might use a dynamic block to define multiple network interfaces for a virtual machine:

```hcl

variable "network_interfaces" {
  type = list(object({
    name    = string
    subnet  = string
    security_group = string
  }))
}

resource "azurerm_virtual_machine" "example" {
  name     = "example-vm"
  size     = "Standard_DS1_v2"
  image    = "UbuntuServer"
  
  dynamic "network_interface" {
    for_each = var.network_interfaces
    content {
      name            = network_interface.value.name
      subnet          = network_interface.value.subnet
      security_group  = network_interface.value.security_group
    }
  }
}
```


In this example, the `network_interfaces` variable defines a list of objects representing network interfaces with three attributes: `name`, `subnet`, and `security_group`. The dynamic block iterates over the list of network interfaces and creates a network interface block for each object in the list.

## Conclusion

In this post, I explained how to define nested structures with optional attributes and use dynamic blocks in Terraform. Nested structures are useful for representing complex data types, while optional attributes allow you to provide default values for attributes that can be overridden by users. Dynamic blocks are useful for creating multiple instances of a block based on a list or map of values. By combining these features, you can create flexible and reusable configurations in Terraform.
