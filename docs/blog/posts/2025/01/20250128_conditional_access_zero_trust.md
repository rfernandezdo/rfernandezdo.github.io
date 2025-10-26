---
draft: false
date: 2025-01-28
authors:
  - rfernandezdo
categories:
  - Azure Security
tags:
  - Microsoft Entra ID
  - Conditional Access
  - Zero Trust
---

# Conditional Access: Políticas esenciales para Zero Trust

## Resumen

Conditional Access es el corazón de Zero Trust en Azure. aquí están las 5 políticas que deberías implementar HOY en tu tenant.

## ¿Qué es Conditional Access?

Conditional Access evalúa signals en tiempo real para decidir si permitir, bloquear o requerir MFA en un acceso:

**Signals:**
- Usuario/grupo
- Ubicación (IP ranges)
- Dispositivo (managed, compliant)
- Aplicación
- Riesgo (Azure AD Identity Protection)

**Decisiones:**
- Permitir
- Bloquear
- Requiere MFA
- Requiere dispositivo compliant
- Requiere hybrid Azure AD join

## Prerequisitos

```bash
# Verificar licencias (P1 mínimo)
az ad signed-in-user show --query "assignedLicenses[].skuId"

# Crear grupo de exclusión (break-glass accounts)
az ad group create \
  --display-name "CA-Exclusion-Emergency" \
  --mail-nickname "ca-exclusion"
```

!!! warning "Break-glass accounts"
    SIEMPRE excluye 2 cuentas de emergencia de todas las políticas CA. Si algo falla, necesitas acceso.

## Política 1: MFA para todos los admins

```bash
# Esta política la creas desde el portal por ser más visual
# Portal → Azure AD → Security → Conditional Access
```

**Configuración:**
- **Usuarios**: Todos los roles admin (Global Admin, Security Admin, etc.)
- **Cloud apps**: Todas las aplicaciones
- **Condiciones**: Ninguna
- **Grant**: Require MFA
- **Estado**: Report-only (primero testea)

JSON de ejemplo (via API):

```json
{
  "displayName": "CA001: Require MFA for administrators",
  "state": "enabledForReportingButNotEnforced",
  "conditions": {
    "users": {
      "includeRoles": [
        "62e90394-69f5-4237-9190-012177145e10",  // Global Admin
        "194ae4cb-b126-40b2-bd5b-6091b380977d"   // Security Admin
      ],
      "excludeGroups": ["break-glass-group-id"]
    },
    "applications": {
      "includeApplications": ["All"]
    }
  },
  "grantControls": {
    "operator": "OR",
    "builtInControls": ["mfa"]
  }
}
```

## Política 2: Bloquear legacy authentication

Legacy auth (IMAP, POP3, SMTP) no soporta MFA → vector de ataque.

```json
{
  "displayName": "CA002: Block legacy authentication",
  "state": "enabled",
  "conditions": {
    "users": {
      "includeUsers": ["All"],
      "excludeGroups": ["break-glass-group-id"]
    },
    "applications": {
      "includeApplications": ["All"]
    },
    "clientAppTypes": [
      "exchangeActiveSync",
      "other"  // Incluye IMAP, POP3, SMTP
    ]
  },
  "grantControls": {
    "operator": "OR",
    "builtInControls": ["block"]
  }
}
```

## Política 3: Requiere managed devices para apps corporativas

```json
{
  "displayName": "CA003: Require compliant device for corporate apps",
  "state": "enabled",
  "conditions": {
    "users": {
      "includeUsers": ["All"],
      "excludeGroups": ["break-glass-group-id"]
    },
    "applications": {
      "includeApplications": [
        "00000003-0000-0000-c000-000000000000",  // Microsoft Graph
        "Office365"
      ]
    },
    "platforms": {
      "includePlatforms": ["windows", "macOS", "iOS", "android"]
    }
  },
  "grantControls": {
    "operator": "OR",
    "builtInControls": [
      "compliantDevice",
      "domainJoinedDevice"
    ]
  }
}
```

## Política 4: Bloquear acceso desde países no autorizados

```bash
# Crear Named Location
az rest --method PUT \
  --url 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations' \
  --body '{
    "@odata.type": "#microsoft.graph.countryNamedLocation",
    "displayName": "Blocked Countries",
    "countriesAndRegions": ["KP", "IR", "SY"],
    "includeUnknownCountriesAndRegions": false
  }'
```

