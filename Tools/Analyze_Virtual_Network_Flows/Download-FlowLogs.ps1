#Requires -Version 5.1
<#
.SYNOPSIS
    Descarga Flow Logs manejando rutas largas de Windows

.DESCRIPTION
    Script que descarga archivos de Flow Logs y reorganiza la estructura para evitar
    problemas de rutas largas en Windows y mantener una estructura limpia.

    Nota: si la variable de entorno AZ_STORAGE_KEY no está definida, el script
    intentará descubrir automáticamente el resource group de la cuenta de
    almacenamiento mediante 'az storage account show' y obtener una account key
    vía 'az storage account keys list' (requiere az CLI y permisos adecuados).

.PARAMETER StorageAccount
    Nombre de la cuenta de almacenamiento

.PARAMETER ContainerName
    Nombre del contenedor

.PARAMETER DownloadPath
    Ruta local de descarga

.EXAMPLE
    .\Download-FlowLogs.ps1 -StorageAccount "stflowlog" -DownloadPath ".\FlowLogs"

.NOTES
    Autor: Rafael Fernández (@rfernandezdo)
    Versión: 1.1
    Última actualización: 2025-10-01
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$StorageAccount,
   
    [Parameter(Mandatory = $false)]
    [string]$ContainerName = "insights-logs-flowlogflowevent",
   
    [Parameter(Mandatory = $false)]
    [string]$DownloadPath = ".\FlowLogs"
    ,
    [Parameter(Mandatory = $false)]
    [switch]$AutoShorten
    ,
    [Parameter(Mandatory = $false)]
    [switch]$Force
)

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN" { "Yellow" }
        "SUCCESS" { "Green" }
        "INFO" { "Cyan" }
        default { "White" }
    }
    $icon = switch ($Level) {
        "ERROR" { "❌" }
        "WARN" { "⚠️" }
        "SUCCESS" { "✅" }
        "INFO" { "ℹ️" }
        default { "📝" }
    }
    Write-Host "[$timestamp] $icon $Message" -ForegroundColor $color
}

Write-Host ""
Write-Host "=" * 60 -ForegroundColor Green
Write-Host "    DESCARGA FINAL DE FLOW LOGS - MANEJO DE RUTAS LARGAS    " -ForegroundColor Green  
Write-Host "=" * 60 -ForegroundColor Green
Write-Host ""

Write-Log "📁 Ruta de descarga: $DownloadPath" "INFO"
Write-Log "🗂️  Storage Account: $StorageAccount" "INFO"
Write-Log "📦 Container: $ContainerName" "INFO"
Write-Host ""

# --- Enhanced: prepare local paths and temp staging
# Crear directorio base
if (-not (Test-Path $DownloadPath)) {
    New-Item -Path $DownloadPath -ItemType Directory -Force | Out-Null
    Write-Log "Creado directorio base: $DownloadPath" "SUCCESS"
}

# Crear directorio temporal para descarga (plano)
$tempDownloadPath = Join-Path $DownloadPath "temp_download"
if (-not (Test-Path $tempDownloadPath)) {
    New-Item -Path $tempDownloadPath -ItemType Directory -Force | Out-Null
    Write-Log "Creado directorio temporal: $tempDownloadPath" "SUCCESS"
}

Write-Log "Iniciando descarga a directorio temporal (plano)" "INFO"

# Small helper: determine max path length and evaluate a candidate full path
function Test-PathLength {
    param([string]$PathToTest)
    # Conservative limit for Windows paths (without long-path opt) is 260. Reserve room for operations.
    $max = 250
    return ($PathToTest.Length -le $max)
}

# Helper: list blobs with optional account-key or auth-mode login
function Get-BlobList {
    param(
        [string]$StorageAccount,
        [string]$Container,
        [string]$AccountKey = $null
    )
    try {
        Write-Log "Listando blobs en contenedor: $Container" "INFO"
        if ($AccountKey) {
            $json = az storage blob list --account-name $StorageAccount --container-name $Container --account-key $AccountKey --output json 2>$null
        } else {
            $json = az storage blob list --account-name $StorageAccount --container-name $Container --auth-mode login --output json 2>$null
        }
        if (-not $json) { return @() }
        $blobs = $json | ConvertFrom-Json
        return $blobs
    } catch {
        Write-Log "Error listando blobs: $($_.Exception.Message)" "ERROR"
        return @()
    }
}

