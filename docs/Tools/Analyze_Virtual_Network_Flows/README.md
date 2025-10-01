# Analyze-VNETFlowLogs

Analizador de logs de flujo de Azure (VNet). Este script PowerShell procesa archivos JSON generados por Azure Network Watcher (flow logs) y genera un análisis en consola con detección de anomalías y, opcionalmente, exporta resultados a CSV.

## Contenido
- [`Analyze-VNETFlowLogs.ps1`](./Analyze-VNETFlowLogs.ps1) — Script principal que realiza el análisis.

Puedes leer un artículo que explica VNet flow logs y muestra cómo usar esta herramienta en:
- [Analizando VNet Flow Logs en Azure](../../blog/posts/2025/202501001_Analyze_VNet_Flows.md)

## Requisitos
- PowerShell 5.1 o superior (Windows PowerShell o PowerShell Core / pwsh).
- Archivos JSON con formato de Azure flow logs v2 (cada archivo contiene un array `records`, y dentro `flowRecords.flows[].flowGroups[].flowTuples`).

Nota: este script está diseñado para procesar Virtual Network (VNet) flow logs tal y como los documenta
Microsoft. Para más detalles sobre el formato y cómo habilitar VNet flow logs en Azure, consulta la
documentación oficial:

https://learn.microsoft.com/azure/network-watcher/vnet-flow-logs-overview


## Uso rápido
Abrir PowerShell o pwsh y ejecutar el script con uno o varios archivos (acepta wildcards):

```bash
# Ejecutar contra todos los JSON en un directorio y exportar CSV
pwsh -File ./docs/Tools/Analyze\ Virtual\ Network\ Flows/Analyze-VNETFlowLogs.ps1 -LogFiles "./samples/*.json" -ExportCSV -OutputPath "./reports"

# Analizar un único archivo y mostrar gráficos en consola
pwsh -File ./docs/Tools/Analyze\ Virtual\ Network\ Flows/Analyze-VNETFlowLogs.ps1 -LogFiles "./flowlog.json" -ShowGraphs

# Analizar y centrarse en IPs específicas
pwsh -File ./docs/Tools/Analyze\ Virtual\ Network\ Flows/Analyze-VNETFlowLogs.ps1 -LogFiles "./flowlog.json" -SpecificIPs @("10.0.0.5","192.168.1.10")
```

> Nota: en sistemas Linux/macOS con `pwsh`, use `pwsh` en lugar de `powershell`.

## Salidas
- Salida por consola con secciones: resumen, top IPs, puertos, reglas, conexiones problemáticas y detección de anomalías.
- Si se usa `-ExportCSV`: dos ficheros CSV generados en `-OutputPath` (o directorio actual):
  - `VNetFlowAnalysis_Details_<timestamp>.csv` — detalle de todos los flows.
  - `VNetFlowAnalysis_Summary_<timestamp>.csv` — métricas agregadas.

## Códigos de salida
- 0 — ejecución correcta.
- 1 — error (por ejemplo: no se encontraron archivos, o excepción durante el análisis).

