#!/usr/bin/env python3
"""
Script de reporte para Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials

Este script genera un reporte completo de todas las credenciales de identidad federada
asociadas a identidades administradas asignadas por el usuario en Azure.

Características:
- Autenticación mediante Managed Identity o Azure CLI
- Exportación a múltiples formatos (JSON, CSV, Excel)
- Filtrado por suscripción, grupo de recursos o identidad específica
- Logging detallado y manejo de errores
- Retry logic con exponential backoff

Requisitos:
- azure-identity
- azure-mgmt-msi
- pandas
- openpyxl (para exportar a Excel)

Autor: Script generado para reporte de Federated Identity Credentials
Fecha: 2025-06-26
"""

import argparse
import json
import logging
import sys
from datetime import datetime
from typing import Dict, List, Optional, Any
import time

try:
    from azure.identity import DefaultAzureCredential, AzureCliCredential, InteractiveBrowserCredential, DeviceCodeCredential
    from azure.mgmt.msi import ManagedServiceIdentityClient
    from azure.mgmt.resource import ResourceManagementClient, SubscriptionClient
    from azure.core.exceptions import AzureError, HttpResponseError
    import pandas as pd
except ImportError as e:
    print(f"Error: Faltan dependencias requeridas. Instala con: pip install azure-identity azure-mgmt-msi azure-mgmt-resource pandas openpyxl")
    sys.exit(1)

# Configuración de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('federated_identity_report.log'),
        logging.StreamHandler(sys.stderr)
    ]
)
logger = logging.getLogger(__name__)