Política:

```json
{
  "displayName": "CA004: Block access from blocked countries",
  "state": "enabled",
  "conditions": {
    "users": {
      "includeUsers": ["All"],
      "excludeGroups": ["break-glass-group-id", "travelers-group-id"]
    },
    "applications": {
      "includeApplications": ["All"]
    },
    "locations": {
      "includeLocations": ["blocked-countries-location-id"]
    }
  },
  "grantControls": {
    "operator": "OR",
    "builtInControls": ["block"]
  }
}
```

## Política 5: MFA para acceso desde fuera de red corporativa

```bash
# Crear Named Location para IPs corporativas
az rest --method POST \
  --url 'https://graph.microsoft.com/v1.0/identity/conditionalAccess/namedLocations' \
  --body '{
    "@odata.type": "#microsoft.graph.ipNamedLocation",
    "displayName": "Corporate Network",
    "isTrusted": true,
    "ipRanges": [
      {"@odata.type": "#microsoft.graph.iPv4CidrRange", "cidrAddress": "203.0.113.0/24"},
      {"@odata.type": "#microsoft.graph.iPv4CidrRange", "cidrAddress": "198.51.100.0/24"}
    ]
  }'
```

Política:

```json
{
  "displayName": "CA005: Require MFA for external access",
  "state": "enabled",
  "conditions": {
    "users": {
      "includeUsers": ["All"],
      "excludeGroups": ["break-glass-group-id"]
    },
    "applications": {
      "includeApplications": ["All"]
    },
    "locations": {
      "includeLocations": ["Any"],
      "excludeLocations": ["corporate-network-location-id"]
    }
  },
  "grantControls": {
    "operator": "OR",
    "builtInControls": ["mfa"]
  }
}
```

## Testing con Report-Only mode

```bash
# Ver reportes de impacto
# Portal → Azure AD → Sign-in logs → Conditional Access tab
```

Analiza:
- ¿Cuántos usuarios impactados?
- ¿Algún servicio crítico bloqueado?
- ¿Break-glass accounts funcionando?

Después de 7-14 días de monitoring → cambiar a `enabled`.

## Monitoreo continuo

Query en Log Analytics:

```kusto
SigninLogs
| where TimeGenerated > ago(24h)
| where ConditionalAccessStatus != "notApplied"
| summarize count() by ConditionalAccessStatus, ConditionalAccessPolicies
| order by count_ desc
```

Alerta para fallos:

```bash
az monitor scheduled-query create \
  --resource-group $RG \
  --name ca-policy-failures \
  --scopes /subscriptions/{sub-id}/resourceGroups/$RG/providers/Microsoft.OperationalInsights/workspaces/my-law \
  --condition "count 'SigninLogs | where ConditionalAccessStatus == \"failure\"' > 10" \
  --window-size 5m \
  --evaluation-frequency 5m \
  --action /subscriptions/{sub-id}/resourceGroups/$RG/providers/Microsoft.Insights/actionGroups/security-team
```

## Política avanzada: Risk-based con Identity Protection

Requiere Azure AD P2:

```json
{
  "displayName": "CA006: Block high risk sign-ins",
  "state": "enabled",
  "conditions": {
    "users": {
      "includeUsers": ["All"],
      "excludeGroups": ["break-glass-group-id"]
    },
    "applications": {
      "includeApplications": ["All"]
    },
    "signInRiskLevels": ["high"]
  },
  "grantControls": {
    "operator": "OR",
    "builtInControls": ["block"]
  }
}
```

## Buenas prácticas

- **Naming convention**: `CA###: [Acción] for [Condición]`
- **Report-only primero**: Nunca actives sin testear
- **Exclusiones documentadas**: Justifica cada grupo excluido
- **Review trimestral**: Las políticas se vuelven obsoletas
- **Combinación de políticas**: No crees una mega-política, divide por propósito
- **What If tool**: Usa el simulador antes de activar

!!! danger "Errores comunes"
    - Bloquear sin break-glass accounts
    - No testear en report-only mode
    - Aplicar a "All apps" sin excluir Azure Management
    - No documentar políticas

## Referencias

- [What is Conditional Access?](https://learn.microsoft.com/en-us/entra/identity/conditional-access/overview)
- [Conditional Access templates](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-policy-common)
- [Plan a Conditional Access deployment](https://learn.microsoft.com/en-us/entra/identity/conditional-access/plan-conditional-access)
