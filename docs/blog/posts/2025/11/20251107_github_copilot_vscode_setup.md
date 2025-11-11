---
draft: false
date: 2025-11-07
authors:
  - rfernandezdo
categories:
  - DevOps
tags:
  - GitHub Copilot
  - VSCode
  - Productivity
  - AI
---

# Configurar VSCode con GitHub Copilot: Guía práctica

## Resumen

Guía práctica para configurar GitHub Copilot en VSCode: custom instructions, prompt files, generación automática de conventional commits y uso de modos Ask/Edit/Agent para maximizar productividad en proyectos Azure/DevOps.

## ¿Qué es GitHub Copilot?

GitHub Copilot es un asistente de código basado en IA que sugiere código, genera tests, documenta funciones y responde preguntas técnicas directamente en tu editor. En VSCode, Copilot ofrece:

- **Completado de código inline**: Sugerencias mientras escribes
- **Chat interactivo**: Conversaciones sobre tu código
- **Generación de commits**: Mensajes siguiendo conventional commits
- **Modos de trabajo**: Ask, Edit y Agent para diferentes escenarios

## Instalación en VSCode

Requisitos previos:

- VSCode 1.99 o superior
- Cuenta GitHub con acceso a Copilot ([Copilot Free](https://github.com/copilot/free) disponible)

Pasos de instalación:

1. Abrir VSCode
2. Ir a Extensions (`Ctrl+Shift+X`)
3. Buscar "GitHub Copilot"
4. Instalar dos extensiones:
   - **GitHub Copilot** (autocompletado)
   - **GitHub Copilot Chat** (chat interactivo)

Autenticación:

```bash
# VSCode solicitará autenticación con GitHub
# Alternativamente desde Command Palette (Ctrl+Shift+P):
GitHub Copilot: Sign In
```

## Custom Instructions

Las instrucciones personalizadas permiten definir reglas y contexto que Copilot aplicará automáticamente, eliminando la necesidad de repetir el mismo contexto en cada prompt.

### Tipos de archivos de instrucciones

VSCode soporta tres tipos de archivos Markdown para instrucciones:

**1. `.github/copilot-instructions.md`** (instrucciones globales del workspace)

- Se aplica automáticamente a todas las conversaciones
- Un único archivo en la raíz del repositorio
- Compartido con todo el equipo vía Git

**2. `.instructions.md`** (instrucciones específicas por archivo/tarea)

- Múltiples archivos para diferentes contextos
- Usa frontmatter `applyTo` con glob patterns
- Puede ser workspace o user-level (sincronizable)

**3. `AGENTS.md`** (experimental, para múltiples agentes IA)

- En la raíz o subfolders del workspace
- Útil si trabajas con varios agentes IA
- Requiere habilitar `chat.useAgentsMdFile`

Estructura del proyecto:

```text
your-repo/
├── .github/
│   ├── copilot-instructions.md    ← Global workspace
│   ├── instructions/               ← Instrucciones específicas
│   │   ├── python.instructions.md
│   │   └── terraform.instructions.md
│   └── prompts/                    ← Prompts reutilizables
├── AGENTS.md                        ← Para múltiples agentes (experimental)
├── src/
└── README.md
```

Ejemplo de instrucciones para proyectos Azure/DevOps:

```markdown
# Instrucciones para GitHub Copilot

## Contexto del proyecto

Este repositorio contiene infraestructura Azure gestionada con Terraform y CI/CD con GitHub Actions.

## Convenciones de código

### Terraform

- Usar módulos para componentes reutilizables
- Variables en `variables.tf`, outputs en `outputs.tf`
- Naming: `<recurso>-<entorno>-<región>` (ejemplo: `st-prod-weu`)
- Tags obligatorios: Environment, Owner, CostCenter

### Python

- PEP 8 para estilo de código
- Type hints obligatorios en funciones públicas
- Docstrings en formato Google
- Tests con pytest, coverage mínimo 80%

### Commits

- Seguir conventional commits: `type(scope): description`
- Tipos permitidos: feat, fix, docs, chore, refactor, test
- Scope debe indicar área afectada: terraform, github-actions, scripts

## Seguridad

- NUNCA incluir credenciales hardcoded
- Usar Azure Key Vault para secretos
- Managed Identities sobre service principals
- Mínimo privilegio en roles RBAC

## Referencias

- Validar recursos Azure contra docs oficiales
- Seguir Azure Well-Architected Framework
- Bicep/Terraform: sintaxis actualizada
```

### Habilitar Custom Instructions en VSCode

**Opción 1: Habilitar en Settings**

```json
{
  "github.copilot.chat.codeGeneration.useInstructionFiles": true
}
```

**Opción 2: Generar automáticamente desde tu workspace**

VSCode puede analizar tu código y generar instrucciones que coincidan con tus prácticas:

1. Chat view → **Configure Chat** → **Generate Instructions**
2. Revisar y editar el archivo generado
3. Guardar en `.github/copilot-instructions.md`

**Validación**: Cuando Copilot use las instrucciones, aparecerá el archivo en la lista de "References" de la respuesta.

## Instrucciones específicas con .instructions.md

Además del archivo global, puedes crear instrucciones específicas para lenguajes, frameworks o tareas.

### Formato de .instructions.md

**Estructura**:

```markdown
---
description: "Descripción mostrada al hacer hover"
applyTo: "**/*.py"  # Glob pattern (relativo al workspace root)
---

# Instrucciones específicas para Python

- Seguir PEP 8
- Type hints obligatorios
- Docstrings en formato Google
```

**Ejemplo: Instrucciones para Terraform**

Archivo: `.github/instructions/terraform.instructions.md`

```markdown
---
description: "Terraform coding standards"
applyTo: "**/*.tf,**/*.tfvars"
---

# Terraform Best Practices

- Usar módulos para componentes reutilizables
- Variables en variables.tf, outputs en outputs.tf
- Naming convention: `<resource>-<environment>-<region>`
- Tags obligatorios: Environment, Owner, CostCenter
- Encryption habilitado por defecto
- Validar con `terraform validate` y `tflint`
```

### Crear instrucciones desde VSCode

**Comando**: `Chat: New Instructions File` (`Ctrl+Shift+P`)

1. Elegir ubicación:
   - **Workspace**: `.github/instructions/` (compartido vía Git)
   - **User**: Perfil de usuario (sincronizable entre dispositivos)
2. Nombrar archivo (ej: `python.instructions.md`)
3. Definir `applyTo` pattern en frontmatter
4. Escribir instrucciones en Markdown

**Adjuntar manualmente**: En Chat view → botón `+` → **Instructions** → seleccionar archivo

### Sincronizar instrucciones de usuario

Las instrucciones user-level pueden sincronizarse entre dispositivos:

1. Habilitar Settings Sync
2. `Ctrl+Shift+P` → **Settings Sync: Configure**
3. Seleccionar **Prompts and Instructions**

## Prompt Files (.github/prompts)

Los prompt files permiten crear plantillas de prompts reutilizables compartibles con el equipo.

### Crear prompts reutilizables

Ejemplo: Prompt para generar Terraform modules

Archivo: `.github/prompts/terraform-module.prompt.md`

```markdown
Crea un módulo Terraform para #selection siguiendo estas reglas:

1. Estructura estándar:
   - `main.tf`: recursos principales
   - `variables.tf`: inputs con validation
   - `outputs.tf`: valores exportados
   - `versions.tf`: provider constraints
   - `README.md`: documentación

2. Convenciones:
   - Variables: descripción, tipo, validación con condition
   - Outputs: descripción clara del valor exportado
   - Tags: usar merge() con var.tags

3. Seguridad:
   - Encryption habilitado por defecto
   - HTTPS obligatorio para endpoints
   - Logging habilitado

4. Documentación:
   - README con ejemplos de uso
   - Terraform-docs compatible
```

Archivo: `.github/prompts/fix-security.prompt.md`

```markdown
Analiza #file en busca de problemas de seguridad:

- Credenciales hardcoded
- Endpoints HTTP (deben ser HTTPS)
- Secretos en logs
- Permisos excesivos en RBAC
- Resources sin encryption
- Network security groups demasiado permisivos

Proporciona fix aplicando principio de mínimo privilegio y Zero Trust.
```

### Usar Prompt Files

En Copilot Chat:

```text
# Referenciar prompt file
#prompt:terraform-module

# Combinar con referencias
#prompt:fix-security #file:main.tf

# Agregar contexto adicional
#prompt:terraform-module para Azure Storage con lifecycle policies
```

Desde UI:

1. Abrir Copilot Chat (`Ctrl+Alt+I`)
2. Click en botón `+`
3. Seleccionar "Prompt Files"
4. Elegir prompt deseado

## Conventional Commits con Copilot

GitHub Copilot puede generar mensajes de commit siguiendo conventional commits automáticamente.

### Configuración para Conventional Commits

**Opción 1: Settings específico para commits** (recomendado)

Desde VS Code 1.102+, usar setting dedicado:

```json
{
  "github.copilot.chat.commitMessageGeneration.instructions": [
    {
      "text": "Seguir Conventional Commits 1.0.0: <type>(<scope>): <description>"
    },
    {
      "file": ".github/instructions/commit-standards.md"
    }
  ]
}
```

**Opción 2: Agregar a `.github/copilot-instructions.md`**

```markdown
## Git Commits

Todos los commits deben seguir Conventional Commits 1.0.0:

**Formato**: `<type>(<scope>): <description>`

**Types permitidos**:

- `feat`: Nueva funcionalidad
- `fix`: Corrección de bug
- `docs`: Cambios en documentación
- `chore`: Tareas de mantenimiento (deps, config)
- `refactor`: Refactorización sin cambio funcional
- `test`: Añadir o modificar tests
- `ci`: Cambios en CI/CD
- `perf`: Mejoras de performance

**Scope**: Área del proyecto afectada (terraform, github-actions, scripts, docs)

**Ejemplos**:

```text
feat(terraform): add Azure Front Door module
fix(github-actions): correct OIDC authentication
docs(readme): update deployment instructions
chore(deps): bump terraform-azurerm to 4.0
```

**Breaking changes**: Usar `!` o footer `BREAKING CHANGE:`

```text
feat(terraform)!: migrate to azurerm 4.0

BREAKING CHANGE: provider azurerm 3.x no longer supported
```

### Generar commits con Copilot

En Source Control panel de VSCode:

1. Hacer cambios en archivos
2. Stage changes
3. Click en icono ✨ (Sparkle) en message box
4. Copilot genera mensaje siguiendo conventional commits

Desde terminal con Git:

```bash
# Copilot CLI (requiere instalación adicional)
gh copilot suggest "git commit message for staged changes"
```

**Ejemplo de mensaje generado**:

```text
feat(terraform): add network security group for AKS

- Create NSG with default deny rules
- Allow only required ports (443, 80)
- Associate to AKS subnet
- Add diagnostic settings for logging
```

## Modos de Copilot Chat

Copilot ofrece tres modos de trabajo según el tipo de tarea.

### Ask Mode (Modo pregunta)

**Cuándo usar**: Consultas, explicaciones, búsqueda de información.

**Características**:

- Responde en el panel de chat
- No modifica archivos
- Proporciona ejemplos de código copiables

**Ejemplos**:

```text
# Explicar código
Explica qué hace #selection

# Mejores prácticas
¿Cuáles son las mejores prácticas para Azure Storage lifecycle policies?

# Comparar opciones
Diferencia entre Azure Container Apps y AKS

# Troubleshooting
¿Por qué falla este módulo de Terraform? #file:main.tf
```

### Edit Mode (Modo edición)

**Cuándo usar**: Modificar código existente, refactorizar.

**Características**:

- Propone cambios con preview diff
- Puedes aceptar/rechazar modificaciones
- Trabaja en archivos abiertos

**Activar Edit Mode**:

1. Seleccionar código
2. `Ctrl+I` (inline chat)
3. Escribir instrucción

**Ejemplos**:

```text
# Refactor
Refactoriza #selection para usar módulos reutilizables

# Optimizar
Optimiza este loop para mejor performance

# Agregar tests
Genera unit tests para #selection usando pytest

# Documentar
Agrega docstrings a todas las funciones en #file
```

### Agent Mode (Modo agente)

**Cuándo usar**: Tareas complejas multi-archivo, workflows completos.

**Características**:

- Ejecuta acciones en todo el workspace
- Crea/edita múltiples archivos
- Ejecuta comandos en terminal
- Requiere confirmación en pasos críticos

**Activar Agent Mode**:

1. Abrir Copilot Chat
2. Selector de modo → **Agent**
3. Confirmar modo activo

**Habilitar Agent Mode**:

VSCode Settings (`Ctrl+,`):

```json
{
  "chat.agent.enabled": true,
  "chat.agent.maxRequests": 128
}
```

**Ejemplos de tareas con Agent Mode**:

```text
# Crear proyecto completo
Crea un proyecto Terraform para desplegar Azure Container Apps con:
- Virtual Network con subnets
- Azure Container Registry
- Log Analytics Workspace
- Application Insights
- GitHub Actions workflow para CI/CD

# Migrar código
Migra todos los recursos en #folder de azurerm 3.x a 4.x

# Generar documentación
Genera README.md completo para este repositorio incluyendo:
- Descripción
- Arquitectura (diagrama Mermaid)
- Prerequisites
- Deployment steps
- Troubleshooting

# Implementar tests
Crea suite completa de tests para todos los módulos Terraform
```

**Best Practices para Agent Mode**:

1. **Prompts granulares**: Dividir tareas grandes en pasos pequeños
2. **Permitir que Copilot trabaje**: Dejar que ejecute tareas en vez de hacerlas manualmente
3. **Revisar cambios**: Validar modificaciones antes de commit
4. **Configurar auto-approve** (opcional):

```json
{
  "chat.tools.autoApprove": true
}
```

## Slash Commands

Comandos rápidos para tareas comunes sin escribir prompts largos.

| Command      | Descripción                         | Ejemplo                                    |
| ------------ | ----------------------------------- | ------------------------------------------ |
| `/doc`       | Generar documentación               | Seleccionar función → `/doc`               |
| `/explain`   | Explicar código                     | Seleccionar bloque → `/explain`            |
| `/fix`       | Proponer correcciones               | Seleccionar error → `/fix`                 |
| `/tests`     | Generar unit tests                  | Seleccionar función → `/tests using pytest`|
| `/optimize`  | Optimizar performance               | Seleccionar loop → `/optimize`             |
| `/generate`  | Generar código nuevo                | `/generate Azure Bicep for Storage Account`|

**Uso combinado con contexto**:

```text
# Con archivos
/explain #file:main.tf

# Con selección
/tests #selection using XUnit

# Con scope
/fix the authentication logic in #file:auth.py
```

## Herramientas de Agent Mode para Azure

Cuando trabajas con recursos Azure, Agent Mode tiene herramientas específicas.

**Verificar herramientas disponibles**:

```text
What are your tools?
```

**Herramientas Azure**:

- **Azure CLI tools**: Generar comandos `az`
- **Terraform tools**: Crear/validar configuraciones
- **GitHub Actions tools**: Generar workflows

**Ejemplo práctico**:

```text
# Generar comando Azure CLI
¿Cuál es el comando az para listar todas mis storage accounts ordenadas por región?
```

Copilot genera:

```bash
az storage account list --query "sort_by([], &location)[].{Name:name, Location:location}" --output table
```

## Mejores prácticas

### Contexto efectivo

**Proporcionar referencias específicas**:

```text
❌ MALO:
"Explica este código"

✅ BUENO:
"Explica #selection enfocándote en el flujo de autenticación OIDC"
```

**Usar scope adecuado**:

```text
# Archivo completo
#file:main.tf

# Función específica
#selection

# Múltiples archivos
#file:variables.tf #file:outputs.tf

# Workspace
#codebase (usa con precaución, puede ser lento)
```

### Organización de instrucciones

**Por archivo de instrucciones**:

- **Global** (`.github/copilot-instructions.md`): Principios generales del proyecto
- **Por lenguaje** (`.github/instructions/python.instructions.md`): Standards específicos
- **Por framework** (`.github/instructions/terraform.instructions.md`): Convenciones del stack
- **Por tarea** (`.github/instructions/security-review.instructions.md`): Workflows específicos

**Usar `applyTo` patterns efectivos**:

```markdown
---
applyTo: "**/*.{ts,tsx}"  # TypeScript y React
---

---
applyTo: "src/backend/**"  # Backend folder
---

---
applyTo: "terraform/**/*.tf"  # Solo Terraform files
---
```

### Seguridad

**Validar código generado**:

- No confiar ciegamente en sugerencias
- Revisar permisos y roles RBAC
- Verificar que no expone credenciales
- Comprobar configuraciones de red

**Ejemplo de validación**:

```text
Analiza #file:main.tf y verifica:
1. ¿Hay credenciales hardcoded?
2. ¿Todos los recursos tienen encryption habilitado?
3. ¿Network security groups siguen principio de mínimo privilegio?
4. ¿Están definidos todos los tags obligatorios?
```

### Iteración incremental

**Trabajar por pasos**:

```text
# ❌ Prompt demasiado amplio:
"Crea infraestructura completa para microservicios en Azure"

# ✅ Iteración incremental:
# Paso 1:
"Crea networking base: VNET con 3 subnets (app, data, management)"

# Paso 2:
"Agrega Azure Container Apps environment con internal VNET"

# Paso 3:
"Configura Application Gateway con WAF"
```

### Validación contra docs oficiales

Copilot puede estar desactualizado. Validar contra documentación oficial:

```text
# Verificar sintaxis actualizada
Muestra la sintaxis actual de azurerm_storage_account en Terraform 1.9

# Contrastar con docs
¿Esta configuración sigue las mejores prácticas de Azure Well-Architected Framework para seguridad?
```

### Tips oficiales (VSCode)

Según [documentación oficial](https://code.visualstudio.com/docs/copilot/customization/custom-instructions):

1. **Instrucciones cortas y autocontenidas**: Una declaración por instrucción
2. **Múltiples archivos por tema**: Usar `.instructions.md` con `applyTo` selectivo
3. **Workspace sobre user**: Compartir con equipo vía Git
4. **Referenciar en prompts**: Evitar duplicación con Markdown links
5. **Markdown links para contexto**: `[archivo](../path/file.ts)` o URLs externas

## Settings especializados

VSCode permite configurar instrucciones específicas para escenarios concretos:

### Settings disponibles

| Setting | Uso |
|---------|-----|
| `github.copilot.chat.commitMessageGeneration.instructions` | Generación de commit messages |
| `github.copilot.chat.pullRequestDescriptionGeneration.instructions` | Descripción de PRs |
| `github.copilot.chat.reviewSelection.instructions` | Code review |
| `github.copilot.chat.codeGeneration.instructions` | Generación de código (deprecated)* |
| `github.copilot.chat.testGeneration.instructions` | Generación de tests (deprecated)* |

*Desde VS Code 1.102, usar `.instructions.md` files en su lugar.

**Ejemplo completo en settings.json**:

```json
{
  // Commits con Conventional Commits
  "github.copilot.chat.commitMessageGeneration.instructions": [
    { "text": "Usar formato: <type>(<scope>): <description>" },
    { "text": "Types: feat, fix, docs, chore, refactor, test, ci, perf" }
  ],
  
  // PRs con checklist
  "github.copilot.chat.pullRequestDescriptionGeneration.instructions": [
    { "text": "Incluir siempre lista de cambios principales" },
    { "text": "Agregar sección Testing con casos probados" },
    { "file": ".github/instructions/pr-template.md" }
  ],
  
  // Code review enfocado en seguridad
  "github.copilot.chat.reviewSelection.instructions": [
    { "file": ".github/instructions/security-review.md" }
  ]
}
```

## Configuración avanzada VSCode

Settings recomendados para Copilot (`settings.json`):

```json
{
  // GitHub Copilot
  "github.copilot.enable": {
    "*": true,
    "yaml": true,
    "markdown": true,
    "terraform": true
  },
  
  // Instructions files
  "github.copilot.chat.codeGeneration.useInstructionFiles": true,
  "chat.instructionsFilesLocations": [
    ".github/instructions"  // Carpeta adicional para .instructions.md
  ],
  
  // AGENTS.md (experimental)
  "chat.useAgentsMdFile": false,  // true para habilitar
  "chat.useNestedAgentsMdFiles": false,  // subfolder support
  
  // Agent mode
  "chat.agent.enabled": true,
  "chat.agent.maxRequests": 128,
  
  // Editor
  "editor.inlineSuggest.enabled": true,
  "editor.suggestSelection": "first",
  
  // Opcional: Auto-approve (usar con precaución)
  "chat.tools.autoApprove": false
}
```

Keybindings personalizados (`.vscode/keybindings.json`):

```json
[
  {
    "key": "ctrl+shift+i",
    "command": "workbench.action.chat.open"
  },
  {
    "key": "ctrl+i",
    "command": "inlineChat.start",
    "when": "editorFocus"
  }
]
```

## Workflow recomendado

Flujo de trabajo típico con Copilot:

1. **Planificación**:

```text
# Agent Mode
Analiza los requisitos y propón arquitectura para [proyecto]
Genera diagrama Mermaid de la solución
```

2. **Implementación**:

```text
# Edit Mode
Usando #prompt:terraform-module, crea módulo para Azure Front Door
```

3. **Testing**:

```text
# Ask Mode
/tests #file:main.tf usando Terratest
```

4. **Documentación**:

```text
# Agent Mode
Genera documentación completa para #folder incluyendo:
- README con ejemplos
- Diagramas de arquitectura
- Runbooks de operaciones
```

5. **Commit**:

```text
# Source Control panel
Click en ✨ → genera conventional commit
```

6. **Validación**:

```text
# Ask Mode
Revisa #file:main.tf contra Azure security baseline
```

## Troubleshooting

### Copilot no responde

**Verificar**:

```bash
# Estado de extensión
Ctrl+Shift+P → "GitHub Copilot: Check Status"

# Logs
Ctrl+Shift+P → "GitHub Copilot: Open Logs"
```

**Soluciones comunes**:

- Verificar autenticación GitHub
- Reiniciar VSCode
- Comprobar firewall/proxy (requiere acceso a `*.github.com`)

### Sugerencias irrelevantes

**Mejorar contexto**:

- Usar custom instructions más específicas
- Proporcionar ejemplos en instructions
- Referenciar archivos relacionados en prompt

**Ejemplo**:

```text
❌ "Crea módulo Terraform"

✅ "Usando #file:examples/storage.tf como referencia, crea módulo 
   para #selection siguiendo #prompt:terraform-module"
```

### Agent Mode pide demasiadas confirmaciones

**Configurar auto-approve**:

```json
{
  "chat.tools.autoApprove": true
}
```

**Alternativa**: Click en "Always Allow" en diálogo de confirmación.

## MCP Server de Awesome Copilot

El repositorio [Awesome Copilot](https://github.com/github/awesome-copilot) incluye un MCP Server que permite buscar e instalar instrucciones, prompts y chat modes directamente desde VSCode.

### Instalación del MCP Server

Requiere Docker instalado y ejecutándose.

**Instalar en VSCode**:

1. [Install in VS Code](https://aka.ms/awesome-copilot/mcp/vscode)
2. Docker descargará la imagen automáticamente
3. Usar comando en Chat: `/awesome-copilot <query>`

**Ejemplo de uso**:

```text
/awesome-copilot create-readme
/awesome-copilot terraform best practices
/awesome-copilot security review
```

### Recursos del repositorio Awesome Copilot

El repositorio contiene cientos de contribuciones de la comunidad:

- **Agents**: Agentes especializados (Terraform, Security, Database, etc.)
- **Instructions**: Standards de código por lenguaje/framework
- **Prompts**: Tareas específicas (documentación, refactoring, testing)
- **Chat Modes**: Personas IA (arquitecto, DBA, security expert)
- **Collections**: Conjuntos curados por tema/workflow

**Explorar**:

- [Awesome Agents](https://github.com/github/awesome-copilot/blob/main/docs/README.agents.md)
- [Awesome Instructions](https://github.com/github/awesome-copilot/blob/main/docs/README.instructions.md)
- [Awesome Prompts](https://github.com/github/awesome-copilot/blob/main/docs/README.prompts.md)
- [Awesome Chat Modes](https://github.com/github/awesome-copilot/blob/main/docs/README.chatmodes.md)

## Referencias

- [GitHub Copilot Documentation](https://docs.github.com/en/copilot)
- [VSCode Custom Instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions)
- [VSCode Prompt Files](https://code.visualstudio.com/docs/copilot/customization/prompt-files)
- [VSCode Copilot Chat](https://code.visualstudio.com/docs/copilot/copilot-chat)
- [Awesome Copilot Repository](https://github.com/github/awesome-copilot)
- [Conventional Commits 1.0.0](https://www.conventionalcommits.org/)
- [Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/)
