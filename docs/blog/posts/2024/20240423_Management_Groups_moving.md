---
draft: false
date: 2024-04-23
authors:
  - rfernandezdo
categories:
    - Azure Services
tags:
    - Management Groups
    
---
# Moving Management Groups and Subscriptions

Managing your Azure resources efficiently often involves moving management groups and subscriptions. Here's a brief guide on how to do it:

## Moving Management Groups

To move a management group, you need to have the necessary permissions. You must be an owner of the target parent management group and have `Management Group Contributor` role at the group you want to move.

Here's the step-by-step process:

1. Navigate to the **Azure portal**.
2. Go to **Management groups**.
3. Select the management group you want to move.
4. Click **Details**.
5. Under **Parent group**, click **Change**.
6. Choose the new parent group from the list and click **Save**.

Remember, moving a management group will also move all its child resources including other management groups and subscriptions.

## Moving Subscriptions

You can move a subscription from one management group to another or within the same management group. To do this, you must have the `Owner` or `Contributor` role at the target management group and `Owner` role at the subscription level.

Follow these steps:

1. Go to the **Azure portal**.
2. Navigate to **Management groups**.
3. Select the management group where the subscription currently resides.
4. Click on **Subscriptions**.
5. Find the subscription you want to move and select **..."** (More options).
6. Click **Change parent**.
7. In the pop-up window, select the new parent management group and click **Save**.

!!! note 
    Moving subscriptions could affect the resources if there are policies or permissions applied at the management group level. It's important to understand the implications before making the move. Also, keep in mind that you cannot move the Root management group or rename it.

In conclusion, moving management groups and subscriptions allows for better organization and management of your Azure resources. However, it should be done carefully considering the impact on resources and compliance with assigned policies.