# Helper: download single blob preserving structure to a target base path. Returns hashtable with status and messages.
function Download-BlobWithStructure {
    param(
        [object]$Blob,
        [string]$StorageAccount,
        [string]$Container,
        [string]$LocalBasePath,
        [string]$AccountKey = $null
    )
    try {
        $blobName = $Blob.name
        $localPath = Join-Path $LocalBasePath $blobName

        # Ensure target directory exists
        $localDir = Split-Path $localPath -Parent
        if (-not (Test-Path $localDir)) { New-Item -Path $localDir -ItemType Directory -Force | Out-Null }

        # Check path length; if too long, return special code so caller can decide
        if (-not (Test-PathLength $localPath)) {
            return @{ Success = $false; PathTooLong = $true; Message = "PathTooLong"; LocalPath = $localPath; BlobName = $blobName }
        }

        # If exists and same size, skip
        if (Test-Path $localPath) {
            $localSize = (Get-Item $localPath).Length
            $blobSize = [long]$Blob.properties.contentLength
            if ($localSize -eq $blobSize) { return @{ Success = $true; Skipped = $true; Message = "Exists" } }
        }

        # Build az command
        if ($AccountKey) {
            $cmd = "az storage blob download --account-name `"$StorageAccount`" --container-name `"$Container`" --name `"$blobName`" --file `"$localPath`" --account-key `"$AccountKey`" --output none"
        } else {
            $cmd = "az storage blob download --account-name `"$StorageAccount`" --container-name `"$Container`" --name `"$blobName`" --file `"$localPath`" --auth-mode login --output none"
        }

        $null = Invoke-Expression $cmd 2>$null
        if ($LASTEXITCODE -eq 0 -and (Test-Path $localPath)) {
            $downloadedSize = (Get-Item $localPath).Length
            if ($downloadedSize -eq [long]$Blob.properties.contentLength) {
                return @{ Success = $true; Skipped = $false; Message = "Downloaded"; LocalPath = $localPath }
            } else {
                return @{ Success = $false; Message = "SizeMismatch" }
            }
        } else {
            return @{ Success = $false; Message = "AzCliFailed" }
        }

    } catch {
        return @{ Success = $false; Message = "Error: $($_.Exception.Message)" }
    }
}

# Try to obtain account key (best-effort). Returns null on failure.
function Try-GetAccountKey {
    param([string]$StorageAccount, [string]$ResourceGroup)
    try {
        # If explicit resource group provided, try directly
        if ($ResourceGroup) {
            $key = az storage account keys list --account-name $StorageAccount --resource-group $ResourceGroup --query "[0].value" -o tsv 2>$null
            if ($LASTEXITCODE -eq 0 -and $key) { return $key }
        }

        # Attempt to discover resource group via az if not provided
        Write-Log "Intentando descubrir ResourceGroup para la cuenta $StorageAccount" "INFO"
        $acctJson = az storage account show --name $StorageAccount --output json 2>$null
        if ($acctJson) {
            $acct = $acctJson | ConvertFrom-Json
            if ($acct.resourceGroup) {
                Write-Log "ResourceGroup detectado: $($acct.resourceGroup)" "INFO"
                $rg = $acct.resourceGroup
                $key = az storage account keys list --account-name $StorageAccount --resource-group $rg --query "[0].value" -o tsv 2>$null
                if ($LASTEXITCODE -eq 0 -and $key) { return $key }
            }
        }

        return $null
    } catch {
        return $null
    }
}

# Attempt download: prefer account key if provided via environment var or discoverable; fallback to login.
$accountKey = $env:AZ_STORAGE_KEY
if (-not $accountKey) {
    # Try discovering key if resource group is stored in env (best-effort). The original script did not have ResourceGroup param; check env var.
    $rg = $env:AZ_RESOURCE_GROUP
    $accountKey = Try-GetAccountKey -StorageAccount $StorageAccount -ResourceGroup $rg
}

# Obtain blob list
$blobs = Get-BlobList -StorageAccount $StorageAccount -Container $ContainerName -AccountKey $accountKey
if (-not $blobs -or $blobs.Count -eq 0) {
    Write-Log "No se encontraron blobs en el contenedor (o no se pudo listar). Asegúrate de tener permisos o proporciona la clave de cuenta en la variable de entorno AZ_STORAGE_KEY." "ERROR"
    exit 1
}

Write-Log "Se encontraron $($blobs.Count) blobs. Preparando descarga (se respetará la estructura de nombres)." "INFO"

# Confirm intent
$confirm = Read-Host "¿Descargar todos los blobs manteniendo la estructura de carpetas localmente? (s/N)"
if ($confirm -notlike "s*" -and $confirm -notlike "y*") {
    Write-Log "Descarga cancelada por el usuario" "WARN"
    exit 0
}

# Limit for interactive path-shortening prompts
$interactiveShortenLimit = 500

# Start per-blob download to temp folder preserving structure in names
$downloaded = 0; $skipped = 0; $failed = 0; $pathTooLong = 0

foreach ($blob in $blobs) {
    $res = Download-BlobWithStructure -Blob $blob -StorageAccount $StorageAccount -Container $ContainerName -LocalBasePath $tempDownloadPath -AccountKey $accountKey
    if ($res.PathTooLong) {
        $pathTooLong++
        # Decide how to handle long paths: interactive or automatic truncation/hashing
        $candidateFull = $res.LocalPath
        Write-Log "Ruta local demasiado larga para Windows: $candidateFull" "WARN"

        if ($AutoShorten -or $Force) {
            # Non-interactive mode: always hash to a short name
            $choice = "2"
        } elseif ($pathTooLong -le $interactiveShortenLimit) {
            Write-Host "Opciones para acortar la ruta:`n 1) Ignorar componente de subcarpeta intermedia(s) (auto) `n 2) Usar nombre corto hash (recomendado) `n 3) Omitir este archivo`n 4) Salir y revisar manualmente" -ForegroundColor Yellow
            $choice = Read-Host "Elige 1/2/3/4 (por defecto 2)"
        } else {
            # Default to hashing after a few prompts
            $choice = "2"
        }

        switch ($choice) {
            "1" {
                # Remove intermediate folders, keep leaf filename
                $leaf = Split-Path $res.BlobName -Leaf
                $shortLocal = Join-Path $tempDownloadPath $leaf
            }
            "3" {
                Write-Log "Omitiendo $($res.BlobName) por path largo" "WARN"
                $failed++
                continue
            }
            "4" {
                Write-Log "Operación interrumpida por el usuario (revisa rutas manualmente)" "ERROR"
                exit 2
            }
            default {
                # Hash the full blob name to a short folder + leaf
                $hash = [System.BitConverter]::ToString((New-Object -TypeName System.Security.Cryptography.SHA1Managed).ComputeHash([System.Text.Encoding]::UTF8.GetBytes($res.BlobName))).Replace("-","").Substring(0,12)
                $leaf = Split-Path $res.BlobName -Leaf
                $shortLocal = Join-Path $tempDownloadPath ("$hash`_$leaf")
            }
        }

        # Attempt to download to the shortened path
        try {
            $localDir = Split-Path $shortLocal -Parent
            if (-not (Test-Path $localDir)) { New-Item -Path $localDir -ItemType Directory -Force | Out-Null }
            if ($accountKey) {
                $cmd = "az storage blob download --account-name `"$StorageAccount`" --container-name `"$ContainerName`" --name `"$($res.BlobName)`" --file `"$shortLocal`" --account-key `"$accountKey`" --output none"
            } else {
                $cmd = "az storage blob download --account-name `"$StorageAccount`" --container-name `"$ContainerName`" --name `"$($res.BlobName)`" --file `"$shortLocal`" --auth-mode login --output none"
            }
            $null = Invoke-Expression $cmd 2>$null
            if ($LASTEXITCODE -eq 0 -and (Test-Path $shortLocal)) { $downloaded++ } else { $failed++ }
        } catch {
            Write-Log "Error descargando con ruta corta: $($_.Exception.Message)" "ERROR"
            $failed++
        }

        continue
    }

    if ($res.Success) { $downloaded++ } else { $failed++ }
}

Write-Log "Descarga completada (temporal). Descargados: $downloaded, Saltados: $skipped, Errores: $failed, PathTooLong events: $pathTooLong" "INFO"

## Move downloaded files from temp_download into structured folders
$downloadedFiles = Get-ChildItem $tempDownloadPath -File -Filter "*.json" -ErrorAction SilentlyContinue

if (-not $downloadedFiles -or $downloadedFiles.Count -eq 0) {
    Write-Log "No se encontraron archivos en el directorio temporal. Nada que organizar." "WARN"
} else {
    Write-Log "Organizando $($downloadedFiles.Count) archivos descargados por fecha..." "INFO"
    $organizedCount = 0
    foreach ($file in $downloadedFiles) {
        try {
            $moved = $false
            # Intentar extraer fecha desde el contenido JSON
            try {
                $content = Get-Content $file.FullName -Raw -ErrorAction Stop
                $json = $content | ConvertFrom-Json -ErrorAction Stop
                if ($json -and $json.records -and $json.records.Count -gt 0) {
                    $recordTime = $json.records[0].time
                    if ($recordTime) {
                        $date = [DateTime]::Parse($recordTime)
                        $dateFolder = $date.ToString("yyyy-MM-dd")
                        $hourFolder = $date.ToString("HH")
                        $targetDir = Join-Path $DownloadPath "$dateFolder\$hourFolder"
                        if (-not (Test-Path $targetDir)) { New-Item -Path $targetDir -ItemType Directory -Force | Out-Null }
                        $timestamp = $date.ToString("HHmmss")
                        $newFileName = "FlowLog_$timestamp`_$($file.Name)"
                        $targetPath = Join-Path $targetDir $newFileName

                        if (-not (Test-PathLength $targetPath)) {
                            # If moving would create too long path, place in unknown or use short name
                            $unknownDir = Join-Path $DownloadPath "unknown"
                            if (-not (Test-Path $unknownDir)) { New-Item -Path $unknownDir -ItemType Directory -Force | Out-Null }
                            $targetPath = Join-Path $unknownDir $file.Name
                        }

                        Move-Item -Path $file.FullName -Destination $targetPath -Force
                        Write-Log "Movido: $newFileName -> $dateFolder/$hourFolder" "SUCCESS"
                        $moved = $true; $organizedCount++
                    }
                }
            } catch {
                # ignore parse errors and fall back to file timestamp
            }

            if (-not $moved) {
                $fileDate = $file.LastWriteTime
                $dateFolder = $fileDate.ToString("yyyy-MM-dd")
                $hourFolder = $fileDate.ToString("HH")
                $targetDir = Join-Path $DownloadPath "$dateFolder\$hourFolder"
                if (-not (Test-Path $targetDir)) { New-Item -Path $targetDir -ItemType Directory -Force | Out-Null }
                $newFileName = "FlowLog_$($fileDate.ToString('HHmmss'))_$($file.Name)"
                $targetPath = Join-Path $targetDir $newFileName

                if (-not (Test-PathLength $targetPath)) {
                    $unknownDir = Join-Path $DownloadPath "unknown"
                    if (-not (Test-Path $unknownDir)) { New-Item -Path $unknownDir -ItemType Directory -Force | Out-Null }
                    $targetPath = Join-Path $unknownDir $file.Name
                }

                Move-Item -Path $file.FullName -Destination $targetPath -Force
                Write-Log "Movido por timestamp: $newFileName -> $dateFolder/$hourFolder" "INFO"
                $organizedCount++
            }

        } catch {
            Write-Log "Error organizando $($file.Name): $($_.Exception.Message). Moviendo a unknown..." "WARN"
            $unknownDir = Join-Path $DownloadPath "unknown"
            if (-not (Test-Path $unknownDir)) { New-Item -Path $unknownDir -ItemType Directory -Force | Out-Null }
            try { Move-Item -Path $file.FullName -Destination (Join-Path $unknownDir $file.Name) -Force -ErrorAction SilentlyContinue } catch {}
        }
    }

    Write-Log "Organización completada. Archivos organizados: $organizedCount" "SUCCESS"
}

