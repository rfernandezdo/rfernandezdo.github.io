---
draft: false
date: 2025-02-06
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure Logic Apps
  - Integration
  - Automation
---

# Azure Logic Apps: Automatización sin código para integraciones

## Resumen

Logic Apps te permite crear workflows de integración sin escribir código. Ideal para automatizar procesos que involucran múltiples servicios: recibir email → guardar adjunto en Blob → procesar con Function → enviar notificación.

## ¿Cuándo usar Logic Apps?

- Integraciones entre SaaS (Office 365, Salesforce, Dynamics)
- Procesos de negocio automatizados
- Event-driven workflows
- B2B con EDI/AS2/X12

**No uses Logic Apps si:**
- Necesitas lógica compleja (usa Functions)
- Performance crítico <100ms (usa Functions)
- Procesamiento en batch grande (usa Data Factory)

## Crear Logic App

```bash
# Variables
RG="my-rg"
LOGIC_APP="email-processor"
LOCATION="westeurope"

# Crear Logic App (Consumption plan)
az logic workflow create \
  --resource-group $RG \
  --location $LOCATION \
  --name $LOGIC_APP
```

## Ejemplo: Procesar emails con adjuntos

**Workflow:**
1. Trigger: Cuando llega email a Outlook
2. Acción: Si tiene adjunto PDF
3. Acción: Guardar en Blob Storage
4. Acción: Llamar Function para OCR
5. Acción: Guardar metadatos en Cosmos DB
6. Acción: Enviar notificación a Teams

```json
{
  "definition": {
    "$schema": "https://schema.management.azure.com/schemas/2016-06-01/Microsoft.Logic.json",
    "triggers": {
      "When_a_new_email_arrives": {
        "type": "ApiConnection",
        "inputs": {
          "host": {"connection": {"name": "@parameters('$connections')['office365']['connectionId']"}},
          "method": "get",
          "path": "/Mail/OnNewEmail"
        }
      }
    },
    "actions": {
      "Condition_has_PDF": {
        "type": "If",
        "expression": {
          "@contains(triggerBody()?['Attachments'], '.pdf')"
        },
        "actions": {
          "Upload_to_Blob": {
            "type": "ApiConnection",
            "inputs": {
              "host": {"connection": {"name": "@parameters('$connections')['azureblob']['connectionId']"}},
              "method": "post",
              "path": "/datasets/default/files",
              "queries": {
                "folderPath": "/invoices",
                "name": "@triggerBody()?['Attachments'][0]['Name']"
              },
              "body": "@base64ToBinary(triggerBody()?['Attachments'][0]['ContentBytes'])"
            }
          }
        }
      }
    }
  }
}
```

## Conectores más útiles

**Azure:**
- Service Bus, Event Grid, Storage, Cosmos DB, Key Vault, Functions

**Microsoft 365:**
- Outlook, Teams, SharePoint, OneDrive, Planner

**Terceros:**
- Salesforce, SAP, Twitter, Slack, Twilio, SendGrid

**On-premises:**
- SQL Server, File System, Oracle (requiere Data Gateway)

## Standard vs Consumption

| Feature | Consumption | Standard |
|---------|-------------|----------|
| Pricing | Por ejecución | Por vCPU/hora |
| Networking | Public | VNET integration |
| Stateful/Stateless | Stateful | Ambos |
| Local dev | No | Sí (VS Code) |
| CI/CD | Difícil | Fácil |

## Buenas prácticas

- **Idempotencia**: Usa `ClientTrackingId` para deduplicación
- **Error handling**: Configura retry policy y run after
- **Monitoreo**: Habilita diagnostic logs
- **Variables**: Usa variables para valores reutilizables
- **Funciones inline**: Usa expressions para transformaciones simples

## Referencias

- [Azure Logic Apps documentation](https://learn.microsoft.com/en-us/azure/logic-apps/)
