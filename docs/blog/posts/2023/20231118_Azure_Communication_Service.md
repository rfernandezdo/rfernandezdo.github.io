---
date: 2023-11-18
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:  
  - Azure Communication Services
  
---

# Azure Communication Services

## What is Azure Communication Services?

Azure Communication Services are cloud-based services with REST APIs and client library SDKs available to help you integrate communication into your applications. You can add communication to your applications without being an expert in underlying technologies such as media encoding or telephony.

Azure Communication Services supports various communication formats:

- Voice and Video Calling
- Rich Text Chat
- SMS
- Email

And offers the following services:

- SMS: Send and receive SMS messages from your applications.
- Phone calling: Enable your applications to make and receive PSTN calls.
- Voice and video calling: Enable your applications to make and receive voice and video calls.
- Chat: Enable your applications to send and receive chat messages.
- Email: Send and receive emails from your applications.
- Network traversal: Enable your applications to connect to other clients behind firewalls and NATs.
- Advanced Messaging:
    - WhatsApp(Public Preview): Enable you to send and receive WhatsApp messages using the Azure Communication Services Messaging SDK. 
- Job Router(Public Preview): It's a tool designed to optimize the management of customer interactions across various communication applications.

Some Use Cases:

- Telemedicine: Enable patients to connect with doctors and nurses through video consultations.
- Remote education: Enable students to connect with teachers and other students through video classes.
- Financial Advisory: Enhancing global advisor and client interactions with rich capabilities such as translation for chat.
- Retail Notifications: Send notifications to customers about their orders via SMS or email.
- Professional Support: Enable customers to connect with support agents through chat, voice, or video.


## Design considerations

You have  some data flow diagrams to help you to understand how Azure Communication Services works [here](https://learn.microsoft.com/en-us/azure/architecture/guide/mobile/azure-communication-services-architecture)

Some aspects to consider:

- You need to apply throttling patterns to avoid overloading the service,  HTTP status code 429 (Too many requests).
- Plan how to map users from your identity domain to Azure Communication Services identities. You can follow any kind of pattern. For example, you can use 1:1, 1:N, N:1, or M:N
- Check regional availability. You can see more information about regional availability [here](https://azure.microsoft.com/en-us/global-infrastructure/services/?products=communication-services).
- Check the service limits. You can see more information about service limits [here](https://learn.microsoft.com/en-us/azure/communication-services/concepts/service-limits).
- Check security baseline. You can see more information about security baseline [here](https://learn.microsoft.com/en-us/security/benchmark/azure/baselines/azure-communication-services-security-baseline).



## Pricing

Azure Communication Services is a pay-as-you-go service. You only pay for what you use, and there are no upfront costs. You can see more information about pricing [here](https://azure.microsoft.com/en-us/pricing/details/communication-services/).

The bad news are:

- In some services pricing vary by country.
- You don't have a free tier, but you have something free.
- You don't have Azure Reservations or equivalent.


## Conclusion

Azure Communication Services is a very interesting service but you need to consider the cost of the service and the regional availability before to use it.



That's it folks!, thanks for reading :smile:!.