class FederatedIdentityReporter:
    """
    Clase principal para generar reportes de credenciales de identidad federada.
    
    Implementa las mejores prácticas de Azure:
    - Uso de Managed Identity para autenticación
    - Retry logic con exponential backoff
    - Logging comprehensivo
    - Manejo robusto de errores
    """
    
    def __init__(self, subscription_id: Optional[str] = None, use_cli_auth: bool = False, 
                 all_subscriptions: bool = False, tenant_id: Optional[str] = None):
        """
        Inicializa el cliente de reporte.
        
        Args:
            subscription_id: ID de la suscripción de Azure (opcional si all_subscriptions=True)
            use_cli_auth: Si usar autenticación de Azure CLI en lugar de Managed Identity
            all_subscriptions: Si procesar todas las suscripciones disponibles
            tenant_id: ID del tenant de Azure (opcional)
        """
        self.subscription_id = subscription_id
        self.all_subscriptions = all_subscriptions
        self.tenant_id = tenant_id
        self.credential = self._get_credential(use_cli_auth)
        self.msi_client = None
        self.resource_client = None
        
        # Validar parámetros
        if not all_subscriptions and not subscription_id:
            raise ValueError("Debes especificar subscription_id o usar all_subscriptions=True")
        
        if all_subscriptions and subscription_id:
            logger.warning("Se especificó subscription_id y all_subscriptions. Se usará all_subscriptions.")
            self.subscription_id = None
        
    def _get_credential(self, use_cli_auth: bool):
        """
        Obtiene las credenciales apropiadas siguiendo las mejores prácticas de seguridad.
        Implementa múltiples métodos de autenticación incluyendo MFA.
        """
        try:
            if use_cli_auth:
                logger.info("Usando autenticación de Azure CLI")
                if self.tenant_id:
                    logger.info(f"Usando tenant específico: {self.tenant_id}")
                return AzureCliCredential(tenant_id=self.tenant_id)
            else:
                logger.info("Usando cadena de credenciales de Azure (incluye Managed Identity, Interactive Browser, Device Code)")
                
                # Crear una cadena de credenciales que incluya múltiples métodos
                credential_chain = []
                
                # 1. Managed Identity (para recursos en Azure)
                try:
                    from azure.identity import ManagedIdentityCredential
                    credential_chain.append(ManagedIdentityCredential())
                    logger.debug("Añadido ManagedIdentityCredential a la cadena")
                except ImportError:
                    pass
                
                # 2. Interactive Browser (para usuarios locales)
                try:
                    credential_chain.append(InteractiveBrowserCredential(tenant_id=self.tenant_id))
                    logger.debug("Añadido InteractiveBrowserCredential a la cadena")
                except Exception:
                    pass
                
                # 3. Device Code (fallback para entornos sin browser)
                try:
                    credential_chain.append(DeviceCodeCredential(tenant_id=self.tenant_id))
                    logger.debug("Añadido DeviceCodeCredential a la cadena")
                except Exception:
                    pass
                
                # 4. Azure CLI (si está disponible)
                try:
                    credential_chain.append(AzureCliCredential(tenant_id=self.tenant_id))
                    logger.debug("Añadido AzureCliCredential a la cadena")
                except Exception:
                    pass
                
                # Si tenemos credenciales en la cadena, usar DefaultAzureCredential con configuración custom
                if credential_chain:
                    from azure.identity import ChainedTokenCredential
                    return ChainedTokenCredential(*credential_chain)
                else:
                    # Fallback a DefaultAzureCredential estándar
                    return DefaultAzureCredential(tenant_id=self.tenant_id)
                    
        except Exception as e:
            logger.error(f"Error al obtener credenciales: {e}")
            raise
    
    def _initialize_clients(self, subscription_id: str):
        """
        Inicializa los clientes de Azure con retry logic para una suscripción específica.
        
        Args:
            subscription_id: ID de la suscripción para la cual inicializar los clientes
        """
        max_retries = 3
        retry_delay = 1
        
        for attempt in range(max_retries):
            try:
                self.msi_client = ManagedServiceIdentityClient(
                    self.credential, 
                    subscription_id
                )
                self.resource_client = ResourceManagementClient(
                    self.credential,
                    subscription_id
                )
                logger.debug(f"Clientes de Azure inicializados correctamente para suscripción: {subscription_id}")
                return
            except Exception as e:
                if attempt < max_retries - 1:
                    logger.warning(f"Intento {attempt + 1} fallido, reintentando en {retry_delay}s: {e}")
                    time.sleep(retry_delay)
                    retry_delay *= 2  # Exponential backoff
                else:
                    logger.error(f"Error al inicializar clientes después de {max_retries} intentos: {e}")
                    raise
    
    def get_all_subscriptions(self) -> List[Dict]:
        """
        Obtiene todas las suscripciones disponibles para el usuario.
        Si se especifica un tenant_id, filtra solo las suscripciones de ese tenant.
        
        Returns:
            Lista de suscripciones con ID y nombre
        """
        try:
            logger.info("Obteniendo lista de todas las suscripciones disponibles...")
            subscription_client = SubscriptionClient(self.credential)
            
            subscriptions = []
            subscription_list = subscription_client.subscriptions.list()
            
            for sub in subscription_list:
                # Verificar el estado de la suscripción
                state = getattr(sub, 'state', None)
                if state:
                    # El estado puede ser un objeto con atributo 'name' o directamente una cadena
                    if hasattr(state, 'name'):
                        state_name = state.name.lower()
                    else:
                        state_name = str(state).lower()
                else:
                    # Si no hay estado, asumir que está habilitada
                    state_name = 'enabled'
                
                if state_name == 'enabled':
                    # Si se especifica un tenant, filtrar solo las suscripciones de ese tenant
                    if self.tenant_id:
                        if sub.tenant_id == self.tenant_id:
                            subscriptions.append({
                                'subscription_id': sub.subscription_id,
                                'display_name': sub.display_name,
                                'tenant_id': sub.tenant_id
                            })
                            logger.debug(f"Suscripción incluida: {sub.display_name} (tenant: {sub.tenant_id})")
                        else:
                            logger.debug(f"Suscripción excluida por tenant: {sub.display_name} (tenant: {sub.tenant_id})")
                    else:
                        subscriptions.append({
                            'subscription_id': sub.subscription_id,
                            'display_name': sub.display_name,
                            'tenant_id': getattr(sub, 'tenant_id', 'N/A')
                        })
            
            if self.tenant_id:
                logger.info(f"Se encontraron {len(subscriptions)} suscripciones habilitadas en el tenant {self.tenant_id}")
            else:
                logger.info(f"Se encontraron {len(subscriptions)} suscripciones habilitadas")
            
            return subscriptions
            
        except Exception as e:
            logger.error(f"Error obteniendo lista de suscripciones: {e}")
            raise
    
    def get_user_assigned_identities(self, resource_group_name: Optional[str] = None) -> List[Dict]:
        """
        Obtiene todas las identidades administradas asignadas por el usuario.
        
        Args:
            resource_group_name: Nombre del grupo de recursos (opcional)
            
        Returns:
            Lista de identidades administradas
        """
        identities = []
        
        try:
            if resource_group_name:
                logger.info(f"Obteniendo identidades del grupo de recursos: {resource_group_name}")
                identity_list = self.msi_client.user_assigned_identities.list_by_resource_group(
                    resource_group_name
                )
            else:
                logger.info("Obteniendo todas las identidades de la suscripción")
                identity_list = self.msi_client.user_assigned_identities.list_by_subscription()
            
            for identity in identity_list:
                identities.append({
                    'name': identity.name,
                    'id': identity.id,
                    'resource_group': identity.id.split('/')[4] if identity.id else None,
                    'location': identity.location,
                    'principal_id': identity.principal_id,
                    'client_id': identity.client_id,
                    'tenant_id': identity.tenant_id
                })
                
            logger.info(f"Se encontraron {len(identities)} identidades administradas")
            return identities
            
        except HttpResponseError as e:
            logger.error(f"Error HTTP al obtener identidades: {e.status_code} - {e.message}")
            raise
        except Exception as e:
            logger.error(f"Error inesperado al obtener identidades: {e}")
            raise
    
    def get_federated_credentials(self, identity_name: str, resource_group_name: str) -> List[Dict]:
        """
        Obtiene las credenciales de identidad federada para una identidad específica.
        
        Args:
            identity_name: Nombre de la identidad administrada
            resource_group_name: Nombre del grupo de recursos
            
        Returns:
            Lista de credenciales federadas
        """
        credentials = []
        
        try:
            logger.debug(f"Obteniendo credenciales federadas para {identity_name}")
            
            cred_list = self.msi_client.federated_identity_credentials.list(
                resource_group_name,
                identity_name
            )
            
            for cred in cred_list:
                credentials.append({
                    'name': cred.name,
                    'id': cred.id,
                    'issuer': cred.issuer,
                    'subject': cred.subject,
                    'audiences': cred.audiences,
                    'description': getattr(cred, 'description', ''),
                    'type': cred.type
                })
                
            logger.debug(f"Se encontraron {len(credentials)} credenciales federadas para {identity_name}")
            return credentials
            
        except HttpResponseError as e:
            if e.status_code == 404:
                logger.warning(f"No se encontraron credenciales federadas para {identity_name}")
                return []
            else:
                logger.error(f"Error HTTP al obtener credenciales federadas: {e.status_code} - {e.message}")
                raise
        except Exception as e:
            logger.error(f"Error inesperado al obtener credenciales federadas: {e}")
            raise
    
    def generate_report(self, resource_group_name: Optional[str] = None, 
                       identity_name: Optional[str] = None) -> List[Dict]:
        """
        Genera el reporte completo de credenciales de identidad federada.
        
        Args:
            resource_group_name: Filtrar por grupo de recursos específico
            identity_name: Filtrar por identidad específica
            
        Returns:
            Lista de registros del reporte
        """
        report_data = []
        
        try:
            # Determinar qué suscripciones procesar
            if self.all_subscriptions:
                subscriptions = self.get_all_subscriptions()
                if not subscriptions:
                    if self.tenant_id:
                        logger.warning(f"No se encontraron suscripciones habilitadas en el tenant {self.tenant_id}")
                    else:
                        logger.warning("No se encontraron suscripciones habilitadas")
                    return []
            else:
                # Para suscripción específica, obtener información del tenant si está disponible
                subscription_info = {
                    'subscription_id': self.subscription_id,
                    'display_name': 'Suscripción especificada',
                    'tenant_id': self.tenant_id or 'N/A'
                }
                subscriptions = [subscription_info]
            
            # Procesar cada suscripción
            for subscription in subscriptions:
                current_subscription_id = subscription['subscription_id']
                subscription_name = subscription['display_name']
                
                logger.info(f"Procesando suscripción: {subscription_name} ({current_subscription_id})")
                
                try:
                    # Inicializar clientes para esta suscripción
                    self._initialize_clients(current_subscription_id)
                    
                    # Obtener identidades administradas
                    identities = self.get_user_assigned_identities(resource_group_name)
                    
                    # Filtrar por identidad específica si se proporciona
                    if identity_name:
                        identities = [id for id in identities if id['name'] == identity_name]
                        if not identities:
                            logger.warning(f"No se encontró la identidad especificada: {identity_name} en suscripción {subscription_name}")
                            continue
                    
                    # Procesar cada identidad
                    for identity in identities:
                        # Validar que la identidad tenga un nombre válido
                        if not identity.get('name') or identity['name'].strip() == '':
                            logger.warning(f"Se omitió una identidad con nombre vacío o nulo en suscripción: {subscription_name}")
                            continue
                            
                        logger.info(f"Procesando identidad: {identity['name']} en suscripción: {subscription_name}")
                        
                        try:
                            federated_creds = self.get_federated_credentials(
                                identity['name'], 
                                identity['resource_group']
                            )
                            
                            if federated_creds:
                                for cred in federated_creds:
                                    report_record = {
                                        # Información de la identidad
                                        'identity_name': identity['name'],
                                        'identity_id': identity['id'],
                                        'identity_resource_group': identity['resource_group'],
                                        'identity_location': identity['location'],
                                        'identity_principal_id': identity['principal_id'],
                                        'identity_client_id': identity['client_id'],
                                        'identity_tenant_id': identity['tenant_id'],
                                        
                                        # Información de la credencial federada
                                        'credential_name': cred['name'],
                                        'credential_id': cred['id'],
                                        'credential_issuer': cred['issuer'],
                                        'credential_subject': cred['subject'],
                                        'credential_audiences': ', '.join(cred['audiences']) if cred['audiences'] else '',
                                        'credential_description': cred['description'],
                                        'credential_type': cred['type'],
                                        
                                        # Metadatos del reporte
                                        'subscription_id': current_subscription_id,
                                        'subscription_name': subscription_name,
                                        'tenant_id': subscription.get('tenant_id', 'N/A'),
                                        'report_timestamp': datetime.now().isoformat()
                                    }
                                    report_data.append(report_record)
                            else:
                                # Incluir identidades sin credenciales federadas
                                report_record = {
                                    'identity_name': identity['name'],
                                    'identity_id': identity['id'],
                                    'identity_resource_group': identity['resource_group'],
                                    'identity_location': identity['location'],
                                    'identity_principal_id': identity['principal_id'],
                                    'identity_client_id': identity['client_id'],
                                    'identity_tenant_id': identity['tenant_id'],
                                    'credential_name': 'N/A',
                                    'credential_id': 'N/A',
                                    'credential_issuer': 'N/A',
                                    'credential_subject': 'N/A',
                                    'credential_audiences': 'N/A',
                                    'credential_description': 'Sin credenciales federadas',
                                    'credential_type': 'N/A',
                                    'subscription_id': current_subscription_id,
                                    'subscription_name': subscription_name,
                                    'tenant_id': subscription.get('tenant_id', 'N/A'),
                                    'report_timestamp': datetime.now().isoformat()
                                }
                                report_data.append(report_record)
                                
                        except Exception as e:
                            logger.error(f"Error procesando identidad {identity['name']} en suscripción {subscription_name}: {e}")
                            continue
                            
                except Exception as e:
                    logger.error(f"Error procesando suscripción {subscription_name}: {e}")
                    continue
            
            logger.info(f"Reporte generado exitosamente con {len(report_data)} registros de {len(subscriptions)} suscripción(es)")
            return report_data
            
        except Exception as e:
            logger.error(f"Error generando reporte: {e}")
            raise
    
    def export_to_json(self, data: List[Dict], filename: str):
        """Exporta los datos a formato JSON."""
        try:
            with open(filename, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent=2, ensure_ascii=False)
            logger.info(f"Reporte exportado a JSON: {filename}")
        except Exception as e:
            logger.error(f"Error exportando a JSON: {e}")
            raise
    
    def export_to_csv(self, data: List[Dict], filename: str):
        """Exporta los datos a formato CSV."""
        try:
            df = pd.DataFrame(data)
            df.to_csv(filename, index=False, encoding='utf-8')
            logger.info(f"Reporte exportado a CSV: {filename}")
        except Exception as e:
            logger.error(f"Error exportando a CSV: {e}")
            raise
    
    def export_to_excel(self, data: List[Dict], filename: str):
        """Exporta los datos a formato Excel con formato mejorado."""
        try:
            df = pd.DataFrame(data)
            
            with pd.ExcelWriter(filename, engine='openpyxl') as writer:
                df.to_excel(writer, sheet_name='Federated_Identity_Credentials', index=False)
                
                # Obtener el worksheet para formatear
                worksheet = writer.sheets['Federated_Identity_Credentials']
                
                # Ajustar ancho de columnas
                for column in worksheet.columns:
                    max_length = 0
                    column_letter = column[0].column_letter
                    for cell in column:
                        try:
                            if len(str(cell.value)) > max_length:
                                max_length = len(str(cell.value))
                        except (AttributeError, TypeError):
                            pass
                    adjusted_width = min(max_length + 2, 50)
                    worksheet.column_dimensions[column_letter].width = adjusted_width
            
            logger.info(f"Reporte exportado a Excel: {filename}")
        except Exception as e:
            logger.error(f"Error exportando a Excel: {e}")
            raise

    def export_credentials_tuples(self, data: List[Dict], base_filename: str, format_type: str = 'json'):
        """
        Exporta solo las tuplas de credenciales federadas (credential_issuer, credential_subject, 
        credential_audiences, credential_type) sin duplicados.
        """
        try:
            # Extraer solo las tuplas de credenciales, filtrando aquellas que no son 'N/A'
            credentials_tuples = []
            seen_tuples = set()
            
            for record in data:
                # Solo incluir registros que tienen credenciales válidas (no 'N/A')
                if (record.get('credential_issuer', 'N/A') != 'N/A' and 
                    record.get('credential_subject', 'N/A') != 'N/A'):
                    
                    tuple_data = {
                        'credential_issuer': record.get('credential_issuer', ''),
                        'credential_subject': record.get('credential_subject', ''),
                        'credential_audiences': record.get('credential_audiences', ''),
                        'credential_type': record.get('credential_type', '')
                    }
                    
                    # Crear una clave única para evitar duplicados
                    tuple_key = (
                        tuple_data['credential_issuer'],
                        tuple_data['credential_subject'],
                        tuple_data['credential_audiences'],
                        tuple_data['credential_type']
                    )
                    
                    if tuple_key not in seen_tuples:
                        seen_tuples.add(tuple_key)
                        credentials_tuples.append(tuple_data)
            
            # Generar nombre de archivo para las tuplas
            name_parts = base_filename.rsplit('.', 1)
            if len(name_parts) == 2:
                tuples_filename = f"{name_parts[0]}_credentials_tuples.{name_parts[1]}"
            else:
                tuples_filename = f"{base_filename}_credentials_tuples.{format_type}"
            
            # Exportar según el formato
            if format_type == 'json':
                with open(tuples_filename, 'w', encoding='utf-8') as f:
                    json.dump(credentials_tuples, f, indent=2, ensure_ascii=False)
            elif format_type == 'csv':
                if credentials_tuples:
                    df = pd.DataFrame(credentials_tuples)
                    df.to_csv(tuples_filename, index=False, encoding='utf-8')
            elif format_type == 'excel':
                if credentials_tuples:
                    df = pd.DataFrame(credentials_tuples)
                    with pd.ExcelWriter(tuples_filename, engine='openpyxl') as writer:
                        df.to_excel(writer, sheet_name='Credentials_Tuples', index=False)
                        
                        # Formatear el Excel
                        worksheet = writer.sheets['Credentials_Tuples']
                        for column in worksheet.columns:
                            max_length = 0
                            column_letter = column[0].column_letter
                            for cell in column:
                                try:
                                    if len(str(cell.value)) > max_length:
                                        max_length = len(str(cell.value))
                                except:
                                    pass
                            adjusted_width = min(max_length + 2, 50)
                            worksheet.column_dimensions[column_letter].width = adjusted_width
            
            logger.info(f"Tuplas de credenciales exportadas a: {tuples_filename} ({len(credentials_tuples)} tuplas únicas)")
            return tuples_filename
            
        except Exception as e:
            logger.error(f"Error exportando tuplas de credenciales: {e}")
            raise

