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

## Caution

EPAC is a true desired state deployment technology. It takes possession of all Policy Resources at the deploymentRootScope and its children. It will delete any Policy resources not defined in the EPAC repo¹.

## Conclusion

EPAC is a robust solution for managing Azure Policies as code. It offers a high level of assurance in highly controlled and sensitive environments, and a means for the development, deployment, management, and reporting of Azure policy at scale. 

## References
- [EPAC Documentation](https://github.com/Azure/enterprise-azure-policy-as-code)
- 




