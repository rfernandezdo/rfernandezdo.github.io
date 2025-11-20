---
draft: false
date: 2025-11-20
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure Arc
  - Python
  - Managed Identity
  - Authentication
  - IMDS
  - Security
---

# Autenticación Python en Máquinas Azure Arc: Guía Práctica

## Resumen

Los servidores enrolados en Azure Arc pueden autenticarse contra recursos Azure usando managed identity sin almacenar credenciales. Python + Azure SDK (`azure-identity`) simplifica esto con `DefaultAzureCredential` o `ManagedIdentityCredential`, accediendo al endpoint IMDS local (`http://localhost:40342`) que expone el agente Azure Connected Machine.

## ¿Qué es Azure Arc-enabled servers?

Azure Arc extiende el plano de control de Azure a servidores físicos y VMs fuera de Azure (on-premises, otras clouds, edge). Una vez enrolado, el servidor obtiene:

- Representación como recurso Azure (`Microsoft.HybridCompute/machines`)
- System-assigned managed identity automática
- Acceso a servicios Azure (Key Vault, Storage, Log Analytics, etc.) sin credenciales hard-coded
- Gestión unificada (Policy, Update Management, extensiones VM)

## Cómo funciona la autenticación en Azure Arc

Cuando el agente `azcmagent` se instala y conecta, ocurre:

1. Azure Resource Manager crea un service principal en Microsoft Entra ID para la identidad del servidor.
2. El agente configura un endpoint IMDS local en `http://localhost:40342` (no enrutable, solo accesible desde localhost).
3. Variables de entorno se establecen automáticamente:
   - `IMDS_ENDPOINT=http://localhost:40342`
   - `IDENTITY_ENDPOINT=http://localhost:40342/metadata/identity/oauth2/token`
4. Las aplicaciones solicitan tokens a este endpoint, sin exponer secretos.

!!! note "Diferencia con Azure VMs"
    Azure VMs usan `http://169.254.169.254` (Azure IMDS), mientras que Arc usa `localhost:40342`. El SDK de Azure detecta automáticamente el entorno correcto.

## Métodos de autenticación en Python

### Opción 1: DefaultAzureCredential (recomendada)

Cadena de credenciales que prueba múltiples métodos en orden (variables de entorno, managed identity, Azure CLI, etc.). Funciona tanto en desarrollo local como en producción Arc sin cambios de código.

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# Credential chain automática (detecta Arc managed identity)
credential = DefaultAzureCredential()

# Cliente Key Vault sin credenciales explícitas
vault_url = "https://my-vault.vault.azure.net"
client = SecretClient(vault_url=vault_url, credential=credential)

# Obtener secreto
secret = client.get_secret("database-password")
print(f"Secret value: {secret.value}")
```

### Opción 2: ManagedIdentityCredential (explícita)

Fuerza el uso de managed identity exclusivamente, útil cuando no quieres la cadena de fallback.

```python
from azure.identity import ManagedIdentityCredential
from azure.storage.blob import BlobServiceClient

# System-assigned managed identity
credential = ManagedIdentityCredential()

# Cliente Blob Storage
account_url = "https://mystorageaccount.blob.core.windows.net"
blob_service = BlobServiceClient(account_url=account_url, credential=credential)

# Listar containers
for container in blob_service.list_containers():
    print(f"Container: {container.name}")
```

### Opción 3: User-assigned managed identity

Si el servidor tiene múltiples identities user-assigned, especifica el `client_id`:

```python
from azure.identity import ManagedIdentityCredential

# User-assigned identity con client_id específico
client_id = "12345678-abcd-1234-abcd-1234567890ab"
credential = ManagedIdentityCredential(client_id=client_id)

# Usa este credential con cualquier SDK Azure
```

### Opción 4: MSAL Python (bajo nivel)

Para casos avanzados, `msal` 1.29.0+ soporta managed identity directamente:

```python
import msal
import requests

# System-assigned managed identity
managed_identity = msal.SystemAssignedManagedIdentity()
app = msal.ManagedIdentityClient(managed_identity, http_client=requests.Session())

