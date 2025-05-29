---
draft: false
date: 2025-05-29
authors:
  - rfernandezdo
categories:
    - Azure Services
tags:
    - Azure Virtual Network Manager
---

# Azure Virtual Network Manager: Illustrative relationship between components

```mermaid
graph TD
    subgraph "Azure Scope"
        MG["Management Group / Subscription"]
    end
    subgraph "Azure Virtual Network Manager (AVNM)"
        AVNM_Instance["AVNM Instance"] -- Manages --> MG
        AVNM_Instance -- Contains --> NG1["Network Group A (e.g., Production)"]
        AVNM_Instance -- Contains --> NG2["Network Group B (e.g., Test)"]
    end
    subgraph "Virtual Networks (VNets)"
        VNet1["VNet 1"]
        VNet2["VNet 2"]
        VNet3["VNet 3"]
        VNet4["VNet 4"]
    end
    subgraph "Membership"
        Static["Static Membership"] -- Manually Adds --> NG1
        Static -- Manually Adds --> NG2
        VNet1 -- Member Of --> Static
        VNet4 -- Member Of --> Static
        Dynamic["Dynamic Membership (Azure Policy)"] -- Automatically Adds --> NG1
        Dynamic -- Automatically Adds --> NG2
        Policy["Azure Policy Definition (e.g., 'tag=prod')"] -- Defines --> Dynamic
        VNet2 -- Meets Policy --> Dynamic
        VNet3 -- Meets Policy --> Dynamic
    end
    subgraph "Configurations"
        ConnConfig["Connectivity Config (Mesh / Hub-Spoke)"] -- Targets --> NG1
        SecConfig["Security Admin Config (Rules)"] -- Targets --> NG1
        SecConfig2["Security Admin Config (Rules)"] -- Targets --> NG2
    end
    subgraph "Deployment & Enforcement"
        Deploy["Deployment"] -- Applies --> ConnConfig
        Deploy -- Applies --> SecConfig
        Deploy -- Applies --> SecConfig2
        NG1 -- Receives --> ConnConfig
        NG1 -- Receives --> SecConfig
        NG2 -- Receives --> SecConfig2
        VNet1 -- Enforced --> NG1
        VNet2 -- Enforced --> NG1
        VNet3 -- Enforced --> NG1
        VNet4 -- Enforced --> NG2
    end
    %% Removed 'fill' for better dark mode compatibility, kept colored strokes
    classDef avnm stroke:#f9f,stroke-width:2px;
    classDef ng stroke:#ccf,stroke-width:1px;
    classDef vnet stroke:#cfc,stroke-width:1px;
    classDef config stroke:#ffc,stroke-width:1px;
    classDef policy stroke:#fcc,stroke-width:1px;
    class AVNM_Instance avnm;
    class NG1,NG2 ng;
    class VNet1,VNet2,VNet3,VNet4 vnet;
    class ConnConfig,SecConfig,SecConfig2 config;
    class Policy,Dynamic,Static policy;
```

## Diagram Explanation

1.  **Azure Scope**: Azure Virtual Network Manager (AVNM) operates within a defined **scope**, which can be a **Management Group** or a **Subscription**. This determines which VNets AVNM can "see" and manage.
2.  **AVNM Instance**: This is the main Azure Virtual Network Manager resource. Network groups and configurations are created and managed from here.
3.  **Network Groups**:
    * These are **logical containers** for your Virtual Networks (VNets).
    * They allow you to group VNets with common characteristics (environment, region, etc.).
    * A VNet can belong to multiple network groups.
4.  **Membership**: How VNets are added to Network Groups:
    * **Static Membership**: You add VNets **manually**, selecting them one by one.
    * **Dynamic Membership**: Uses **Azure Policy** to automatically add VNets that meet certain criteria (like tags, names, locations). VNets matching the policy are dynamically added (and removed) from the group.
5.  **Virtual Networks (VNets)**: These are the Azure virtual networks that are being managed.
6.  **Configurations**: AVNM allows you to apply two main types of configurations to Network Groups:
    * **Connectivity Config**: Defines how VNets connect within a group (or between groups). You can create topologies like **Mesh** (all connected to each other) or **Hub-and-Spoke** (a central VNet connected to several "spoke" VNets).
    * **Security Admin Config**: Allows you to define high-level **security rules** that apply to the VNets in a group. These rules can **override** Network Security Group (NSG) rules, enabling centralized and mandatory security policies.
7.  **Deployment & Enforcement**:
    * The created configurations (connectivity and security) must be **Deployed**.
    * During deployment, AVNM translates these configurations and applies them to the VNets that are members of the target network groups in the selected regions.
    * Once deployed, the VNets within the groups **receive** and **apply** (Enforced) these configurations, establishing the defined connections and security rules.

    And maybe this post will be published in the official [documentation of Azure Virtual Network Manager](https://github.com/MicrosoftDocs/azure-docs/pull/126940), who knows? 😉