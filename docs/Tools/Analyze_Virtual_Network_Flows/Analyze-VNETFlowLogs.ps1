#Requires -Version 5.1
<#
.SYNOPSIS
    Analiza logs de flujo de Azure (VNet - Virtual Network) y genera reportes con detección de anomalías.

.DESCRIPTION
    Este script procesa archivos JSON generados por Azure Network Watcher (flow logs) y realiza un
    análisis exhaustivo de los patrones de tráfico. Entre sus funcionalidades se incluyen:
      - Cálculo de estadísticas agregadas (flows, bytes, paquetes, IPs únicas).
      - Identificación de protocolos, puertos y servicios comunes.
      - Detección de anomalías: conexiones de alto volumen, puertos inusuales, posibles escaneos
        de puertos, conexiones denegadas y reintentos excesivos.
      - Análisis por archivo y por IP específica (cuando se solicita).
      - Export opcional de resultados detallados y resumen a CSV.

    El script espera archivos JSON con la estructura típica de Azure flow logs v2, en los que se
    encuentra un array "records" y dentro de cada record: "flowRecords.flows[].flowGroups[].flowTuples".
    Cada "flowTuple" es una cadena con valores separados por comas con el siguiente orden esperado:
      Timestamp, SourceIP, DestIP, SourcePort, DestPort, Protocol, Direction, Action, FlowState,
      PacketsSourceToDest, BytesSourceToDest, PacketsDestToSource, BytesDestToSource

.PARAMETER LogFiles
    Una o varias rutas a archivos JSON de logs. Se aceptan patrones con wildcards (por ejemplo:
    "C:\logs\*.json" o "./logs/*.json").

.PARAMETER OutputPath
    Directorio donde se guardarán los ficheros CSV cuando se use -ExportCSV. Si no se especifica,
    se utilizan el directorio actual.

.PARAMETER SpecificIPs
    Array de direcciones IP (strings). Si se proporciona, el script generará análisis específicos
    para cada IP indicada (como origen y destino).

.PARAMETER ExportCSV
    Switch. Si se establece, exporta dos ficheros CSV: un detalle de todos los flows y un resumen
    con métricas agregadas. Los nombres incluyen marca temporal (timestamp).

.PARAMETER ShowGraphs
    Switch. Si se establece, muestra gráficas simples de barras en la consola (usa caracteres
    Unicode). Si la consola no soporta estos caracteres, pueden verse caracteres basura.

.EXAMPLE
    .\Analyze-VNETFlowLogs.ps1 -LogFiles "C:\logs\*.json" -ExportCSV -OutputPath "C:\reports"

.EXAMPLE
    .\Analyze-VNETFlowLogs.ps1 -LogFiles "./flowlog-2025-09-*.json" -SpecificIPs @("10.0.0.5","192.168.1.10") -ShowGraphs

.EXAMPLE
    # Procesar un único archivo
    .\Analyze-VNETFlowLogs.ps1 -LogFiles "./flowlog.json"

.INPUTS
    Ninguno. El script lee archivos desde el sistema de ficheros.

.OUTPUTS
    Salida por consola con el análisis. Opcionalmente, archivos CSV cuando se usa -ExportCSV.

.EXITCODE
    0 - Éxito
    1 - Error (por ejemplo, no se encontraron archivos o excepción durante el análisis)

.REMARKS
    Requisitos:
      - PowerShell 5.1 o superior (Windows PowerShell / PowerShell Core).
      - Archivos JSON con formato de flow logs v2 de Azure Network Watcher.

    Rendimiento:
      Para conjuntos de datos muy grandes (miles de archivos o millones de registros) se recomienda
      filtrar previamente los archivos por rango de tiempo o ejecutar el análisis en una máquina con
      suficiente memoria. El script agrupa en memoria todos los flows para facilitar el análisis.

.NOTES
    Autor: Rafael Fernández (@rfernandezdo)
    Versión: 1.1
    Última actualización: 2025-10-01
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string[]]$LogFiles,
   
    [Parameter(Mandatory = $false)]
    [string]$OutputPath,
   
    [Parameter(Mandatory = $false)]
    [string[]]$SpecificIPs = @(),
   
    [Parameter(Mandatory = $false)]
    [switch]$ExportCSV,
   
    [Parameter(Mandatory = $false)]
    [switch]$ShowGraphs
)

# Colores para output
$Colors = @{
    Header = "Green"
    Subheader = "Yellow"
    Warning = "Red"
    Error = "DarkRed"
    Info = "Cyan"
    Success = "Magenta"
    Normal = "White"
}

# Helper para validar y convertir color a System.ConsoleColor
function Get-ConsoleColor {
    param(
        [Parameter(Mandatory=$true)][string]$ColorName,
        [string]$Default = 'White'
    )
    try {
        if ([string]::IsNullOrWhiteSpace($ColorName)) { $ColorName = $Default }
        return [System.ConsoleColor]::Parse([System.ConsoleColor], $ColorName)
    } catch {
        return [System.ConsoleColor]::Parse([System.ConsoleColor], $Default)
    }
}