## Ejemplos de ejecución
```pwsh
 Analyze-VNETFlowLogs.ps1 -LogFiles samples/sample-flowlog.json -ExportCSV -OutputPath reports -ShowGraphs
🔍 Archivos a procesar:
   samples/sample-flowlog.json

======================================================
=  INICIANDO ANÁLISIS DE LOGS DE FLUJO DE AZURE VNET =
======================================================

📁 Procesando archivo: samples/sample-flowlog.json
✅ Procesado: 7 flows de 2 records
=====================
=  RESUMEN GENERAL  =
=====================

📊 Archivos procesados: 1
📊 Total de records: 2
📊 Total de flows: 7
⏰ Período analizado: 09/30/2025 12:00:00 - 09/30/2025 12:10:00

--- ESTADÍSTICAS POR ARCHIVO ---
📄 sample-flowlog.json:
   Records: 2
   Flows: 7
   Período: 09/30/2025 12:00:00 - 09/30/2025 12:10:00

=====================================
=  ANÁLISIS DE PATRONES DE TRÁFICO  =
=====================================


--- ESTADÍSTICAS GENERALES ---
🔢 Total de flows: 7
🖥️  IPs de origen únicas: 3
🌐 IPs de destino únicas: 4
📊 Total de bytes transferidos: 0.01 MB
📦 Total de paquetes: 37

--- ANÁLISIS DE PROTOCOLOS ---
UDP : 1 flows (14.3%)
TCP : 6 flows (85.7%)

📊 Distribución de Protocolos
────────────────────────────────────────────────────────────
TCP                  │██████████████████████████████████████████████████ 6
UDP                  │████████ 1


--- ANÁLISIS DE ACCIONES DE SEGURIDAD ---
BLOQUEADO/INICIADO (Begin) : 4 flows (57.1%)
DENEGADO (Denied) : 1 flows (14.3%)
PERMITIDO (Established) : 2 flows (28.6%)

📊 Distribución de Acciones
────────────────────────────────────────────────────────────
BLOQUEADO/INICIADO (Begin) │██████████████████████████████████████████████████ 4
PERMITIDO (Established) │█████████████████████████ 2
DENEGADO (Denied)    │████████████ 1


--- ANÁLISIS DE DIRECCIONES ---
ENTRANTE (Inbound) : 1 flows (14.3%)
SALIENTE (Outbound) : 6 flows (85.7%)

--- TOP 15 IPs DE ORIGEN ---
10.0.0.6             : 4 flows
10.0.0.5             : 2 flows
192.168.1.10         : 1 flows

📊 Top IPs de Origen
────────────────────────────────────────────────────────────
10.0.0.6             │██████████████████████████████████████████████████ 4
10.0.0.5             │█████████████████████████ 2
192.168.1.10         │████████████ 1


--- TOP 15 IPs DE DESTINO CON IDENTIFICACIÓN ---
203.0.113.10         : 4 flows - HTTPS (Unknown/Public)
10.0.0.5             : 1 flows - HTTPS (RFC1918 Private)
8.8.8.8              : 1 flows - HTTPS (Google DNS)
93.184.216.34        : 1 flows - HTTPS (Unknown/Public)

📊 Top IPs de Destino
────────────────────────────────────────────────────────────
203.0.113.10         │██████████████████████████████████████████████████ 4
10.0.0.5             │████████████ 1
8.8.8.8              │████████████ 1
93.184.216.34        │████████████ 1


--- TOP 15 PUERTOS DE DESTINO ---
Puerto 22       : 1 flows - SSH (Unknown/Public)
Puerto 23       : 1 flows - Telnet (Unknown/Public)
Puerto 25       : 1 flows - SMTP (Unknown/Public)
Puerto 3389     : 1 flows - RDP (Unknown/Public)
Puerto 4444     : 1 flows - Port-4444 (Unknown/Public)
Puerto 53       : 1 flows - DNS (Unknown/Public)
Puerto 80       : 1 flows - HTTP (Unknown/Public)

📊 Top Puertos de Destino
────────────────────────────────────────────────────────────
Port-25              │██████████████████████████████████████████████████ 1
Port-3389            │██████████████████████████████████████████████████ 1
Port-22              │██████████████████████████████████████████████████ 1
Port-53              │██████████████████████████████████████████████████ 1
Port-23              │██████████████████████████████████████████████████ 1
Port-80              │██████████████████████████████████████████████████ 1
Port-4444            │██████████████████████████████████████████████████ 1


--- ANÁLISIS DE REGLAS DE SEGURIDAD ---
Allow-DNS                                : 5 flows
Allow-HTTP                               : 2 flows
==========================================
=  ANÁLISIS DE CONEXIONES PROBLEMÁTICAS  =
==========================================


--- CONEXIONES SIN COMPLETAR (BEGIN SIN ESTABLISHED) ---
🔍 Analizando conexiones BEGIN...
📊 Encontradas 4 conexiones BEGIN. Agrupando...
🔍 Verificando cuáles no tienen ESTABLISHED correspondiente...
✅ Análisis de conexiones sin completar finalizado.
🔄 10.0.0.6 →  203.0.113.10: 22 - 1 intentos sin completar - Port- 22 (Unknown/Public)
🔄 10.0.0.6 →  203.0.113.10: 23 - 1 intentos sin completar - Port- 23 (Unknown/Public)
🔄 10.0.0.6 →  203.0.113.10: 25 - 1 intentos sin completar - Port- 25 (Unknown/Public)
🔄 10.0.0.6 →  203.0.113.10: 4444 - 1 intentos sin completar - Port- 4444 (Unknown/Public)

--- CONEXIONES DENEGADAS (DENIED) ---
🚫 192.168.1.10 →  10.0.0.5: 3389 - 1 denegaciones - Port- 3389 (Unknown/Public)

--- CONEXIONES CON DROPS (PÉRDIDA DE PAQUETES) ---
✅ No se detectaron patrones de drops significativos

--- CONEXIONES CON REINTENTOS EXCESIVOS ---
✅ No se detectaron reintentos excesivos

--- CONEXIONES ASIMÉTRICAS (UNA DIRECCIÓN) ---
🔍 Analizando conexiones asimétricas...
📊 Analizando 0 pares de conexiones...
✅ Análisis de conexiones asimétricas completado.
✅ No se detectaron conexiones asimétricas significativas
===================================================
=  DETECCIÓN DE ANOMALÍAS Y PATRONES SOSPECHOSOS  =
===================================================


--- CONEXIONES DE ALTO VOLUMEN (Top 1%) ---
🚨 10.0.0.6 → 203.0.113.10:25 - 0.08 KB

--- PUERTOS INUSUALES ---
🔍 Puerto 23 : 1 conexiones
🔍 Puerto 4444 : 1 conexiones

--- IPs CON MUCHAS CONEXIONES BLOQUEADAS ---
✅ No se detectaron IPs con patrones sospechosos de bloqueo

--- POSIBLE PORT SCANNING ---
✅ No se detectaron patrones de port scanning
===========================
=  EXPORTANDO RESULTADOS  =
===========================

📄 Flows detallados exportados a: reports/VNetFlowAnalysis_Details_20251001_170752.csv
📊 Resumen exportado a: reports/VNetFlowAnalysis_Summary_20251001_170752.csv
=========================
=  ANÁLISIS COMPLETADO  =
=========================

🎯 Se analizaron 7 flows de 1 archivo(s)
⏱️  Período total analizado: 09/30/2025 12:00:00 - 09/30/2025 12:10:00
```

## Limitaciones y recomendaciones
- El script acumula los flows en memoria para facilitar el análisis; para conjuntos de datos muy grandes (muchos GB o millones de registros) puede consumir mucha memoria.
  - Recomiendo filtrar previamente por fecha/rango o procesar archivos por lotes.
- Las gráficas en consola usan caracteres Unicode (bloques). Si la terminal no los soporta, activar/desactivar `-ShowGraphs` según convenga.
- Si el formato de `flowTuple` difiere de lo esperado, actualiza la función `Parse-FlowTuple` en el script o avísame para adaptar la documentación.

## Autor y licencia
Autor: Rafael Fernández (@rfernandezdo)

## Historial de cambios
- v1.1 (2025-10-01): Añadida documentación ampliada y README.
- v1.0 (2025-09-24): Versión inicial del script.
