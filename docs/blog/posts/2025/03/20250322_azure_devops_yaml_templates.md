---
draft: false
date: 2025-03-22
authors:
  - rfernandezdo
categories:
  - DevOps
tags:
  - Azure DevOps
  - YAML
  - CI/CD
---

# Azure DevOps: YAML templates reutilizables

## Resumen

Templates eliminan código duplicado en pipelines. template parameters, extends y multistage.

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