# Función para mostrar headers con estilo
function Write-StyledHeader {
    param([string]$Text, [string]$Color = "Green", [string]$Symbol = "=")
    $fg = Get-ConsoleColor $Color 'Green'
    $line = $Symbol * ($Text.Length + 6)
    Write-Host $line -ForegroundColor $fg
    Write-Host "$Symbol  $Text  $Symbol" -ForegroundColor $fg
    Write-Host $line -ForegroundColor $fg
    Write-Host ""
}

# Función para mostrar subheaders
function Write-StyledSubHeader {
    param([string]$Text, [string]$Color = "Yellow")
    $fg = Get-ConsoleColor $Color 'Yellow'
    Write-Host "`n--- $Text ---" -ForegroundColor $fg
}

# Función para parsear flow tuples
function Parse-FlowTuple {
    param([string]$Tuple)
   
    $parts = $Tuple -split ','
    if ($parts.Count -ge 13) {
        return [PSCustomObject]@{
            Timestamp = $parts[0]
            SourceIP = $parts[1]
            DestIP = $parts[2]
            SourcePort = $parts[3]
            DestPort = $parts[4]
            Protocol = $parts[5]
            Direction = $parts[6]
            Action = $parts[7]
            FlowState = $parts[8]
            PacketsSourceToDest = $parts[9]
            BytesSourceToDest = $parts[10]
            PacketsDestToSource = $parts[11]
            BytesDestToSource = $parts[12]
        }
    }
    return $null
}

# Función para identificar servicios por IP/Puerto
function Get-ServiceIdentification {
    param([string]$IP, [string]$Port)
   
    $service = switch ($Port) {
        "80" { "HTTP" }
        "443" { "HTTPS" }
        "53" { "DNS" }
        "123" { "NTP" }
        "22" { "SSH" }
        "3389" { "RDP" }
        "25" { "SMTP" }
        "21" { "FTP" }
        "23" { "Telnet" }
        "110" { "POP3" }
        "143" { "IMAP" }
        "993" { "IMAPS" }
        "995" { "POP3S" }
        default { "Port-$Port" }
    }
   
    $provider = switch -Regex ($IP) {
        "^208\.67\.(220|222)\.220$" { "OpenDNS" }
        "^8\.8\.[48]\.8$" { "Google DNS" }
        "^1\.1\.1\.1$" { "Cloudflare DNS" }
        "^52\." { "Microsoft Azure" }
        "^20\." { "Microsoft Azure" }
        "^40\." { "Microsoft Azure" }
        "^104\." { "Microsoft Azure" }
        "^13\." { "Microsoft Azure" }
        "^34\." { "Google Cloud Platform" }
        "^35\." { "Google Cloud Platform" }
        "^54\." { "Amazon Web Services" }
        "^18\." { "Amazon Web Services" }
        "^3\." { "Amazon Web Services" }
        "^64\.39\.106\.233$" { "NTP Pool" }
        "^23\." { "Akamai CDN" }
        "^172\.16\." { "RFC1918 Private" }
        "^192\.168\." { "RFC1918 Private" }
        "^10\." { "RFC1918 Private" }
        default { "Unknown/Public" }
    }
   
    return "$service ($provider)"
}

# Función para calcular estadísticas de tráfico
function Get-TrafficStatistics {
    param([object[]]$Flows)
   
    $stats = @{
        TotalFlows = $Flows.Count
        UniqueSourceIPs = ($Flows | Select-Object -ExpandProperty SourceIP -Unique).Count
        UniqueDestIPs = ($Flows | Select-Object -ExpandProperty DestIP -Unique).Count
        TotalBytesSourceToDest = ($Flows | Where-Object { $_.BytesSourceToDest -ne $null } | Measure-Object -Property BytesSourceToDest -Sum).Sum
        TotalBytesDestToSource = ($Flows | Where-Object { $_.BytesDestToSource -ne $null } | Measure-Object -Property BytesDestToSource -Sum).Sum
        TotalPacketsSourceToDest = ($Flows | Where-Object { $_.PacketsSourceToDest -ne $null } | Measure-Object -Property PacketsSourceToDest -Sum).Sum
        TotalPacketsDestToSource = ($Flows | Where-Object { $_.PacketsDestToSource -ne $null } | Measure-Object -Property PacketsDestToSource -Sum).Sum
    }
   
    $stats.TotalBytes = $stats.TotalBytesSourceToDest + $stats.TotalBytesDestToSource
    $stats.TotalPackets = $stats.TotalPacketsSourceToDest + $stats.TotalPacketsDestToSource
   
    return $stats
}

