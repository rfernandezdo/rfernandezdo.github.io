---
draft: false
date: 2025-02-10
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure API Management
  - API Gateway
  - Security
---

# Azure API Management: Políticas esenciales de seguridad

## Resumen

API Management no es solo un proxy. Las políticas (policies) te dan control total: rate limiting, auth, transformaciones, caching, circuit breakers. Aquí las más importantes.

## Arquitectura de políticas

Las políticas se aplican en 4 fases:

```xml
<policies>
  <inbound>   <!-- Antes de enviar a backend -->
  </inbound>
  <backend>   <!-- Modificar llamada a backend -->
  </backend>
  <outbound>  <!-- Modificar respuesta -->
  </outbound>
  <on-error>  <!-- Manejo de errores -->
  </on-error>
</policies>
```

## Política 1: Rate limiting

```xml
<policies>
  <inbound>
    <rate-limit calls="100" renewal-period="60" />
    <!-- 100 llamadas por minuto -->
    
    <!-- Rate limit por suscripción -->
    <rate-limit-by-key calls="1000"
                        renewal-period="3600"
                        counter-key="@(context.Subscription.Id)" />
    
    <!-- Quota mensual -->
    <quota calls="1000000" renewal-period="2592000" />
  </inbound>
</policies>
```

## Política 2: Validar JWT

```xml
<policies>
  <inbound>
    <validate-jwt header-name="Authorization" failed-validation-httpcode="401">
      <openid-config url="https://login.microsoftonline.com/{tenant}/.well-known/openid-configuration" />
      <audiences>
        <audience>api://my-api</audience>
      </audiences>
      <issuers>
        <issuer>https://sts.windows.net/{tenant}/</issuer>
      </issuers>
      <required-claims>
        <claim name="roles" match="any">
          <value>Admin</value>
          <value>User</value>
        </claim>
      </required-claims>
    </validate-jwt>
  </inbound>
</policies>
```

## Política 3: Caching

```xml
<policies>
  <inbound>
    <cache-lookup vary-by-developer="false"
                  vary-by-developer-groups="false"
                  allow-private-response-caching="false">
      <vary-by-header>Accept</vary-by-header>
      <vary-by-query-parameter>category</vary-by-query-parameter>
    </cache-lookup>
  </inbound>
  <outbound>
    <cache-store duration="3600" />
    <!-- Cache por 1 hora -->
  </outbound>
</policies>
```

## Política 4: Transformar request/response

```xml
<policies>
  <inbound>
    <!-- Añadir header de autenticación al backend -->
    <set-header name="X-API-Key" exists-action="override">
      <value>{{backend-api-key}}</value>
    </set-header>
    
    <!-- Reescribir URL -->
    <rewrite-uri template="/v2/api/{path}" />
    
    <!-- Transformar body -->
    <set-body template="liquid">
    {
      "requestId": "{{context.RequestId}}",
      "timestamp": "{{DateTime.UtcNow}}",
      "data": {{body}}
    }
    </set-body>
  </inbound>
  
  <outbound>
    <!-- Eliminar headers internos -->
    <set-header name="X-Internal-Server" exists-action="delete" />
    
    <!-- Transformar respuesta JSON -->
    <find-and-replace from="&quot;oldField&quot;" to="&quot;newField&quot;" />
  </outbound>
</policies>
```

## Política 5: Circuit breaker

```xml
<policies>
  <inbound>
    <base />
  </inbound>
  <backend>
    <retry condition="@(context.Response.StatusCode >= 500)"
           count="3"
           interval="1"
           delta="1"
           first-fast-retry="true">
      <forward-request timeout="10" />
    </retry>
  </backend>
  <on-error>
    <return-response>
      <set-status code="503" reason="Service Unavailable" />
      <set-body>Backend service is temporarily unavailable</set-body>
    </return-response>
  </on-error>
</policies>
```

## Política 6: IP whitelist

```xml
<policies>
  <inbound>
    <ip-filter action="allow">
      <address>192.168.1.1</address>
      <address-range from="10.0.0.1" to="10.0.0.255" />
    </ip-filter>
  </inbound>
</policies>
```

## Named Values para secretos

```bash
# Crear named value (variable global)
az apim nv create \
  --resource-group $RG \
  --service-name my-apim \
  --named-value-id backend-api-key \
  --display-name "Backend API Key" \
  --value "secret-key-12345" \
  --secret true

# Usar en política: {{backend-api-key}}
```

## Buenas prácticas

- **Rate limiting**: Siempre por subscription/IP
- **Caching**: Solo para GET requests idempotentes
- **Secrets**: Usa Named Values con KeyVault integration
- **Error handling**: Customiza mensajes de error, no expongas internals
- **Logging**: Habilita Application Insights para todas las APIs

## Referencias

- [API Management policies](https://learn.microsoft.com/en-us/azure/api-management/api-management-policies)
