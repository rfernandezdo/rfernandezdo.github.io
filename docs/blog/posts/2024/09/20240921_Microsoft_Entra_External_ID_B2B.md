---
draft: false
date: 2024-09-21
authors:
  - rfernandezdo
categories:
    -  Microsoft Entra External ID
tags:
    - External ID B2B
    - B2B
    - B2B Direct Connect
    - B2B Collaboration
---
# Differences between **B2B Direct Connect** and **B2B Collaboration** in Microsoft Entra

Microsoft Entra offers two ways to collaborate with external users: **B2B Direct Connect** and **B2B Collaboration**. Both features allow organizations to share resources with external users while maintaining control over access and security. However, they differ in functionality, access, and integration. Here is a comparison between **B2B Direct Connect** and **B2B Collaboration**:

| **Feature**                 | **B2B Direct Connect**                                                                 | **B2B Collaboration**                                                                 |
|-----------------------------|----------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------|
| **Definition**              | Mutual trust relationship between two Microsoft Entra organizations                    | Invite external users to access resources using their own credentials                |
| **Functionality**           | Seamless collaboration using origin credentials and shared channels in Teams           | External users receive an invitation and access resources after authentication       |
| **Applications**            | Shared channels in Microsoft Teams                                                     | Wide range of applications and services within the Microsoft ecosystem               |
| **Access**                  | Single sign-on (SSO) with origin credentials                                           | Authentication each time resources are accessed, unless direct federation is set up  |
| **Integration**             | Deep and continuous integration between two organizations                              | Flexible way to invite and manage external users                                     |

I hope this helps! 