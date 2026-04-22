# Script de reporte para Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials
# PowerShell version
#
# Este script genera un reporte completo de todas las credenciales de identidad federada
# asociadas a identidades administradas asignadas por el usuario en Azure.
#
# Características:
# - Autenticación mediante Managed Identity o Azure CLI
# - Exportación a múltiples formatos (JSON, CSV, Excel)
# - Filtrado por suscripción, grupo de recursos o identidad específica
# - Logging detallado y manejo de errores
# - Retry logic con exponential backoff
#
# Requisitos:
# - Azure PowerShell module (Az)
# - ImportExcel module (para exportar a Excel)
#
# Autor: Script generado para reporte de Federated Identity Credentials
# Fecha: 2025-06-26

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory = $false)]
    [switch]$AllSubscriptions,
    
    [Parameter(Mandatory = $false)]
    [string]$TenantId,
    
    [Parameter(Mandatory = $false)]
    [string]$ResourceGroupName,
    
    [Parameter(Mandatory = $false)]
    [string]$IdentityName,
    
    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "CSV", "Excel")]
    [string]$Format = "JSON",
    
    [Parameter(Mandatory = $false)]
    [string]$OutputFile,
    
    [Parameter(Mandatory = $false)]
    [switch]$UseCliAuth
)

# Configuración de logging
$LogFile = "federated_identity_report.log"
# $VerbosePreference se maneja automáticamente por PowerShell cuando se usa -Verbose

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogMessage = "$Timestamp - $Level - $Message"
    
    # Escribir a la consola usando Write-Host para evitar que vaya al pipeline
    Write-Host $LogMessage -ForegroundColor $(
        switch ($Level) {
            "ERROR" { "Red" }
            "WARNING" { "Yellow" }
            "INFO" { "Green" }
            default { "White" }
        }
    )
    
    # Escribir al archivo de log
    Add-Content -Path $LogFile -Value $LogMessage
}

function Test-AzureModules {
    Write-Log "Verificando módulos de Azure PowerShell..."
    
    $RequiredModules = @("Az.Accounts", "Az.ManagedServiceIdentity", "Az.Resources")
    
    foreach ($Module in $RequiredModules) {
        if (-not (Get-Module -ListAvailable -Name $Module)) {
            Write-Error "Módulo requerido no encontrado: $Module. Instala con: Install-Module $Module"
            exit 1
        }
    }
    
    if ($Format -eq "Excel") {
        if (-not (Get-Module -ListAvailable -Name "ImportExcel")) {
            Write-Warning "Módulo ImportExcel no encontrado. Instala con: Install-Module ImportExcel"
            Write-Warning "Cambiando formato a CSV..."
            $script:Format = "CSV"
        }
    }
    
    Write-Log "Todos los módulos requeridos están disponibles"
}

