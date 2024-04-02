---
draft: true
date: 2024-02-23
authors:
  - rfernandezdo
categories:
  - Azure Services
tags:
  - Azure Policy
  - EPAC  
---

# Usando EPAC para Desplegar Azure Policy

Azure Policy es una herramienta que nos permite gestionar y prevenir problemas de configuración en nuestros recursos de Azure. En este post, vamos a explorar cómo podemos usar EPAC para desplegar Azure Policy.

## ¿Qué es EPAC?

EPAC, o Enterprise Policy as Code, es una herramienta que nos permite definir y gestionar nuestras políticas como código. Esto significa que podemos versionar, probar y desplegar nuestras políticas de la misma manera que lo hacemos con nuestro código.

## Desplegando Azure Policy con EPAC

Para desplegar Azure Policy con EPAC, necesitaremos seguir los siguientes pasos:

1. **Definir la política**: Primero, necesitaremos definir nuestra política en un archivo de código. Este archivo definirá las reglas que queremos que se apliquen a nuestros recursos de Azure.

```json
{
  "if": {
    "allOf": [
      {
        "field": "type",
        "equals": "Microsoft.Compute/virtualMachines"
      },
      {
        "field": "Microsoft.Compute/virtualMachines/sku.name",
        "like": "Standard_D*"
      }
    ]
  },
  "then": {
    "effect": "audit"
  }
}
```

2. **Desplegar la política con EPAC**: Una vez que tenemos nuestra política definida, podemos usar EPAC para desplegarla. Esto se puede hacer usando la línea de comandos de EPAC o a través de la interfaz de usuario de EPAC.

```bash
epac deploy --policy policy.json --subscription my-subscription
```

3. **Verificar la política**: Finalmente, después de desplegar nuestra política, deberíamos verificar que se ha aplicado correctamente. Esto se puede hacer a través del portal de Azure o usando la línea de comandos de Azure.

```bash
az policy assignment list --query "[?name=='my-policy']"
```

Espero que este post te haya ayudado a entender cómo puedes usar EPAC para desplegar Azure Policy. Si tienes alguna pregunta, no dudes en dejar un comentario abajo.

---

# Conclusion

En este post, hemos explorado cómo podemos usar EPAC para desplegar Azure Policy. EPAC nos permite definir y gestionar nuestras políticas como código, lo que nos permite versionar, probar y desplegar nuestras políticas de la misma manera que lo hacemos con nuestro código. 

Espero que haya sido de ayuda.

