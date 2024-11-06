---
draft: false
date: 2024-09-17
authors:
  - rfernandezdo
categories:
    - Security

tags:    
    - CVSS
---

# Security Score System

The Common Vulnerability Scoring System (CVSS) is a framework for scoring the severity of security vulnerabilities. It provides a standardized method for assessing the impact of vulnerabilities and helps organizations prioritize their response to security threats. In this article, we will discuss the CVSS and how it can be used to calculate the severity of security vulnerabilities.

## What is CVSS?

The Common Vulnerability Scoring System (CVSS) is an open framework for scoring the severity of security vulnerabilities. It was developed by the Forum of Incident Response and Security Teams (FIRST) to provide a standardized method for assessing the impact of vulnerabilities. CVSS assigns a numerical score to vulnerabilities based on their characteristics, such as the impact on confidentiality, integrity, and availability, and the complexity of the attack vector.

CVSS is widely used by security researchers, vendors, and organizations to prioritize their response to security threats. It helps organizations understand the severity of vulnerabilities and allocate resources to address the most critical issues first.

## How is CVSS calculated?

In CVSS Version 4.0, vulnerabilities are scored on a scale of 0.0 to 10.0, with 10.0 being the most severe. The CVSS score is calculated based on several metrics groups, including:

- **Base Metric**: The Base metric group represents the intrinsic characteristics of a vulnerability that are constant over time and across user environments. It is composed of two sets of metrics: the Exploitability metrics and the Impact metrics.

- **Threat metric group**: The Threat metric group reflects the characteristics of a vulnerability related to threat that may change over time but not necessarily across user environments. 

- **Environmental metric group**: The Environmental metric group represents the characteristics of a vulnerability that are relevant and unique to a particular user's environment.

- **The Supplementary metric group**: The Supplemental metric group includes metrics that provide context as well as describe and measure additional extrinsic attributes of a vulnerability. 


## CVSS Version 4.0 Metrics

### Base Metrics

The Base metric group includes the following metrics:

- **Exploitability Metrics**: These metrics describe the characteristics of the vulnerability that affect how easy it is to exploit. They include the Attack Vector (AV), Attack Complexity (AC), Privileges Required (PR), and User Interaction (UI).
- **Vulnerable System Impact Metrics**: These metrics describe the impact on the system if the vulnerability is exploited. They include the Confidentiality(VC), Integrity (VI), and Availability (VA) impacts.
- **Subsequent System Impact Metrics**: These metrics describe the impact on the system if the vulnerability is exploited. They include the Confidentiality(SC), Integrity (II), and Availability (SA) impacts.

#### Exploitability Metrics

- **Attack Vector (AV)**: This metric describes the context where vulnerability is exploited. It can be either Local (L), Adjacent Network (A), Network (N), or Physical (P).
- **Attack Complexity (AC)**: This metric describes the complexity of the attack required to exploit the vulnerability. It can be either Low (L), High (H).
- **Privileges Required (PR)**: This metric describes the level of privileges required to exploit the vulnerability. It can be either None (N), Low (L), or High (H).
- **User Interaction (UI)**: This metric describes whether user interaction is required to exploit the vulnerability. It can be either None (N), Required (R).

####  Vulnerable System Impact Metrics

- **Confidentiality Impact (VC)**: This metric measures the impact on the confidentiality of the information managed by the vulnerable system due to a successful exploit of the vulnerability. It can be either Low (L), High (H), or None (N).

- **Integrity Impact (VI)**: This metric measures the impact on the integrity of the information managed by the vulnerable system due to a successful exploit of the vulnerability. It can be either Low (L), High (H), or None (N).

- **Availability Impact (VA)**: This metric measures the impact on the availability of the services of the vulnerable system due to a successful exploit of the vulnerability. It can be either Low (L), High (H), or None (N).

#### Subsequent System Impact Metrics

- **Confidentiality Impact (SC)**: This metric measures the impact to the confidentiality of the information managed by the Subsequent System due to a successful exploit of the vulnerability. It can be either Low (L), High (H), or None (N).


## References

 - [Common Vulnerability Scoring System version 4.0: Specification Document](https://www.first.org/cvss/v4.0/specification-document)
 - [CVSS Version 4.0 Calculator](https://www.first.org/cvss/calculator/4.0)
 - [CVSS Version 4.0 User Guide](https://www.first.org/cvss/user-guide)
