---
draft: false
date: 2025-09-25
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Network Watcher
  - VNet Flow Logs
---

# Analizando VNet Flow Logs en Azure

En este post explico qué son los VNet flow logs (logs de flujo de red de Azure), cómo habilitarlos y cómo
analizarlos con un pequeño script PowerShell que desarrollé para facilitar la detección de anomalías y la
generación de reportes.

Documentación oficial (Microsoft):

https://learn.microsoft.com/azure/network-watcher/vnet-flow-logs-overview

## Resumen rápido

- Los VNet flow logs capturan información sobre el tráfico IP que atraviesa subredes y recursos dentro de
  una Virtual Network. Almacenan datos similares a los NSG flow logs pero a nivel de VNet.
- Se pueden enviar a una cuenta de almacenamiento, a Log Analytics o a Event Hub. El formato JSON resultante
  contiene un array `records` con campos que describen cada flujo y sus métricas (bytes, paquetes, acción,
  puertos, etc.).

## Por qué analizarlos

- Identificar hosts con alto volumen de tráfico.
- Detectar intentos de escaneo de puertos o reintentos persistentes.
- Encontrar conexiones denegadas o patrones sospechosos.

## Herramienta: script PowerShell

He incluido un script llamado `Analyze-VNETFlowLogs.ps1` que procesa archivos JSON con VNet flow logs
y genera un análisis en consola. Además puede exportar dos ficheros CSV con el detalle y el resumen del
análisis.

### Dónde está el script y ejemplos

- Script: [Analyze-VNETFlowLogs.ps1](../../Tools/Analyze%20Virtual%20Network%20Flows/Analyze-VNETFlowLogs.ps1)
- README con instrucciones: [README.md](../../Tools/Analyze%20Virtual%20Network%20Flows/README.md)
- Ejemplo de flow log (reducido) para pruebas: [sample-flowlog.json](../../Tools/Analyze%20Virtual%20Network%20Flows/samples/sample-flowlog.json)
- Ejecuciones de ejemplo (reports) generadas: [reports/](../../Tools/Analyze%20Virtual%20Network%20Flows/reports/)

## Cómo usar el script

1. Preparar archivos JSON descargados desde la cuenta de almacenamiento o exportados desde Log Analytics.
2. Abrir PowerShell (Windows) o pwsh (Linux/macOS) y ejecutar (ejemplo):

```powershell
pwsh -File "./docs/Tools/Analyze Virtual Network Flows/Analyze-VNETFlowLogs.ps1" -LogFiles "./docs/Tools/Analyze Virtual Network Flows/samples/*.json" -ExportCSV -OutputPath "./docs/Tools/Analyze Virtual Network Flows/reports" -ShowGraphs
```

### Explicación rápida de parámetros

- `-LogFiles`: rutas a los JSON (acepta wildcards).
- `-ExportCSV`: exporta `VNetFlowAnalysis_Details_<timestamp>.csv` y `VNetFlowAnalysis_Summary_<timestamp>.csv`.
- `-OutputPath`: directorio para los CSV.
- `-SpecificIPs`: array de IPs para análisis centrado en hosts concretos.
- `-ShowGraphs`: muestra gráficas de barras simples en la consola.

## Ejemplo práctico (archivo de ejemplo incluido)

- He añadido `samples/sample-flowlog.json` con varios flujos que cubren casos típicos (permitidos, denegados,
  varios BEGIN para simular reintentos/posible escaneo).
- Ejecutando el comando anterior sobre ese ejemplo se generan dos CSV de salida en `reports/` y se muestra
  un resumen en consola.

## Notas y recomendaciones

- El script agrupa los flows en memoria para facilitar el análisis; para datasets muy grandes conviene
  procesar por lotes o filtrar por rango de tiempo antes de ejecutar.
- Revisa la documentación oficial (enlace arriba) si tu flujo JSON tiene un formato distinto o campos
  adicionales; la función `Parse-FlowTuple` del script espera un orden concreto de campos, que puedes
  adaptar si es necesario.

## Contribuciones y siguientes pasos

- Si quieres, puedo añadir un conjunto de tests que ejecuten el script sobre el ejemplo y verifiquen los
  CSV generados automáticamente.
- También puedo crear un pequeño tutorial paso a paso para habilitar VNet flow logs en Azure y obtener
  los JSON desde una cuenta de almacenamiento.

## Archivos incluidos

- `Analyze-VNETFlowLogs.ps1` — script principal.
- `README.md` — instrucciones y referencia a la doc oficial.
- `samples/sample-flowlog.json` — ejemplo para pruebas.

Espero que esto te ayude a analizar flujos en tus VNets.