def main():
    """Función principal del script."""
    parser = argparse.ArgumentParser(
        description='Generador de reportes para Federated Identity Credentials de Azure',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Ejemplos de uso:
  python federated-identity-credentials-report.py --subscription-id "12345678-1234-1234-1234-123456789012"
  python federated-identity-credentials-report.py --all-subscriptions
  python federated-identity-credentials-report.py --all-subscriptions --tenant-id "your-tenant-id"
  python federated-identity-credentials-report.py --subscription-id "12345678-1234-1234-1234-123456789012" --resource-group "mi-rg"
  python federated-identity-credentials-report.py --all-subscriptions --identity-name "mi-identity"
  python federated-identity-credentials-report.py --subscription-id "12345678-1234-1234-1234-123456789012" --format excel
        """
    )
    
    parser.add_argument(
        '--subscription-id',
        help='ID de la suscripción de Azure (requerido si no se usa --all-subscriptions)'
    )
    
    parser.add_argument(
        '--all-subscriptions',
        action='store_true',
        help='Procesar todas las suscripciones disponibles'
    )
    
    parser.add_argument(
        '--tenant-id',
        help='ID del tenant de Azure (opcional)'
    )
    
    parser.add_argument(
        '--resource-group',
        help='Nombre del grupo de recursos (opcional)'
    )
    
    parser.add_argument(
        '--identity-name',
        help='Nombre de la identidad administrada específica (opcional)'
    )
    
    parser.add_argument(
        '--format',
        choices=['json', 'csv', 'excel'],
        default='json',
        help='Formato de salida del reporte (default: json)'
    )
    
    parser.add_argument(
        '--output',
        help='Nombre del archivo de salida (opcional)'
    )
    
    parser.add_argument(
        '--use-cli-auth',
        action='store_true',
        help='Usar autenticación de Azure CLI en lugar de Managed Identity'
    )
    
    parser.add_argument(
        '--verbose',
        action='store_true',
        help='Habilitar logging verbose'
    )
    
    args = parser.parse_args()
    
    if args.verbose:
        logging.getLogger().setLevel(logging.DEBUG)
    
    # Validar parámetros
    if not args.all_subscriptions and not args.subscription_id:
        parser.error("Debes especificar --subscription-id o usar --all-subscriptions")
    
    if args.all_subscriptions and args.subscription_id:
        logger.warning("Se especificó --subscription-id y --all-subscriptions. Se usará --all-subscriptions.")
    
    try:
        # Crear el reporter
        reporter = FederatedIdentityReporter(
            subscription_id=args.subscription_id,
            use_cli_auth=args.use_cli_auth,
            all_subscriptions=args.all_subscriptions,
            tenant_id=args.tenant_id
        )
        
        # Generar el reporte
        logger.info("Iniciando generación de reporte...")
        report_data = reporter.generate_report(
            resource_group_name=args.resource_group,
            identity_name=args.identity_name
        )
        
        if not report_data:
            logger.warning("No se encontraron datos para el reporte")
            return
        
        # Determinar nombre del archivo de salida
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        if args.output:
            output_filename = args.output
        else:
            extension = 'xlsx' if args.format == 'excel' else args.format
            output_filename = f"federated_identity_credentials_report_{timestamp}.{extension}"
        
        # Exportar en el formato especificado
        if args.format == 'json':
            reporter.export_to_json(report_data, output_filename)
        elif args.format == 'csv':
            reporter.export_to_csv(report_data, output_filename)
        elif args.format == 'excel':
            reporter.export_to_excel(report_data, output_filename)
        
        # Exportar tuplas de credenciales (si hay datos)
        reporter.export_credentials_tuples(report_data, output_filename, args.format)
        
        # Mostrar resumen
        print(f"\n{'='*60}")
        print("RESUMEN DEL REPORTE")
        print(f"{'='*60}")
        print(f"Total de registros: {len(report_data)}")
        print(f"Archivo generado: {output_filename}")
        print(f"Formato: {args.format.upper()}")
        print(f"Timestamp: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"{'='*60}")
        
    except KeyboardInterrupt:
        logger.info("Operación cancelada por el usuario")
        sys.exit(1)
    except Exception as e:
        logger.error(f"Error ejecutando el script: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
