# Pre-commit Hook para validación de posts MkDocs

Este repositorio usa **pre-commit** para validar automáticamente los posts antes de hacer commit.

## 🚀 Instalación rápida

```bash
# 1. Instalar pre-commit (si no está instalado)
pip install pre-commit

# 2. Instalar los hooks en el repositorio
pre-commit install
```

## ✅ ¿Qué valida?

### Hook personalizado: `validate-mkdocs-posts`
Ejecuta `scripts/validate_post.py` en todos los archivos `.md` dentro de `docs/blog/posts/`:

- ✅ Formato de nombre de archivo (`YYYYMMDD_slug.md`)
- ✅ Frontmatter obligatorio (draft, date, authors, categories, tags)
- ✅ Formato de fecha ISO 8601 (`YYYY-MM-DD`)
- ✅ Author correcto (`rfernandezdo`)
- ✅ Sin marcas prohibidas ("validado MCP", etc.)
- ⚠️ Secciones recomendadas (Resumen, Referencias)
- ⚠️ Bloques de código con lenguaje especificado

### Hooks estándar de Python
- `trailing-whitespace`: Elimina espacios al final de líneas
- `end-of-file-fixer`: Asegura salto de línea al final de archivos
- `check-yaml`: Valida sintaxis YAML (mkdocs.yml)
- `check-added-large-files`: Bloquea archivos >500KB
- `check-merge-conflict`: Detecta marcas de conflicto de merge

### Hook de Markdown (opcional - comentado por defecto)
- `markdownlint`: Validación de estilo Markdown
- **Requiere Ruby**: Si deseas usarlo, instala Ruby y descomenta en `.pre-commit-config.yaml`
- **No necesario**: El hook `validate-mkdocs-posts` ya valida estructura básica

## 🔄 Uso diario

### Commit normal (hooks se ejecutan automáticamente)
```bash
git add docs/blog/posts/2025/10/20251026_mi_post.md
git commit -m "Agregar post sobre tema X"
# Pre-commit ejecutará validaciones automáticamente

# Salida si el post es válido:
# Validar formato posts MkDocs.............Passed
# [main abc1234] Agregar post sobre tema X
#  1 file changed, 50 insertions(+)

# Salida si el post tiene errores:
# Validar formato posts MkDocs.............Failed
# - hook id: validate-mkdocs-posts
# ❌ ERRORES CRÍTICOS:
#   1. Formato de fecha inválido: '26/10/2025'. Debe ser YYYY-MM-DD
#   2. Author debe ser 'rfernandezdo' (case-sensitive)
# ❌ Post inválido - corrige los errores críticos
#
# El commit se bloqueará hasta corregir los errores
```

### Ejecutar validaciones manualmente
```bash
# Validar todos los archivos
pre-commit run --all-files

# Validar solo archivos staged
pre-commit run

# Validar un hook específico
pre-commit run validate-mkdocs-posts --all-files
```

### Saltar validaciones (NO RECOMENDADO)
```bash
# Solo en casos excepcionales (ej: WIP commits)
git commit --no-verify -m "WIP: trabajo en progreso"
```

## 🐛 Solución de problemas

### Error: "command not found: pre-commit"
```bash
pip install pre-commit
pre-commit install
```

### Error: "No module named 'yaml'"
```bash
pip install pyyaml
```

### Hook falla en un post específico
```bash
# Validar manualmente para ver el error detallado
python scripts/validate_post.py docs/blog/posts/2025/10/20251026_post.md

# Corregir errores críticos reportados
# Luego reintentar commit
git commit
```

### Desinstalar hooks
```bash
pre-commit uninstall
```

## 📋 Flujo de trabajo completo

```bash
# 1. Activar entorno virtual
source mysite/bin/activate

# 2. Crear post
touch docs/blog/posts/2025/10/20251026_mi_post.md

# 3. Escribir contenido con plantilla

# 4. Validar antes de commit (opcional)
python scripts/validate_post.py docs/blog/posts/2025/10/20251026_mi_post.md

# 5. Agregar al stage
git add docs/blog/posts/2025/10/20251026_mi_post.md

# 6. Commit (pre-commit se ejecuta automáticamente)
git commit -m "Agregar post sobre Azure Storage avanzado"

# 7. Si hay errores, corregir y reintentar
# Los hooks bloquearán el commit si hay errores críticos

# 8. Push cuando todo esté verde
git push origin main
```

## ⚙️ Configuración

### `.pre-commit-config.yaml`
Configuración principal de hooks. Modificar si necesitas:
- Cambiar versiones de hooks
- Añadir/quitar hooks
- Ajustar argumentos o exclusiones

### `.markdownlint.json`
Configuración de reglas de Markdown. Personalizada para permitir:
- Líneas largas (código/URLs)
- HTML inline (tablas complejas)
- URLs sin formato

### Excluir archivos
Agregar patrones en `.pre-commit-config.yaml`:
```yaml
- id: validate-mkdocs-posts
  exclude: ^docs/blog/posts/template/
```

## 🔗 Referencias

- Pre-commit framework: https://pre-commit.com/
- Hooks disponibles: https://pre-commit.com/hooks.html
- Script de validación: `scripts/README_validate_post.md`

## 💡 Buenas prácticas

1. **Instala pre-commit en cada clone**: `pre-commit install`
2. **Ejecuta validación manual antes de commit grande**: `pre-commit run --all-files`
3. **No uses `--no-verify` salvo emergencia**: Los hooks protegen la calidad
4. **Mantén hooks actualizados**: `pre-commit autoupdate`
5. **Revisa errores antes de forzar push**: Los hooks te ahorran tiempo en CI/CD

---

Con pre-commit instalado, cada commit en `docs/blog/posts/` será validado automáticamente antes de ser registrado. ✨
