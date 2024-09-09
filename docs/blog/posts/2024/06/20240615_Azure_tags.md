---
draft: false
date: 2024-06-15
authors:
  - rfernandezdo
categories:
    - Azure Services

tags:
    - Azure Tags
    
---

# Tagging best practices in Azure

In this post, I will show you some best practices for tagging resources in Azure.

## What are tags?

Tags are key-value pairs that you can assign to your Azure resources to organize and manage them more effectively. Tags allow you to categorize resources in different ways, such as by environment, owner, or cost center, and to apply policies and automation based on these categories.

If you don't know anything about tags, you can read the [official documentation](https://docs.microsoft.com/en-us/azure/azure-resource-manager/management/tag-resources) to learn more about them.

## Why use tags?

There are several reasons to use tags:

- **Organization**: Tags allow you to organize your resources in a way that makes sense for your organization. You can use tags to group resources by environment, project, or department, making it easier to manage and monitor them.

- **Cost management**: Tags allow you to track and manage costs more effectively. You can use tags to identify resources that are part of a specific project or department, and to allocate costs accordingly.

- **Automation**: Tags allow you to automate tasks based on resource categories. You can use tags to apply policies, trigger alerts, or enforce naming conventions, making it easier to manage your resources at scale.

## Best practices for tagging resources in Azure

Here are some best practices for tagging resources in Azure:

- **Use consistent naming conventions**: Define a set of standard tags that you will use across all your resources. This will make it easier to search for and manage resources, and to apply policies and automation consistently.

- **Apply tags at resource creation**: Apply tags to resources when you create them, rather than adding them later. This will ensure that all resources are tagged correctly from the start, and will help you avoid missing or incorrect tags.

- **Use tags to track costs**: Use tags to track costs by project, department, or environment. This will help you allocate costs more effectively, and will make it easier to identify resources that are not being used or are costing more than expected.

- **Define tags by hierarchy**: Define tags in a hierarchy that makes sense for your organization, from more general at level subscription to more specific at resource group level. 

- **Use inherited tags**: Use inherited tags to apply tags to resources automatically based on their parent resources. This will help you ensure that all resources are tagged consistently, and will reduce the risk of missing or incorrect tags. Exist Azure Policy to enforce inherited tags for example, you can check all in   [Assign policy definitions for tag compliance](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-policies#policy-definitions)

- **Don't use tags for policy filtering**: If you use Azure Policy, it's highly recommended not to use tag filtering in your policy rules when the policy relates to security setting, when you use tags to filter, resources without tag appear Compliance. Azure Policy exemptions or Azure Policy exclusions are recommended.

- **Don't use tags for replace naming convention gaps**: Tags are not a replacement for naming conventions. Use tags to categorize resources, and use naming conventions to identify resources uniquely.

- **Use tags for automation**: Use tags to trigger automation tasks, such as scaling, backup, or monitoring. You can use tags to define policies that enforce specific actions based on resource categories.

- **Don't go crazy adding tags**: Don't add too many tags to your resources. Keep it simple and use tags that are meaningful and useful. Too many tags can make it difficult to manage. You can begin with a small set of tags and expand as needed, for example: [Minimum Suggested Tags](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-tagging#minimum-suggested-tags)

- **Not all Azure services support tags**: Keep in mind that not all Azure services support tags. You can check in the [Tag support for Azure resources](https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/tag-support) to see which services support tags.

## Conclusion

By using tags, you can organize and manage your resources more effectively, track and manage costs more efficiently, and automate tasks based on resource categories. I hope this post has given you a good introduction to tagging best practices in Azure and how you can use tags to optimize your cloud environment.