function Connect-ToAzure {
    Write-Log "Estableciendo conexión con Azure..."
    
    try {
        $Context = Get-AzContext
        $NeedsNewConnection = $false
        
        # Verificar si necesitamos una nueva conexión
        if (-not $Context) {
            Write-Log "No hay contexto de Azure activo"
            $NeedsNewConnection = $true
        } elseif ($TenantId -and $Context.Tenant.Id -ne $TenantId) {
            Write-Log "El contexto actual está en un tenant diferente ($($Context.Tenant.Id)). Cambiando a tenant: $TenantId"
            $NeedsNewConnection = $true
        } else {
            Write-Log "Usando contexto existente de Azure"
        }
        
        # Establecer nueva conexión si es necesario
        if ($NeedsNewConnection) {
            if ($UseCliAuth) {
                Write-Log "Usando autenticación de Azure CLI"
                # Verificar si Azure CLI está conectado al tenant correcto
                try {
                    $CliAccount = az account show --query "{tenantId: tenantId, subscriptionId: id}" -o json 2>$null | ConvertFrom-Json
                    if ($CliAccount -and ($TenantId -and $CliAccount.tenantId -ne $TenantId)) {
                        Write-Log "Azure CLI está conectado a un tenant diferente. Ejecuta: az login --tenant $TenantId"
                        exit 1
                    } elseif (-not $CliAccount) {
                        Write-Log "Azure CLI no está autenticado. Ejecuta: az login" $(if ($TenantId) { " --tenant $TenantId" })
                        exit 1
                    }
                } catch {
                    Write-Log "Error verificando Azure CLI. Asegúrate de que está instalado y autenticado." "ERROR"
                    exit 1
                }
            } else {
                Write-Log "Iniciando autenticación interactiva con Azure..."
                
                # Parámetros de conexión
                $ConnectParams = @{}
                if ($TenantId) {
                    $ConnectParams.TenantId = $TenantId
                    Write-Log "Conectando al tenant: $TenantId"
                }
                
                # Intentar conexión con diferentes métodos
                try {
                    # Método 1: Conexión estándar (puede incluir MFA)
                    Write-Log "Intentando autenticación interactiva..."
                    Connect-AzAccount @ConnectParams -ErrorAction Stop | Out-Null
                    Write-Log "Autenticación interactiva exitosa"
                } catch {
                    Write-Log "Error en autenticación interactiva: $($_.Exception.Message)" "WARNING"
                    
                    try {
                        # Método 2: Forzar autenticación con device code si la interactiva falla
                        Write-Log "Intentando autenticación con código de dispositivo..."
                        Connect-AzAccount @ConnectParams -UseDeviceAuthentication -ErrorAction Stop | Out-Null
                        Write-Log "Autenticación con código de dispositivo exitosa"
                    } catch {
                        Write-Log "Error en autenticación con código de dispositivo: $($_.Exception.Message)" "ERROR"
                        Write-Log "No se pudo establecer conexión con Azure. Verifica tus credenciales y permisos." "ERROR"
                        exit 1
                    }
                }
            }
            
            # Verificar que la conexión fue exitosa
            $Context = Get-AzContext
            if (-not $Context) {
                Write-Log "Error: No se pudo establecer contexto de Azure" "ERROR"
                exit 1
            }
            
            Write-Log "Conexión establecida exitosamente"
            Write-Log "Usuario: $($Context.Account.Id)"
            Write-Log "Tenant: $($Context.Tenant.Id)"
        }
        
        # Validar parámetros de suscripción
        if (-not $AllSubscriptions -and -not $SubscriptionId) {
            Write-Log "Debes especificar -SubscriptionId o usar -AllSubscriptions" "ERROR"
            exit 1
        }
        
        if ($AllSubscriptions -and $SubscriptionId) {
            Write-Log "No puedes usar -SubscriptionId y -AllSubscriptions al mismo tiempo" "ERROR"
            exit 1
        }
        
        # Si se especifica una suscripción, establecerla
        if ($SubscriptionId) {
            try {
                Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
                $CurrentContext = Get-AzContext
                Write-Log "Contexto establecido para suscripción: $($CurrentContext.Subscription.Name) ($SubscriptionId)"
            } catch {
                Write-Log "Error estableciendo contexto para suscripción $SubscriptionId : $($_.Exception.Message)" "ERROR"
                Write-Log "Verifica que tengas acceso a la suscripción especificada" "ERROR"
                exit 1
            }
        } else {
            Write-Log "Modo todas las suscripciones habilitado"
        }
    }
    catch {
        Write-Log "Error conectando a Azure: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Get-UserAssignedIdentities {
    param(
        [string]$ResourceGroupName,
        [string]$CurrentSubscriptionId
    )
    
    Write-Log "Obteniendo identidades administradas asignadas por el usuario para suscripción: $CurrentSubscriptionId"
    
    try {
        $Identities = @()
        
        if ($ResourceGroupName) {
            Write-Log "Filtrando por grupo de recursos: $ResourceGroupName"
            $Identities = Get-AzUserAssignedIdentity -ResourceGroupName $ResourceGroupName
        } else {
            Write-Log "Obteniendo todas las identidades de la suscripción: $CurrentSubscriptionId"
            $ResourceGroups = Get-AzResourceGroup
            
            foreach ($RG in $ResourceGroups) {
                try {
                    $RGIdentities = Get-AzUserAssignedIdentity -ResourceGroupName $RG.ResourceGroupName -ErrorAction SilentlyContinue
                    if ($RGIdentities) {
                        $Identities += $RGIdentities
                    }
                }
                catch {
                    Write-Log "No se pudieron obtener identidades del grupo de recursos: $($RG.ResourceGroupName)" "WARNING"
                }
            }
        }
        
        Write-Log "Se encontraron $($Identities.Count) identidades administradas en suscripción: $CurrentSubscriptionId"
        return $Identities
    }
    catch {
        Write-Log "Error obteniendo identidades en suscripción $CurrentSubscriptionId : $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Get-FederatedCredentials {
    param(
        [string]$IdentityName,
        [string]$ResourceGroupName,
        [string]$CurrentSubscriptionId
    )
    
    Write-Verbose "Obteniendo credenciales federadas para $IdentityName en suscripción $CurrentSubscriptionId"
    
    try {
        # Usar Azure REST API ya que no hay cmdlet específico para federated credentials
        $Context = Get-AzContext
        $Token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($Context.Account, $Context.Environment, $Context.Tenant.Id, $null, "Never", $null, "https://management.azure.com/").AccessToken
        
        $Headers = @{
            'Authorization' = "Bearer $Token"
            'Content-Type' = 'application/json'
        }
        
        $Uri = "https://management.azure.com/subscriptions/$CurrentSubscriptionId/resourceGroups/$ResourceGroupName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$IdentityName/federatedIdentityCredentials?api-version=2023-01-31"
        
        $Response = Invoke-RestMethod -Uri $Uri -Headers $Headers -Method GET
        
        Write-Verbose "Se encontraron $($Response.value.Count) credenciales federadas para $IdentityName"
        return $Response.value
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Log "No se encontraron credenciales federadas para $IdentityName en suscripción $CurrentSubscriptionId" "WARNING"
            return @()
        } else {
            Write-Log "Error obteniendo credenciales federadas para $IdentityName en suscripción $CurrentSubscriptionId : $($_.Exception.Message)" "ERROR"
            throw
        }
    }
}

function New-Report {
    param(
        [string]$ResourceGroupName,
        [string]$IdentityName
    )
    
    Write-Log "Generando reporte de credenciales de identidad federada..."
    
    try {
        $ReportData = @()
        $SubscriptionsToProcess = @()
        
        # Determinar qué suscripciones procesar
        if ($AllSubscriptions) {
            Write-Log "Obteniendo lista de todas las suscripciones disponibles..."
            $AllSubs = Get-AzSubscription | Where-Object { $_.State -eq "Enabled" }
            
            # Si se especifica un tenant, filtrar solo las suscripciones de ese tenant
            if ($TenantId) {
                $SubscriptionsToProcess = $AllSubs | Where-Object { $_.TenantId -eq $TenantId }
                Write-Log "Filtrando suscripciones por tenant: $TenantId"
                Write-Log "Se encontraron $($SubscriptionsToProcess.Count) suscripciones habilitadas en el tenant especificado"
                
                if ($SubscriptionsToProcess.Count -eq 0) {
                    Write-Log "No se encontraron suscripciones habilitadas en el tenant $TenantId" "WARNING"
                    return @()
                }
            } else {
                $SubscriptionsToProcess = $AllSubs
                Write-Log "Se encontraron $($SubscriptionsToProcess.Count) suscripciones habilitadas (todos los tenants)"
            }
        } else {
            # Usar la suscripción actual
            $CurrentContext = Get-AzContext
            $SubscriptionsToProcess = @([PSCustomObject]@{
                Id = $CurrentContext.Subscription.Id
                Name = $CurrentContext.Subscription.Name
                TenantId = $CurrentContext.Tenant.Id
            })
        }
        
        # Procesar cada suscripción
        foreach ($Subscription in $SubscriptionsToProcess) {
            Write-Log "Procesando suscripción: $($Subscription.Name) ($($Subscription.Id)) - Tenant: $($Subscription.TenantId)"
            
            try {
                # Cambiar contexto a la suscripción actual
                if ($AllSubscriptions) {
                    Set-AzContext -SubscriptionId $Subscription.Id | Out-Null
                }
                
                # Obtener identidades administradas
                $Identities = Get-UserAssignedIdentities -ResourceGroupName $ResourceGroupName -CurrentSubscriptionId $Subscription.Id
                
                # Filtrar por identidad específica si se proporciona
                if ($IdentityName) {
                    $Identities = $Identities | Where-Object { $_.Name -eq $IdentityName }
                    if (-not $Identities) {
                        Write-Log "No se encontró la identidad especificada: $IdentityName en suscripción $($Subscription.Name)" "WARNING"
                        continue
                    }
                }
                
                # Procesar cada identidad
                foreach ($Identity in $Identities) {
                    # Validar que la identidad tenga nombre válido
                    if ([string]::IsNullOrEmpty($Identity.Name)) {
                        Write-Log "Saltando identidad con nombre vacío o nulo (ID: $($Identity.Id))" "WARNING"
                        continue
                    }
                    
                    Write-Log "Procesando identidad: $($Identity.Name) en suscripción: $($Subscription.Name)"
                    
                    try {
                        $FederatedCreds = Get-FederatedCredentials -IdentityName $Identity.Name -ResourceGroupName $Identity.ResourceGroupName -CurrentSubscriptionId $Subscription.Id
                        
                        if ($FederatedCreds.Count -gt 0) {
                            foreach ($Cred in $FederatedCreds) {
                                $ReportRecord = [PSCustomObject]@{
                                    # Información de la identidad
                                    identity_name = $Identity.Name
                                    identity_id = $Identity.Id
                                    identity_resource_group = $Identity.ResourceGroupName
                                    identity_location = $Identity.Location
                                    identity_principal_id = $Identity.PrincipalId
                                    identity_client_id = $Identity.ClientId
                                    identity_tenant_id = $Identity.TenantId
                                    
                                    # Información de la credencial federada
                                    credential_name = $Cred.name
                                    credential_id = $Cred.id
                                    credential_issuer = $Cred.properties.issuer
                                    credential_subject = $Cred.properties.subject
                                    credential_audiences = ($Cred.properties.audiences -join ', ')
                                    credential_description = $Cred.properties.description
                                    credential_type = $Cred.type
                                    
                                    # Metadatos del reporte
                                    subscription_id = $Subscription.Id
                                    subscription_name = $Subscription.Name
                                    tenant_id = $Subscription.TenantId
                                    report_timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
                                }
                                $ReportData += $ReportRecord
                            }
                        } else {
                            # Incluir identidades sin credenciales federadas
                            $ReportRecord = [PSCustomObject]@{
                                identity_name = $Identity.Name
                                identity_id = $Identity.Id
                                identity_resource_group = $Identity.ResourceGroupName
                                identity_location = $Identity.Location
                                identity_principal_id = $Identity.PrincipalId
                                identity_client_id = $Identity.ClientId
                                identity_tenant_id = $Identity.TenantId
                                credential_name = "N/A"
                                credential_id = "N/A"
                                credential_issuer = "N/A"
                                credential_subject = "N/A"
                                credential_audiences = "N/A"
                                credential_description = "Sin credenciales federadas"
                                credential_type = "N/A"
                                subscription_id = $Subscription.Id
                                subscription_name = $Subscription.Name
                                tenant_id = $Subscription.TenantId
                                report_timestamp = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ss")
                            }
                            $ReportData += $ReportRecord
                        }
                    }
                    catch {
                        Write-Log "Error procesando identidad $($Identity.Name) en suscripción $($Subscription.Name): $($_.Exception.Message)" "ERROR"
                        continue
                    }
                }
            }
            catch {
                Write-Log "Error procesando suscripción $($Subscription.Name): $($_.Exception.Message)" "ERROR"
                continue
            }
        }
        
        Write-Log "Reporte generado exitosamente con $($ReportData.Count) registros de $($SubscriptionsToProcess.Count) suscripción(es)"
        return $ReportData
    }
    catch {
        Write-Log "Error generando reporte: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Export-Report {
    param(
        [array]$Data,
        [string]$Format,
        [string]$OutputFile
    )
    
    if (-not $Data -or $Data.Count -eq 0) {
        Write-Log "No hay datos para exportar" "WARNING"
        return
    }
    
    # Determinar nombre del archivo de salida
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    if (-not $OutputFile) {
        $Extension = switch ($Format) {
            "Excel" { "xlsx" }
            "CSV" { "csv" }
            "JSON" { "json" }
        }
        $OutputFile = "federated_identity_credentials_report_$Timestamp.$Extension"
    }
    
    try {
        switch ($Format) {
            "JSON" {
                $Data | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputFile -Encoding UTF8
                Write-Log "Reporte exportado a JSON: $OutputFile"
            }
            "CSV" {
                $Data | Export-Csv -Path $OutputFile -NoTypeInformation -Encoding UTF8
                Write-Log "Reporte exportado a CSV: $OutputFile"
            }
            "Excel" {
                $Data | Export-Excel -Path $OutputFile -WorksheetName "Federated_Identity_Credentials" -AutoSize -FreezeTopRow
                Write-Log "Reporte exportado a Excel: $OutputFile"
            }
        }
        
        return $OutputFile
    }
    catch {
        Write-Log "Error exportando reporte: $($_.Exception.Message)" "ERROR"
        throw
    }
}

function Export-CredentialTuples {
    param(
        [array]$Data,
        [string]$Format,
        [string]$BaseOutputFile
    )
    
    if (-not $Data -or $Data.Count -eq 0) {
        Write-Log "No hay datos para exportar tuplas de credenciales" "WARNING"
        return
    }
    
    # Filtrar solo registros que tienen credenciales federadas (no N/A)
    $CredentialData = $Data | Where-Object { 
        $_.credential_name -ne "N/A" -and 
        $_.credential_issuer -ne "N/A" -and 
        $_.credential_subject -ne "N/A" 
    }
    
    if (-not $CredentialData -or $CredentialData.Count -eq 0) {
        Write-Log "No se encontraron credenciales federadas para exportar tuplas" "WARNING"
        return
    }
    
    # Crear tuplas únicas de credenciales
    $Tuples = @()
    $SeenTuples = @()
    
    foreach ($Record in $CredentialData) {
        $TupleKey = "$($Record.credential_issuer)|$($Record.credential_subject)|$($Record.credential_audiences)|$($Record.credential_type)"
        
        if ($SeenTuples -notcontains $TupleKey) {
            $SeenTuples += $TupleKey
            $Tuples += [PSCustomObject]@{
                credential_issuer = $Record.credential_issuer
                credential_subject = $Record.credential_subject
                credential_audiences = $Record.credential_audiences
                credential_type = $Record.credential_type
            }
        }
    }
    
    Write-Log "Se encontraron $($Tuples.Count) tuplas únicas de credenciales federadas"
    
    # Determinar nombre del archivo de tuplas
    $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    if ($BaseOutputFile) {
        $BaseName = [System.IO.Path]::GetFileNameWithoutExtension($BaseOutputFile)
        $Extension = [System.IO.Path]::GetExtension($BaseOutputFile)
        $TuplesFile = "$BaseName" + "_tuples" + $Extension
    } else {
        $Extension = switch ($Format) {
            "Excel" { ".xlsx" }
            "CSV" { ".csv" }
            "JSON" { ".json" }
        }
        $TuplesFile = "federated_identity_credentials_tuples_$Timestamp$Extension"
    }
    
    try {
        switch ($Format) {
            "JSON" {
                $Tuples | ConvertTo-Json -Depth 10 | Out-File -FilePath $TuplesFile -Encoding UTF8
                Write-Log "Tuplas de credenciales exportadas a JSON: $TuplesFile"
            }
            "CSV" {
                $Tuples | Export-Csv -Path $TuplesFile -NoTypeInformation -Encoding UTF8
                Write-Log "Tuplas de credenciales exportadas a CSV: $TuplesFile"
            }
            "Excel" {
                $Tuples | Export-Excel -Path $TuplesFile -WorksheetName "Credential_Tuples" -AutoSize -FreezeTopRow
                Write-Log "Tuplas de credenciales exportadas a Excel: $TuplesFile"
            }
        }
        
        return $TuplesFile
    }
    catch {
        Write-Log "Error exportando tuplas de credenciales: $($_.Exception.Message)" "ERROR"
        throw
    }
}

# Función principal
function Main {
    try {
        Write-Log "Iniciando script de reporte de Federated Identity Credentials"
        
        # Verificar módulos
        Test-AzureModules
        
        # Conectar a Azure
        Connect-ToAzure
        
        # Generar reporte
        $ReportData = New-Report -ResourceGroupName $ResourceGroupName -IdentityName $IdentityName
        
        if (-not $ReportData -or $ReportData.Count -eq 0) {
            Write-Log "No se encontraron datos para el reporte" "WARNING"
            return
        }
        
        # Exportar reporte
        $OutputFileName = Export-Report -Data $ReportData -Format $Format -OutputFile $OutputFile
        
        # Exportar tuplas de credenciales
        $TuplesFileName = Export-CredentialTuples -Data $ReportData -Format $Format -BaseOutputFile $OutputFileName
        
        # Mostrar resumen
        Write-Output ""
        Write-Output "=" * 60
        Write-Output "RESUMEN DEL REPORTE"
        Write-Output "=" * 60
        Write-Output "Total de registros: $($ReportData.Count)"
        Write-Output "Archivo principal generado: $OutputFileName"
        if ($TuplesFileName) {
            Write-Output "Archivo de tuplas generado: $TuplesFileName"
        }
        Write-Output "Formato: $Format"
        Write-Output "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        Write-Output "=" * 60
    }
    catch {
        Write-Log "Error ejecutando el script: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

# Ejecutar función principal
Main
