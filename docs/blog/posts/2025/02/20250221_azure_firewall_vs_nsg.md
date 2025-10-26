---
draft: false
date: 2025-02-21
authors:
  - rfernandezdo
categories:
  - Azure Security
tags:
  - Azure Firewall
  - NSG
  - Networking
---

# Azure Firewall vs NSG: Cuándo usar cada uno

## Resumen

NSG filtra a nivel de subnet/NIC, Azure Firewall es un firewall centralizado con threat intelligence. No son excluyentes, se complementan.

## Introducción

[Contenido técnico detallado a desarrollar]

## Configuración básica

```bash
# Comandos de ejemplo
RG="my-rg"
LOCATION="westeurope"

# Comandos Azure CLI
az group create --name $RG --location $LOCATION
```

## Casos de uso

- Caso 1: [Descripción]
- Caso 2: [Descripción]  
- Caso 3: [Descripción]

## Buenas prácticas

- **Práctica 1**: Descripción
- **Práctica 2**: Descripción
- **Práctica 3**: Descripción

## Monitoreo y troubleshooting

```bash
# Comandos de diagnóstico
az monitor metrics list --resource ...
```

## Referencias

- [Documentación oficial](https://learn.microsoft.com/en-us/azure/)
