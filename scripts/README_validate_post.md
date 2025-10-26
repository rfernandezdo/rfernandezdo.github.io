# Script de Validación de Posts MkDocs

Script Python para validar posts del blog antes de publicarlos.

## Propósito

Detecta errores de formato que pueden romper el blog:
- Fecha incorrecta → el post no aparecerá
- Author incorrecto → enlace roto al perfil
- Frontmatter malformado → error en build
- Marcas prohibidas → contenido no apto para publicación

## Uso

### Validar un post individual

```bash
python scripts/validate_post.py docs/blog/posts/2025/10/20251026_mi_post.md
```

### Validar todos los posts de un año

```bash
for post in docs/blog/posts/2025/*/*.md; do
    python scripts/validate_post.py "$post"
done
```

### Integrar en pre-commit

```bash
# Validar posts modificados antes de commit
git diff --name-only --cached | grep -E 'docs/blog/posts/.*\.md$' | while read file; do
    python scripts/validate_post.py "$file" || exit 1
done
```

## Validaciones ejecutadas

### ❌ Errores críticos (bloquean publicación)

1. **Nombre de archivo**: Debe seguir `YYYYMMDD_slug.md`
   - ✅ Correcto: `20251026_mi_post.md`
   - ❌ Incorrecto: `mi-post.md`, `26-10-2025_post.md`

2. **Frontmatter obligatorio**:
   ```yaml
   ---
   draft: false
   date: 2025-10-26
   authors:
     - rfernandezdo
   categories:
     - Categoría
   tags:
     - Tag1
   ---
   ```

3. **Formato de fecha**: YYYY-MM-DD (ISO 8601)
   - ✅ Correcto: `2025-10-26`
   - ❌ Incorrecto: `26/10/2025`, `26-10-2025`, `2025/10/26`

4. **Author exacto**: `rfernandezdo` (case-sensitive)
   - ✅ Correcto: `rfernandezdo`
   - ❌ Incorrecto: `Rfernandezdo`, `rfdo`, `autor`

5. **Marcas prohibidas**: No incluir textos como:
   - `validado MCP`
   - `verificado con MCP`
   - `validado Terraform MCP`

   (La validación es interna, no se expone en el post)

### ⚠️ Advertencias (no bloquean)

- Fecha en filename no coincide con frontmatter
- Falta sección `## Resumen`
- Falta sección `## Referencias`
- Bloques de código sin lenguaje (````bash`, ````python`, etc.)
- Listas vacías en categories/tags

## Salida del script

```
======================================================================
Validando: 20251026_mi_post.md
======================================================================

✅ Post válido - no se encontraron problemas
```

O con errores:

```
======================================================================
Validando: 20251026_post_malo.md
======================================================================

❌ ERRORES CRÍTICOS:
  1. Formato de fecha inválido: '26/10/2025'. Debe ser YYYY-MM-DD (ISO 8601)
  2. Author debe ser 'rfernandezdo' (case-sensitive)

⚠️  ADVERTENCIAS:
  1. Falta sección '## Referencias' recomendada

❌ Post inválido - corrige los errores críticos
```

## Códigos de salida

- `0`: Post válido (puede tener advertencias)
- `1`: Post inválido (errores críticos encontrados)

## Integración en workflow

### Paso recomendado al crear posts

1. Escribir post con plantilla
2. **Ejecutar validación**: `python scripts/validate_post.py <archivo>`
3. Corregir errores si existen
4. Preview local: `mkdocs serve`
5. Commit y push

### Automatización con GitHub Actions

```yaml
- name: Validate Posts
  run: |
    for post in docs/blog/posts/**/*.md; do
      python scripts/validate_post.py "$post" || exit 1
    done
```

## Dependencias

- Python 3.7+
- PyYAML (incluido en `requirements.txt`)

## Notas

- El script NO modifica archivos, solo valida
- Es safe ejecutarlo en cualquier momento
- Útil antes de preview local para detectar errores temprano
