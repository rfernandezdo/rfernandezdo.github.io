---
draft: false
date: 2024-02-29
authors:
  - rfernandezdo
categories:
  - Tools
tags:
  - Azure Policy
  - EPAC  
---

# Enterprise Azure Policy as Code (EPAC)

Enterprise Azure Policy as Code (EPAC) is a powerful tool that allows organizations to manage Azure Policies as code in a git repository². It's designed for medium and large organizations with a larger number of Policies, Policy Sets, and Assignments, and/or complex deployment scenarios¹.

## Key Features of EPAC

- **Single and multi-tenant policy deployment**: EPAC supports both single and multi-tenant policy deployments, making it versatile for different organizational structures¹.
- **Easy CI/CD Integration**: EPAC can be easily integrated with any CI/CD tool, which makes it a great fit for DevOps environments¹.
- **Operational scripts**: EPAC includes operational scripts to simplify operational tasks¹.
- **Integration with Azure Landing Zones**: EPAC provides a mature integration with Azure Landing Zones. Utilizing Azure Landing Zones together with EPAC is highly recommended¹.

## Who Should Use EPAC?

EPAC is designed for medium and large organizations with a larger number of Policies, Policy Sets, and Assignments, and/or complex deployment scenarios¹. However, smaller organizations implementing fully-automated DevOps deployments of every Azure resource (known as Infrastructure as Code) can also benefit from EPAC¹.

## How Does EPAC Work?

EPAC works by deploying all policies and policy assignments defined in the EPAC repository to the deploymentRootScope and its children. It takes possession of all Policy Resources at the deploymentRootScope and its children.

![Alt text](image-2.png)


The process depicted in the image involves three key scripts that manage a deployment sequence. Here's a breakdown of the process:

1. **Definition Files**: The process begins with various definition files in JSON, CSV, or XLSX formats. These files contain policy definitions, policy set (initiative) definitions, assignments, exemptions, and global settings.

2. **Planning Script**: The `Build-DeploymentPlans.ps1` script uses these definition files to create a deployment plan. This script requires Resource Policy Reader privileges.

3. **Deployment Scripts**: The deployment plan is then used by two deployment scripts:
   - `Deploy-PolicyPlan.ps1`: This script deploys Policy resources using the `policy-plan.json` file from the deployment plan. It requires Resource Policy Contributor privileges.
   - `Deploy-RolesPlan.ps1`: This script deploys Role Assignments using the `roles-plan.json` file from the deployment plan. It requires User Access Administrator privileges.

The process includes optional approval gates after each deployment step. These are typically used in production environments to ensure each deployment step is reviewed and approved before moving to the next.


!!! Warning

    EPAC is a true desired state deployment technology. It takes possession of all Policy Resources at the deploymentRootScope and its children. It will delete any Policy resources not defined in the EPAC repo.

## Conclusion

EPAC is a robust solution for managing Azure Policies as code. It offers a high level of assurance in highly controlled and sensitive environments, and a means for the development, deployment, management, and reporting of Azure policy at scale. 

## References
- [EPAC Documentation](https://github.com/Azure/enterprise-azure-policy-as-code)