# Función para detectar anomalías
function Find-TrafficAnomalies {
    param([object[]]$Flows)
   
    $anomalies = @{
        HighVolumeConnections = @()
        UnusualPorts = @()
        SuspiciousIPs = @()
        PortScanning = @()
        DeniedConnections = @()
    }
   
    # Conexiones de alto volumen (top 1% por bytes)
    $sortedByBytes = $Flows | Where-Object { $_.BytesSourceToDest -gt 0 } | Sort-Object BytesSourceToDest -Descending
    $top1Percent = [math]::Max(1, [math]::Floor($sortedByBytes.Count * 0.01))
    $anomalies.HighVolumeConnections = $sortedByBytes | Select-Object -First $top1Percent
   
    # Puertos inusuales (no estándar)
    $standardPorts = @("80", "443", "53", "123", "22", "3389", "25", "21", "110", "143", "993", "995")
    $anomalies.UnusualPorts = $Flows | Where-Object { $_.DestPort -notin $standardPorts } |
        Group-Object DestPort | Sort-Object Count -Descending | Select-Object -First 10
   
    # IPs sospechosas (muchas conexiones bloqueadas)
    $blockedFlows = $Flows | Where-Object { $_.Action -eq "B" }
    $anomalies.SuspiciousIPs = $blockedFlows | Group-Object SourceIP |
        Where-Object { $_.Count -gt 10 } | Sort-Object Count -Descending
   
    # Posible port scanning (mismo source IP, múltiples puertos de destino)
    $anomalies.PortScanning = $Flows | Group-Object SourceIP, DestIP |
        Where-Object { ($_.Group | Select-Object -ExpandProperty DestPort -Unique).Count -gt 5 } |
        Sort-Object { ($_.Group | Select-Object -ExpandProperty DestPort -Unique).Count } -Descending
   
    # Conexiones denegadas más frecuentes
    $anomalies.DeniedConnections = $blockedFlows | Group-Object SourceIP, DestIP, DestPort |
        Sort-Object Count -Descending | Select-Object -First 10
   
    return $anomalies
}

# Función para crear gráfico simple en consola
function Show-SimpleBarChart {
    param(
        [hashtable]$Data,
        [string]$Title,
        [int]$MaxBars = 10,
        [int]$MaxWidth = 50
    )
   
    if (-not $ShowGraphs) { return }
   
    $fg = Get-ConsoleColor $Colors.Info 'Cyan'
    Write-Host "`n📊 $Title" -ForegroundColor $fg
    Write-Host ("─" * 60) -ForegroundColor $fg
   
    $sortedData = $Data.GetEnumerator() | Sort-Object Value -Descending | Select-Object -First $MaxBars
    $maxValue = ($sortedData | Measure-Object -Property Value -Maximum).Maximum
   
    foreach ($item in $sortedData) {
        $barLength = [math]::Floor(($item.Value / $maxValue) * $MaxWidth)
        $bar = "█" * $barLength
        $label = $item.Key.ToString().PadRight(20)
    $fg = Get-ConsoleColor $Colors.Normal 'White'
    Write-Host "$label │$bar $($item.Value)" -ForegroundColor $fg
    }
    Write-Host ""
}