# Limpiar directorio temporal
if (Test-Path $tempDownloadPath) {
    try { Remove-Item -Path $tempDownloadPath -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Directorio temporal limpiado" "INFO" } catch { }
}

# Resumen final
Write-Host ""; Write-Host "=" * 50 -ForegroundColor Green
Write-Host "    RESUMEN FINAL    " -ForegroundColor Green
Write-Host "=" * 50 -ForegroundColor Green

$finalFiles = Get-ChildItem $DownloadPath -Recurse -File -Filter "*.json" -ErrorAction SilentlyContinue
if ($finalFiles) {
    $totalSize = ($finalFiles | Measure-Object -Property Length -Sum).Sum
    $totalSizeMB = [math]::Round($totalSize / 1MB, 2)
    Write-Log "Total archivos organizados: $($finalFiles.Count)" "SUCCESS"
    Write-Log "Tamaño total: $totalSizeMB MB" "SUCCESS"
    Write-Log "Ubicación: $DownloadPath" "INFO"
   
    # Mostrar estructura creada (primeros 10 días)
    Write-Log "Estructura de directorios (primeras 10 fechas):" "INFO"
    $directories = Get-ChildItem $DownloadPath -Directory | Sort-Object Name | Select-Object -First 10
    foreach ($dir in $directories) {
        $fileCount = (Get-ChildItem $dir.FullName -Recurse -File).Count
        Write-Log "   $($dir.Name) ($fileCount archivos)" "INFO"
    }
} else {
    Write-Log "No se encontraron archivos finales" "WARN"
}

Write-Host ""; Write-Log "Próximos pasos: analiza con Analyze-NSGFlowLogs.ps1" "INFO"

Write-Log "Proceso completado" "SUCCESS"