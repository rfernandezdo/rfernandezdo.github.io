---
draft: false
date: 2025-10-01
authors:
  - rfernandezdo
categories:
    - Enterprise Policy as Code
tags:
    - Document with EPAC
---

# Documentar con EPAC

EPAC tiene una opción muy útil llamada ["Document All Assignments"](https://azure.github.io/enterprise-azure-policy-as-code/operational-scripts-documenting-policy/#document-all-assignments) que genera Markdown y CSV con todas las asignaciones de policy. Pero hay dos detalles importantes que conviene saber:

1) Antes no se podían excluir tipos enteros de scope (por ejemplo: todas las
   `subscriptions` o `resourceGroups`) desde la configuración.

2) He subido una PR para solucionarlo: https://github.com/Azure/enterprise-azure-policy-as-code/pull/1056

Aquí lo que cambia, rápido y claro.

## Problema

Si usas `documentAllAssignments` y quieres evitar documentar todo lo que hay a
nivel de suscripción o de resource groups, la versión anterior obligaba a
listar cada id con `skipPolicyAssignments` o a procesar el CSV resultante.
En entornos grandes eso resulta muy tedioso y genera mucho ruido en los
informes.

## Qué hace la PR #1056

- Añade `excludeScopeTypes` en la configuración de `documentAllAssignments`.
  Con esto se puede indicar que no se documenten assignments que estén en
  `subscriptions` o en `resourceGroups`.
- Añade `StrictMode` (switch) en los scripts. Por defecto está activado. Si lo
  desactivas (`-StrictMode:$false`) el script no aborta cuando falta alguna
  definición; registra avisos y continúa. Útil en pipelines de prueba.
- Mejora el parsing y el manejo de `skipPolicyAssignments`/`skipPolicyDefinitions`
  (funcionan mejor con arrays u objetos) y corrige bugs menores (p. ej.
  convertir `markdownMaxParameterLength` a entero).

PR: https://github.com/Azure/enterprise-azure-policy-as-code/pull/1056

## Antes / Después (ejemplo práctico)

Antes tenías que usar algo así:

```jsonc
{
  "documentAssignments": {
    "documentAllAssignments": [
      {
        "pacEnvironment": "EPAC-Prod",
        "skipPolicyAssignments": [],
        "skipPolicyDefinitions": ["/providers/.../policySetDefinitions/..."]
      }
    ]
  }
}
```

Después basta con añadir `excludeScopeTypes`:

```jsonc
{
  "documentAssignments": {
    "documentAllAssignments": [
      {
        "pacEnvironment": "EPAC-Prod",
        "excludeScopeTypes": ["subscriptions", "resourceGroups"],
        "skipPolicyAssignments": [],
        "skipPolicyDefinitions": ["/providers/.../policySetDefinitions/..."]
      }
    ]
  }
}
```

Y si quieres pruebas rápidas sin que el pipeline falle por referencias
rotas:

```pwsh
./Build-PolicyDocumentation.ps1 -StrictMode:$false
```

## Recomendaciones prácticas

- Usa `excludeScopeTypes` para reducir ruido cuando necesites una vista global.
- No confundas `excludeScopeTypes` con exemptions: esto solo evita que se
  documente; no evita que la policy se aplique. Para eso usa exemptions.
- Mantén `StrictMode` activado en producción (ayuda a detectar referencias rotas).
- Usa `skipPolicyAssignments` para exclusiones puntuales que conozcas por id.

## Cierre

La mejora es pequeña pero práctica: menos limpieza manual, informes más
útiles. Si quieres puedo:

- Añadir un ejemplo real con IDs/outputs.
- Hacer build local del sitio y comprobar cómo queda el Markdown final.

PR de referencia: https://github.com/Azure/enterprise-azure-policy-as-code/pull/1056