# Obtener token para Key Vault
result = app.acquire_token_for_client(resource="https://vault.azure.net")

if "access_token" in result:
    token = result["access_token"]
    print(f"Token adquirido: {token[:20]}...")
else:
    print(f"Error: {result.get('error_description')}")
```

## Ejemplo completo: Leer secreto de Key Vault

Escenario: Script Python en servidor Arc que obtiene credenciales DB desde Key Vault.

```python
#!/usr/bin/env python3
"""
Script: get_db_credentials.py
Descripción: Obtiene credenciales de base de datos desde Azure Key Vault
             usando managed identity del servidor Azure Arc
Requisitos: pip install azure-identity azure-keyvault-secrets
"""

from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient
import sys

def get_secret(vault_name: str, secret_name: str) -> str:
    """
    Obtiene un secreto de Azure Key Vault usando managed identity.
    
    Args:
        vault_name: Nombre del Key Vault (sin .vault.azure.net)
        secret_name: Nombre del secreto
        
    Returns:
        Valor del secreto
    """
    try:
        # DefaultAzureCredential detecta automáticamente el entorno Arc
        credential = DefaultAzureCredential()
        
        vault_url = f"https://{vault_name}.vault.azure.net"
        client = SecretClient(vault_url=vault_url, credential=credential)
        
        # Obtener secreto
        secret = client.get_secret(secret_name)
        return secret.value
        
    except Exception as e:
        print(f"Error obteniendo secreto: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    # Configuración
    VAULT_NAME = "my-production-vault"
    DB_PASSWORD_SECRET = "db-password"
    
    # Obtener credencial
    password = get_secret(VAULT_NAME, DB_PASSWORD_SECRET)
    print(f"Credencial obtenida exitosamente (longitud: {len(password)} caracteres)")
    
    # Usar password para conectar a DB (no imprimir en logs reales)
    # connection_string = f"Server=myserver;Database=mydb;User=admin;Password={password}"
```

**Requisitos previos:**

1. Servidor enrolado en Azure Arc con managed identity habilitada (por defecto).
2. Identity del servidor con RBAC apropiado en Key Vault:

```bash
# Variables
RESOURCE_GROUP="my-rg"
SERVER_NAME="my-arc-server"
VAULT_NAME="my-production-vault"

# Obtener el principal ID de la managed identity
PRINCIPAL_ID=$(az connectedmachine show \
    --resource-group $RESOURCE_GROUP \
    --name $SERVER_NAME \
    --query identity.principalId -o tsv)

# Asignar rol "Key Vault Secrets User" (RBAC)
az role assignment create \
    --assignee $PRINCIPAL_ID \
    --role "Key Vault Secrets User" \
    --scope /subscriptions/$(az account show --query id -o tsv)/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.KeyVault/vaults/$VAULT_NAME
```

## Validar managed identity en el servidor

Antes de ejecutar código Python, verifica que el endpoint IMDS responde:

```bash
# Variables de entorno expuestas por el agente Arc
echo $IMDS_ENDPOINT
# Salida esperada: http://localhost:40342

echo $IDENTITY_ENDPOINT
# Salida esperada: http://localhost:40342/metadata/identity/oauth2/token

# Test manual del endpoint (requiere header Metadata:true)
curl -H "Metadata:true" \
    "http://localhost:40342/metadata/identity/oauth2/token?api-version=2020-06-01&resource=https://vault.azure.net"
```

Respuesta exitosa (JSON con `access_token`, `expires_on`, etc.):

```json
{
  "access_token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "expires_on": "1700000000",
  "resource": "https://vault.azure.net",
  "token_type": "Bearer"
}
```

## Troubleshooting común

### Error: "No managed identity endpoint found"

**Causa:** El agente Arc no está instalado o no ha configurado el endpoint IMDS.

**Solución:**

```bash
# Verificar estado del agente
sudo azcmagent show

# Si está desconectado, reconectar
sudo azcmagent connect \
    --resource-group "my-rg" \
    --tenant-id "tenant-id" \
    --location "westeurope" \
    --subscription-id "sub-id"
```

### Error: "AADSTS700016: Application not found"

**Causa:** La managed identity no tiene permisos RBAC sobre el recurso destino.

**Solución:** Asignar rol apropiado (ver ejemplo de Key Vault arriba). Roles comunes:

- Key Vault: `Key Vault Secrets User` (lectura secretos)
- Storage: `Storage Blob Data Reader` (lectura blobs)
- Log Analytics: `Log Analytics Reader` (consultas)

### Error: "CredentialUnavailableError: ManagedIdentityCredential authentication unavailable"

**Causa:** Ejecutando código fuera de un entorno con managed identity (ej: laptop local).

**Solución:** `DefaultAzureCredential` caerá en otros métodos (Azure CLI, variables de entorno). Para testing local:

```bash
# Autenticarse con Azure CLI (DefaultAzureCredential lo detectará)
az login

# O usar service principal con variables de entorno
export AZURE_CLIENT_ID="app-id"
export AZURE_CLIENT_SECRET="secret"
export AZURE_TENANT_ID="tenant-id"
```

## Permisos y seguridad

### Principio de mínimo privilegio

Asigna solo los permisos necesarios:

```bash
# ❌ MAL: Owner en toda la suscripción
az role assignment create --assignee $PRINCIPAL_ID --role "Owner" --subscription $SUB_ID

# ✅ BIEN: Lectura específica en un Key Vault
az role assignment create --assignee $PRINCIPAL_ID --role "Key Vault Secrets User" --scope $VAULT_ID
```

### Control de acceso local

Solo usuarios con privilegios elevados pueden obtener tokens managed identity:

- **Windows:** Miembros de `Administrators` o grupo `Hybrid Agent Extension Applications`
- **Linux:** Miembros del grupo `himds`

```bash
# Linux: Añadir usuario al grupo himds (con precaución)
sudo usermod -aG himds myappuser

# Verificar membership
groups myappuser
```

## Buenas prácticas

1. **Usa `DefaultAzureCredential` por defecto:** Funciona en dev y producción sin cambios.
2. **No almacenes tokens:** Deja que el SDK los renueve automáticamente.
3. **Logging seguro:** No imprimas tokens o secretos en logs (`print(token)` ❌).
4. **Auditoría:** Habilita diagnostic logs en Key Vault/Storage para rastrear accesos:

```bash
az monitor diagnostic-settings create \
    --resource $VAULT_ID \
    --name "audit-logs" \
    --logs '[{"category":"AuditEvent","enabled":true}]' \
    --workspace $LOG_ANALYTICS_WORKSPACE_ID
```

5. **Timeout y reintentos:** El SDK maneja reintentos, pero para scripts long-running:

```python
from azure.core.exceptions import AzureError
import time

def get_secret_with_retry(client, secret_name, max_retries=3):
    for attempt in range(max_retries):
        try:
            return client.get_secret(secret_name).value
        except AzureError as e:
            if attempt < max_retries - 1:
                time.sleep(2 ** attempt)  # Exponential backoff
                continue
            raise
```

## Instalación de dependencias

```bash
# Instalar Azure SDK para identidad y servicios específicos
pip install azure-identity azure-keyvault-secrets azure-storage-blob

# Para desarrollo, incluye azure-cli para testing local
pip install azure-cli
```

Archivo `requirements.txt` recomendado:

```txt
azure-identity>=1.15.0
azure-keyvault-secrets>=4.7.0
azure-storage-blob>=12.19.0
```

## Referencias

Documentación oficial validada:

- Autenticación managed identity en Azure Arc: <https://learn.microsoft.com/en-us/azure/azure-arc/servers/managed-identity-authentication>
- Azure Identity library para Python: <https://learn.microsoft.com/en-us/python/api/overview/azure/identity-readme>
- Managed identities overview: <https://learn.microsoft.com/en-us/entra/identity/managed-identities-azure-resources/overview>
- MSAL Python managed identity: <https://learn.microsoft.com/en-us/entra/msal/python/advanced/managed-identity>
- Security overview Azure Arc: <https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/hybrid/arc-enabled-servers/eslz-identity-and-access-management>
