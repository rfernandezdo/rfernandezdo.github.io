---
draft: true
date: 2024-04-19
authors:
  - rfernandezdo
categories:
    - Microsoft Entra
tags:
    - Microsoft Entra External ID B2B 
    - B2B
---

# Microsoft Entra External ID B2B Collaboration

Microsoft Entra External ID B2B Collaboration is a feature that allows organizations to collaborate with external users in a secure and compliant way. It enables organizations to share resources with external users while maintaining control over access and security.

## Guest user

 A guest user is a user who is invited to collaborate with an organization but is not a member of that organization. 

 This the flow for a guest user:

 ```mermaid
sequenceDiagram
    participant A as Organization
    participant B as Guest User
    A->>B: Invite guest user
    B->>A: Accept invitation
    A->>B: Access resources
 ```


## B2B Collaboration

B2B Collaboration allows organizations to invite external users to collaborate with them. Organizations can invite external users to access resources, such as applications, documents, and sites, and can control what those users can access and do.





## Conclusion