# Función principal de análisis
function Analyze-FlowLogs {
    param([string[]]$FilePaths)
   
    Write-StyledHeader "INICIANDO ANÁLISIS DE LOGS DE FLUJO DE AZURE VNet" "Green"
   
    # Variables para recopilar todos los flows
    $allFlows = @()
    $allRecords = @()
    $fileStats = @{}
   
    # Procesar cada archivo
    foreach ($filePath in $FilePaths) {
    $fg = Get-ConsoleColor $Colors.Info 'Cyan'
    Write-Host "📁 Procesando archivo: $filePath" -ForegroundColor $fg
       
        if (-not (Test-Path $filePath)) {
            $fg = Get-ConsoleColor $Colors.Warning 'Red'
            Write-Host "❌ Archivo no encontrado: $filePath" -ForegroundColor $fg
            continue
        }
       
        try {
            $jsonContent = Get-Content $filePath -Raw | ConvertFrom-Json
            $records = $jsonContent.records
            $allRecords += $records
           
            $fileFlows = @()
            foreach ($record in $records) {
                foreach ($flow in $record.flowRecords.flows) {
                    foreach ($flowGroup in $flow.flowGroups) {
                        foreach ($tuple in $flowGroup.flowTuples) {
                            $parsedFlow = Parse-FlowTuple -Tuple $tuple
                            if ($parsedFlow) {
                                $parsedFlow | Add-Member -NotePropertyName "FileName" -NotePropertyValue (Split-Path $filePath -Leaf)
                                $parsedFlow | Add-Member -NotePropertyName "RecordTime" -NotePropertyValue $record.time
                                $parsedFlow | Add-Member -NotePropertyName "ACL_ID" -NotePropertyValue $flow.aclID
                                $parsedFlow | Add-Member -NotePropertyName "Rule" -NotePropertyValue $flowGroup.rule
                                $fileFlows += $parsedFlow
                                $allFlows += $parsedFlow
                            }
                        }
                    }
                }
            }
           
            $fileStats[$filePath] = @{
                Records = $records.Count
                Flows = $fileFlows.Count
                TimeRange = if ($records.Count -gt 0) {
                    "$($records[0].time) - $($records[-1].time)"
                } else { "No records" }
            }
           
            $fg = Get-ConsoleColor $Colors.Success 'Magenta'
            Write-Host "✅ Procesado: $($fileFlows.Count) flows de $($records.Count) records" -ForegroundColor $fg
           
        } catch {
            $fg = Get-ConsoleColor $Colors.Warning 'Red'
            Write-Host "❌ Error procesando $filePath : $($_.Exception.Message)" -ForegroundColor $fg
        }
    }
   
    if ($allFlows.Count -eq 0) {
    $fg = Get-ConsoleColor $Colors.Warning 'Red'
    Write-Host "❌ No se encontraron flows válidos en los archivos proporcionados" -ForegroundColor $fg
        return
    }
   
    # ANÁLISIS GENERAL
    Write-StyledHeader "RESUMEN GENERAL" "Green"
    $fg = Get-ConsoleColor $Colors.Info 'Cyan'
    Write-Host "📊 Archivos procesados: $($FilePaths.Count)" -ForegroundColor $fg
    Write-Host "📊 Total de records: $($allRecords.Count)" -ForegroundColor $fg
    Write-Host "📊 Total de flows: $($allFlows.Count)" -ForegroundColor $fg
   
    if ($allRecords.Count -gt 0) {
        $firstRecord = ($allRecords | Sort-Object time)[0]
        $lastRecord = ($allRecords | Sort-Object time)[-1]
    $fg = Get-ConsoleColor $Colors.Info 'Cyan'
    Write-Host "⏰ Período analizado: $($firstRecord.time) - $($lastRecord.time)" -ForegroundColor $fg
    }
   
    # Estadísticas por archivo
    Write-StyledSubHeader "ESTADÍSTICAS POR ARCHIVO" $Colors.Subheader
    foreach ($file in $fileStats.GetEnumerator()) {
    $fg = Get-ConsoleColor $Colors.Normal 'White'
    Write-Host "📄 $(Split-Path $file.Key -Leaf):" -ForegroundColor $fg
    Write-Host "   Records: $($file.Value.Records)" -ForegroundColor $fg
    Write-Host "   Flows: $($file.Value.Flows)" -ForegroundColor $fg
    Write-Host "   Período: $($file.Value.TimeRange)" -ForegroundColor $fg
        Write-Host ""
    }
   
    # ANÁLISIS DE TRÁFICO
    Write-StyledHeader "ANÁLISIS DE PATRONES DE TRÁFICO" "Green"
   
    $stats = Get-TrafficStatistics -Flows $allFlows
   
    Write-StyledSubHeader "ESTADÍSTICAS GENERALES" $Colors.Subheader
    $fg = Get-ConsoleColor $Colors.Normal 'White'
    Write-Host "🔢 Total de flows: $($stats.TotalFlows)" -ForegroundColor $fg
    Write-Host "🖥️  IPs de origen únicas: $($stats.UniqueSourceIPs)" -ForegroundColor $fg
    Write-Host "🌐 IPs de destino únicas: $($stats.UniqueDestIPs)" -ForegroundColor $fg
    Write-Host "📊 Total de bytes transferidos: $([math]::Round($stats.TotalBytes / 1MB, 2)) MB" -ForegroundColor $fg
    Write-Host "📦 Total de paquetes: $($stats.TotalPackets)" -ForegroundColor $fg
   
    # ANÁLISIS DE PROTOCOLOS
    Write-StyledSubHeader "ANÁLISIS DE PROTOCOLOS" $Colors.Subheader
    $protocolCounts = @{}
    $allFlows | Group-Object Protocol | ForEach-Object {
        $protocolName = switch ($_.Name) {
            "6" { "TCP" }
            "17" { "UDP" }
            "1" { "ICMP" }
            default { "Protocol-$($_.Name)" }
        }
        $protocolCounts[$protocolName] = $_.Count
        Write-Host "$protocolName : $($_.Count) flows ($([math]::Round(($_.Count / $stats.TotalFlows) * 100, 1))%)" -ForegroundColor $Colors.Normal
    }
   
    Show-SimpleBarChart -Data $protocolCounts -Title "Distribución de Protocolos"
   
    # ANÁLISIS DE ACCIONES
    Write-StyledSubHeader "ANÁLISIS DE ACCIONES DE SEGURIDAD" $Colors.Subheader
    $actionCounts = @{}
    $allFlows | Group-Object Action | ForEach-Object {
        $actionName = switch ($_.Name) {
            "E" { "PERMITIDO (Established)" }
            "B" { "BLOQUEADO/INICIADO (Begin)" }
            "C" { "CONTINUADO (Continue)" }
            "D" { "DENEGADO (Denied)" }
            default { $_.Name }
        }
        $actionCounts[$actionName] = $_.Count
        $color = switch ($_.Name) {
            "E" { $Colors.Success }
            "B" { $Colors.Warning }
            "D" { $Colors.Warning }
            default { $Colors.Normal }
        }
        Write-Host "$actionName : $($_.Count) flows ($([math]::Round(($_.Count / $stats.TotalFlows) * 100, 1))%)" -ForegroundColor $color
    }
   
    Show-SimpleBarChart -Data $actionCounts -Title "Distribución de Acciones"
   
    # ANÁLISIS DE DIRECCIONES
    Write-StyledSubHeader "ANÁLISIS DE DIRECCIONES" $Colors.Subheader
    $directionCounts = @{}
    $allFlows | Group-Object Direction | ForEach-Object {
        $dirName = switch ($_.Name) {
            "I" { "ENTRANTE (Inbound)" }
            "O" { "SALIENTE (Outbound)" }
            default { $_.Name }
        }
        $directionCounts[$dirName] = $_.Count
        Write-Host "$dirName : $($_.Count) flows ($([math]::Round(($_.Count / $stats.TotalFlows) * 100, 1))%)" -ForegroundColor $Colors.Normal
    }
   
    # TOP SOURCE IPs
    Write-StyledSubHeader "TOP 15 IPs DE ORIGEN" $Colors.Subheader
    $topSourceIPs = @{}
    $allFlows | Group-Object SourceIP | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
        $topSourceIPs[$_.Name] = $_.Count
        Write-Host "$($_.Name.PadRight(20)) : $($_.Count) flows" -ForegroundColor $Colors.Normal
    }
   
    Show-SimpleBarChart -Data $topSourceIPs -Title "Top IPs de Origen"
   
    # TOP DESTINATION IPs con identificación de servicios
    Write-StyledSubHeader "TOP 15 IPs DE DESTINO CON IDENTIFICACIÓN" $Colors.Subheader
    $topDestIPs = @{}
    $allFlows | Group-Object DestIP | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
        $service = Get-ServiceIdentification -IP $_.Name -Port "443"  # Default para identificación
        $topDestIPs[$_.Name] = $_.Count
        Write-Host "$($_.Name.PadRight(20)) : $($_.Count) flows - $service" -ForegroundColor $Colors.Normal
    }
   
    Show-SimpleBarChart -Data $topDestIPs -Title "Top IPs de Destino"
   
    # TOP PUERTOS
    Write-StyledSubHeader "TOP 15 PUERTOS DE DESTINO" $Colors.Subheader
    $topPorts = @{}
    $allFlows | Group-Object DestPort | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
        $service = Get-ServiceIdentification -IP "0.0.0.0" -Port $_.Name
        $topPorts["Port-$($_.Name)"] = $_.Count
        Write-Host "Puerto $($_.Name.PadRight(8)) : $($_.Count) flows - $service" -ForegroundColor $Colors.Normal
    }
   
    Show-SimpleBarChart -Data $topPorts -Title "Top Puertos de Destino"
   
    # ANÁLISIS DE REGLAS DE SEGURIDAD
    Write-StyledSubHeader "ANÁLISIS DE REGLAS DE SEGURIDAD" $Colors.Subheader
    $ruleCounts = @{}
    $allFlows | Group-Object Rule | Sort-Object Count -Descending | ForEach-Object {
        $ruleCounts[$_.Name] = $_.Count
        Write-Host "$($_.Name.PadRight(40)) : $($_.Count) flows" -ForegroundColor $Colors.Normal
    }
   
    # ANÁLISIS DE CONEXIONES PROBLEMÁTICAS
    Write-StyledHeader "ANÁLISIS DE CONEXIONES PROBLEMÁTICAS" "Magenta"
   
    # Conexiones sin completar (Begin sin Established)
    Write-StyledSubHeader "CONEXIONES SIN COMPLETAR (BEGIN SIN ESTABLISHED)" $Colors.Subheader
    Write-Host "🔍 Analizando conexiones BEGIN..." -ForegroundColor $Colors.Info
   
    $beginConnections = $allFlows | Where-Object { $_.Action -eq "B" }
    Write-Host "📊 Encontradas $($beginConnections.Count) conexiones BEGIN. Agrupando..." -ForegroundColor $Colors.Info
   
    $groupedBeginConnections = $beginConnections | Group-Object SourceIP, DestIP, DestPort
    Write-Host "🔍 Verificando cuáles no tienen ESTABLISHED correspondiente..." -ForegroundColor $Colors.Info
   
    $processedCount = 0
    $incompleteConnections = $groupedBeginConnections |
        Where-Object {
            $processedCount++
            if ($processedCount % 100 -eq 0) {
                Write-Host "⏳ Procesadas $processedCount de $($groupedBeginConnections.Count) conexiones..." -ForegroundColor $Colors.Info
            }
           
            $key = "$($_.Name)"
            $establishedExists = $allFlows | Where-Object {
                $_.Action -eq "E" -and
                "$($_.SourceIP),$($_.DestIP),$($_.DestPort)" -eq $key
            }
            return $establishedExists.Count -eq 0
        } | Sort-Object Count -Descending | Select-Object -First 15
   
    Write-Host "✅ Análisis de conexiones sin completar finalizado." -ForegroundColor $Colors.Success
   
    if ($incompleteConnections.Count -gt 0) {
        $incompleteConnections | ForEach-Object {
            $parts = $_.Name -split ','
            $sourceIP = $parts[0]
            $destIP = $parts[1]
            $destPort = $parts[2]
            $service = Get-ServiceIdentification -IP $destIP -Port $destPort
            Write-Host "🔄 $sourceIP → $destIP`:$destPort - $($_.Count) intentos sin completar - $service" -ForegroundColor $Colors.Warning
        }
    } else {
        Write-Host "✅ No se encontraron conexiones sin completar significativas" -ForegroundColor $Colors.Success
    }
   
    # Conexiones denegadas (Denied)
    Write-StyledSubHeader "CONEXIONES DENEGADAS (DENIED)" $Colors.Subheader
    $deniedConnections = $allFlows | Where-Object { $_.Action -eq "D" } |
        Group-Object SourceIP, DestIP, DestPort | Sort-Object Count -Descending | Select-Object -First 15
   
    if ($deniedConnections.Count -gt 0) {
        $deniedConnections | ForEach-Object {
            $parts = $_.Name -split ','
            $sourceIP = $parts[0]
            $destIP = $parts[1]
            $destPort = $parts[2]
            $service = Get-ServiceIdentification -IP $destIP -Port $destPort
            Write-Host "🚫 $sourceIP → $destIP`:$destPort - $($_.Count) denegaciones - $service" -ForegroundColor $Colors.Error
        }
    } else {
        Write-Host "✅ No se encontraron conexiones denegadas" -ForegroundColor $Colors.Success
    }
   
    # Conexiones con drops (alto número de paquetes perdidos)
    Write-StyledSubHeader "CONEXIONES CON DROPS (PÉRDIDA DE PAQUETES)" $Colors.Subheader
    $connectionsWithDrops = $allFlows | Where-Object {
        $_.Packets -gt 0 -and $_.Bytes -gt 0 -and
        ([int]$_.Bytes / [math]::Max([int]$_.Packets, 1)) -lt 100  # Ratio bajo indica drops
    } | Group-Object SourceIP, DestIP, DestPort | Sort-Object Count -Descending | Select-Object -First 15
   
    if ($connectionsWithDrops.Count -gt 0) {
        $connectionsWithDrops | ForEach-Object {
            $parts = $_.Name -split ','
            $sourceIP = $parts[0]
            $destIP = $parts[1]
            $destPort = $parts[2]
            $relatedFlows = $allFlows | Where-Object {
                $_.SourceIP -eq $sourceIP -and $_.DestIP -eq $destIP -and $_.DestPort -eq $destPort
            }
            $avgBytesPerPacket = ($relatedFlows | Measure-Object -Property Bytes -Sum).Sum /
                                [math]::Max(($relatedFlows | Measure-Object -Property Packets -Sum).Sum, 1)
            $service = Get-ServiceIdentification -IP $destIP -Port $destPort
            Write-Host "📉 $sourceIP → $destIP`:$destPort - $($_.Count) flows sospechosos (avg: $([math]::Round($avgBytesPerPacket, 1)) bytes/pkt) - $service" -ForegroundColor $Colors.Warning
        }
    } else {
        Write-Host "✅ No se detectaron patrones de drops significativos" -ForegroundColor $Colors.Success
    }
   
    # Conexiones con reintentos excesivos (múltiples Begin para misma tupla)
    Write-StyledSubHeader "CONEXIONES CON REINTENTOS EXCESIVOS" $Colors.Subheader
    $excessiveRetries = $allFlows | Where-Object { $_.Action -eq "B" } |
        Group-Object SourceIP, DestIP, DestPort | Where-Object { $_.Count -gt 10 } |
        Sort-Object Count -Descending | Select-Object -First 15
   
    if ($excessiveRetries.Count -gt 0) {
        $excessiveRetries | ForEach-Object {
            $parts = $_.Name -split ','
            $sourceIP = $parts[0]
            $destIP = $parts[1]
            $destPort = $parts[2]
            $service = Get-ServiceIdentification -IP $destIP -Port $destPort
            Write-Host "🔄 $sourceIP → $destIP`:$destPort - $($_.Count) reintentos - $service" -ForegroundColor $Colors.Error
        }
    } else {
        Write-Host "✅ No se detectaron reintentos excesivos" -ForegroundColor $Colors.Success
    }
   
    # Conexiones asimétricas (solo en una dirección)
    Write-StyledSubHeader "CONEXIONES ASIMÉTRICAS (UNA DIRECCIÓN)" $Colors.Subheader
    Write-Host "🔍 Analizando conexiones asimétricas..." -ForegroundColor $Colors.Info
   
    $asymmetricConnections = @()
    $connectionPairs = $allFlows | Group-Object SourceIP, DestIP | Where-Object { $_.Count -gt 5 }
    Write-Host "📊 Analizando $($connectionPairs.Count) pares de conexiones..." -ForegroundColor $Colors.Info
   
    $processedPairs = 0
    foreach ($pair in $connectionPairs) {
        $processedPairs++
        if ($processedPairs % 50 -eq 0) {
            Write-Host "⏳ Procesados $processedPairs de $($connectionPairs.Count) pares..." -ForegroundColor $Colors.Info
        }
       
        $parts = $pair.Name -split ','
        $sourceIP = $parts[0]
        $destIP = $parts[1]
       
        # Buscar tráfico en dirección opuesta
        $reverseTraffic = $allFlows | Where-Object {
            $_.SourceIP -eq $destIP -and $_.DestIP -eq $sourceIP
        }
       
        if ($reverseTraffic.Count -eq 0) {
            $asymmetricConnections += [PSCustomObject]@{
                Source = $sourceIP
                Destination = $destIP
                Count = $pair.Count
            }
        }
    }
   
    Write-Host "✅ Análisis de conexiones asimétricas completado." -ForegroundColor $Colors.Success
   
    if ($asymmetricConnections.Count -gt 0) {
        $asymmetricConnections | Sort-Object Count -Descending | Select-Object -First 15 | ForEach-Object {
            Write-Host "⚖️  $($_.Source) → $($_.Destination) - $($_.Count) flows (sin respuesta)" -ForegroundColor $Colors.Warning
        }
    } else {
        Write-Host "✅ No se detectaron conexiones asimétricas significativas" -ForegroundColor $Colors.Success
    }
   
    # ANÁLISIS DE ANOMALÍAS
    Write-StyledHeader "DETECCIÓN DE ANOMALÍAS Y PATRONES SOSPECHOSOS" "Red"
   
    $anomalies = Find-TrafficAnomalies -Flows $allFlows
   
    Write-StyledSubHeader "CONEXIONES DE ALTO VOLUMEN (Top 1%)" $Colors.Warning
    if ($anomalies.HighVolumeConnections.Count -gt 0) {
        $anomalies.HighVolumeConnections | Select-Object -First 10 | ForEach-Object {
            $totalBytes = [int]$_.BytesSourceToDest + [int]$_.BytesDestToSource
            Write-Host "🚨 $($_.SourceIP) → $($_.DestIP):$($_.DestPort) - $([math]::Round($totalBytes / 1KB, 2)) KB" -ForegroundColor $Colors.Warning
        }
    } else {
        Write-Host "✅ No se detectaron conexiones de alto volumen anómalas" -ForegroundColor $Colors.Success
    }
   
    Write-StyledSubHeader "PUERTOS INUSUALES" $Colors.Warning
    if ($anomalies.UnusualPorts.Count -gt 0) {
        $anomalies.UnusualPorts | ForEach-Object {
            Write-Host "🔍 Puerto $($_.Name) : $($_.Count) conexiones" -ForegroundColor $Colors.Warning
        }
    } else {
        Write-Host "✅ Solo se detectaron puertos estándar" -ForegroundColor $Colors.Success
    }
   
    Write-StyledSubHeader "IPs CON MUCHAS CONEXIONES BLOQUEADAS" $Colors.Warning
    if ($anomalies.SuspiciousIPs.Count -gt 0) {
        $anomalies.SuspiciousIPs | Select-Object -First 10 | ForEach-Object {
            Write-Host "⚠️  $($_.Name) : $($_.Count) conexiones bloqueadas" -ForegroundColor $Colors.Warning
        }
    } else {
        Write-Host "✅ No se detectaron IPs con patrones sospechosos de bloqueo" -ForegroundColor $Colors.Success
    }
   
    Write-StyledSubHeader "POSIBLE PORT SCANNING" $Colors.Warning
    if ($anomalies.PortScanning.Count -gt 0) {
        $anomalies.PortScanning | Select-Object -First 5 | ForEach-Object {
            $sourceIP = ($_.Name -split ', ')[0]
            $destIP = ($_.Name -split ', ')[1]
            $uniquePorts = ($_.Group | Select-Object -ExpandProperty DestPort -Unique).Count
            Write-Host "🕵️  $sourceIP → $destIP : $uniquePorts puertos diferentes" -ForegroundColor $Colors.Warning
        }
    } else {
        Write-Host "✅ No se detectaron patrones de port scanning" -ForegroundColor $Colors.Success
    }
   
    # ANÁLISIS DE IPs ESPECÍFICAS (si se proporcionaron)
    if ($SpecificIPs.Count -gt 0) {
        Write-StyledHeader "ANÁLSIS DE IPs ESPECÍFICAS" "Magenta"
       
        foreach ($targetIP in $SpecificIPs) {
            Write-StyledSubHeader "ANÁLISIS DE IP: $targetIP" $Colors.Info
           
            $specificFlows = $allFlows | Where-Object { $_.SourceIP -eq $targetIP -or $_.DestIP -eq $targetIP }
           
            if ($specificFlows.Count -gt 0) {
                Write-Host "✅ Encontrados $($specificFlows.Count) flows para la IP $targetIP" -ForegroundColor $Colors.Success
               
                $asSource = $specificFlows | Where-Object { $_.SourceIP -eq $targetIP }
                $asDest = $specificFlows | Where-Object { $_.DestIP -eq $targetIP }
               
                Write-Host "   Como origen: $($asSource.Count) flows" -ForegroundColor $Colors.Normal
                Write-Host "   Como destino: $($asDest.Count) flows" -ForegroundColor $Colors.Normal
               
                # Top conexiones de esta IP
                if ($asSource.Count -gt 0) {
                    Write-Host "   Top destinos desde $targetIP :" -ForegroundColor $Colors.Info
                    $asSource | Group-Object DestIP | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object {
                        Write-Host "     $($_.Name) : $($_.Count) conexiones" -ForegroundColor $Colors.Normal
                    }
                }
               
                if ($asDest.Count -gt 0) {
                    Write-Host "   Top orígenes hacia $targetIP :" -ForegroundColor $Colors.Info
                    $asDest | Group-Object SourceIP | Sort-Object Count -Descending | Select-Object -First 5 | ForEach-Object {
                        Write-Host "     $($_.Name) : $($_.Count) conexiones" -ForegroundColor $Colors.Normal
                    }
                }
            } else {
                Write-Host "❌ No se encontró tráfico para la IP $targetIP" -ForegroundColor $Colors.Warning
            }
            Write-Host ""
        }
    }
   
    # EXPORTAR A CSV SI SE SOLICITA
    if ($ExportCSV) {
        Write-StyledHeader "EXPORTANDO RESULTADOS" "Cyan"
       
        $outputDir = if ($OutputPath) { $OutputPath } else { "." }
        $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
       
    # Export flows detallados
    $csvFile = Join-Path $outputDir "VNetFlowAnalysis_Details_$timestamp.csv"
        $allFlows | Export-Csv -Path $csvFile -NoTypeInformation -Encoding UTF8
        Write-Host "📄 Flows detallados exportados a: $csvFile" -ForegroundColor $Colors.Success
       
    # Export resumen
    $summaryFile = Join-Path $outputDir "VNetFlowAnalysis_Summary_$timestamp.csv"
        $summary = @()
        $summary += [PSCustomObject]@{ Metric = "Total Flows"; Value = $stats.TotalFlows }
        $summary += [PSCustomObject]@{ Metric = "Unique Source IPs"; Value = $stats.UniqueSourceIPs }
        $summary += [PSCustomObject]@{ Metric = "Unique Dest IPs"; Value = $stats.UniqueDestIPs }
        $summary += [PSCustomObject]@{ Metric = "Total Bytes (MB)"; Value = [math]::Round($stats.TotalBytes / 1MB, 2) }
        $summary += [PSCustomObject]@{ Metric = "Total Packets"; Value = $stats.TotalPackets }
       
        $summary | Export-Csv -Path $summaryFile -NoTypeInformation -Encoding UTF8
        Write-Host "📊 Resumen exportado a: $summaryFile" -ForegroundColor $Colors.Success
    }
   
    Write-StyledHeader "ANÁLISIS COMPLETADO" "Green"
    Write-Host "🎯 Se analizaron $($allFlows.Count) flows de $($FilePaths.Count) archivo(s)" -ForegroundColor $Colors.Success
    Write-Host "⏱️  Período total analizado: $(if ($allRecords.Count -gt 0) { "$($($allRecords | Sort-Object time)[0].time) - $($($allRecords | Sort-Object time)[-1].time)" } else { "N/A" })" -ForegroundColor $Colors.Info
   
}

# EJECUCIÓN PRINCIPAL
try {
    # Expandir wildcards en rutas de archivos
    $expandedFiles = @()
    foreach ($logFile in $LogFiles) {
        if ($logFile.Contains("*") -or $logFile.Contains("?")) {
            $expandedFiles += Get-ChildItem -Path $logFile -File | Select-Object -ExpandProperty FullName
        } else {
            $expandedFiles += $logFile
        }
    }
   
    if ($expandedFiles.Count -eq 0) {
        Write-Host "❌ No se encontraron archivos que coincidan con los patrones especificados" -ForegroundColor Red
        exit 1
    }
   
    Write-Host "🔍 Archivos a procesar:" -ForegroundColor Cyan
    $expandedFiles | ForEach-Object { Write-Host "   $_" -ForegroundColor White }
    Write-Host ""
   
    # Ejecutar análisis
    Analyze-FlowLogs -FilePaths $expandedFiles
   
} catch {
    Write-Host "❌ Error durante el análisis: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Stack trace: $($_.Exception.StackTrace)" -ForegroundColor Red
    exit 1
}


