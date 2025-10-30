---
draft: false
date: 2025-10-21
authors:
  - rfernandezdo
categories:
  - Git
  - DevOps
  - Troubleshooting
tags:
  - git
  - merge
  - divergent-branches
  - version-control
---

# Cómo Resolver Divergencias en Git: Sincronizando Ramas Local y Remota

## El Problema

Al intentar hacer `git pull`, te encuentras con el siguiente error:

```bash
hint: You have divergent branches and need to specify how to reconcile them.
hint: You can do so by running one of the following commands sometime before
hint: your next pull:
hint:
hint:   git config pull.rebase false  # merge
hint:   git config pull.rebase true   # rebase
hint:   git config pull.ff only       # fast-forward only
```

Este mensaje indica que **tu rama local y la rama remota han divergido**: ambas tienen commits únicos que la otra no tiene. Git necesita que decidas cómo combinar estos cambios.

## ¿Por Qué Ocurre?

La divergencia sucede cuando:

1. **Trabajas localmente** y realizas commits en tu rama `main`
2. **Mientras tanto, cambios se fusionan en el remoto** (por ejemplo, a través de Pull Requests)
3. **Ambas ramas tienen commits exclusivos** que la otra no posee

Ejemplo visual:

```
Local:   A---B---C---L1
                      ^(tu commit local)
Remote:  A---B---C---R1---R2---R3
                      ^(commits del remoto vía PR)
```

## Análisis: Identificar la Divergencia

Antes de resolver, es crucial entender qué ha divergido.

### Paso 1: Sincronizar con el Remoto

```bash
git fetch origin main --tags
```

Este comando descarga los cambios del remoto sin fusionarlos.

### Paso 2: Comparar Commits

Verifica qué commits están únicamente en cada lado:

```bash
# Commits que tienes localmente pero no están en el remoto
git log origin/main..main --oneline

# Commits que están en el remoto pero no tienes localmente
git log main..origin/main --oneline
```

### Paso 3: Revisar los HEADs

```bash
# Ver el commit actual local
git rev-parse HEAD

# Ver el commit actual remoto
git rev-parse origin/main
```

### Ejemplo Real

En nuestro caso, obtuvimos:

```
--- Commits en local, no en remoto ---
81e3b93 feat: add new feature for data processing

--- Commits en remoto, no en local ---
9d3e3e9 Merge pull request #42 from team/feature/update-docs
285a538 Complete documentation review - all documents validated
000b9cb Fix configuration and add new parameters
a7694d3 Initial implementation plan
```

**Interpretación**: El remoto tiene un PR fusionado con 4 commits que no tenemos localmente, y nosotros tenemos 1 commit local que el remoto no tiene.

## Estrategias de Resolución

Existen tres estrategias principales:

### 1. Merge (Recomendado para Trabajo Colaborativo)

**Cuándo usarlo**: Cuando trabajas con un equipo y quieres preservar toda la historia, incluyendo los merge commits de PRs.

**Ventajas**:

- ✅ Preserva la historia completa (incluidos merge commits)
- ✅ Muestra claramente cuándo se integraron features
- ✅ Más seguro: no reescribe historia

**Desventajas**:

- ⚠️ Crea un commit de merge adicional
- ⚠️ Historia no completamente lineal

**Comando**:

```bash
git merge origin/main --no-edit
```

Si prefieres revisar/editar el mensaje de merge:

```bash
git merge origin/main
```

### 2. Rebase (Para Historia Lineal)

**Cuándo usarlo**: Cuando trabajas solo o en una feature branch que aún no has compartido públicamente.

**Ventajas**:

- ✅ Historia completamente lineal
- ✅ Más limpia para revisar con `git log`

**Desventajas**:

- ⚠️ Reescribe commits locales (cambian sus SHAs)
- ⚠️ Puede causar problemas si ya compartiste estos commits
- ⚠️ Pierdes el contexto de cuándo se integró el PR remoto

**Comando**:

```bash
git rebase origin/main
```

### 3. Fast-Forward Only (Restrictivo)

**Cuándo usarlo**: Cuando quieres asegurarte de que solo hagas `pull` si no hay divergencia.

**Comando**:

```bash
git config pull.ff only
git pull
```

Si hay divergencia, fallará y tendrás que decidir merge o rebase manualmente.

## Solución Paso a Paso (Merge)

### 1. Analizar la Situación

```bash
# Sincronizar con remoto
git fetch origin main --tags

# Ver divergencias
echo "--- Commits locales únicos ---"
git log origin/main..main --oneline

echo "--- Commits remotos únicos ---"
git log main..origin/main --oneline
```

### 2. Decidir Estrategia

Para equipos colaborativos con PRs, **merge** es la opción más segura:

```bash
git merge origin/main --no-edit
```

### 3. Resolver Conflictos (Si Ocurren)

Si hay conflictos, Git te lo indicará:

```bash
Auto-merging some-file.md
CONFLICT (content): Merge conflict in some-file.md
Automatic merge failed; fix conflicts and then commit the result.
```

**Pasos para resolver**:

a) Abre el archivo con conflictos:

```markdown
<<<<<<< HEAD
Tu versión local
=======
Versión del remoto
>>>>>>> origin/main
```

b) Edita manualmente para quedarte con el contenido correcto

c) Marca como resuelto:

```bash
git add some-file.md
```

d) Completa el merge:

```bash
git commit -m "Merge origin/main into main"
```

### 4. Verificar el Resultado

```bash
# Ver el log reciente
git log --oneline --graph -10
```

Deberías ver algo como:

```
*   3e1ed57 (HEAD -> main) Merge remote-tracking branch 'origin/main' into main
|\
| * 9d3e3e9 (origin/main) Merge pull request #42
| * 285a538 Complete documentation review
| * 000b9cb Fix configuration parameters
| * a7694d3 Initial implementation plan
* | 81e3b93 feat: add new feature for data processing
|/
* d140dce feat: improved monthly workflow
```

### 5. Empujar los Cambios

```bash
git push origin main
```

Salida esperada:

```
Enumerating objects: 15, done.
Counting objects: 100% (12/12), done.
Delta compression using up to 8 threads
Compressing objects: 100% (7/7), done.
Writing objects: 100% (7/7), 1.08 KiB | 1.08 MiB/s, done.
Total 7 (delta 5), reused 0 (delta 0)
remote: Resolving deltas: 100% (5/5), completed with 4 local objects.
To https://github.com/tu-usuario/tu-repositorio.git
   9d3e3e9..3e1ed57  main -> main
```

## Verificación Post-Merge

### Comprobar Archivos Críticos

Si tienes workflows de CI/CD u otros archivos críticos, verifica su integridad:

```bash
# Buscar un patrón específico en un archivo
grep -n "specific_pattern" .github/workflows/deploy.yml

# O leer el archivo completo
cat .github/workflows/deploy.yml
```

### Confirmar Sincronización

```bash
# Ambos deberían apuntar al mismo commit ahora
git rev-parse HEAD
git rev-parse origin/main
```

## Configuración Permanente

Si quieres establecer una estrategia por defecto para futuros `git pull`:

### Para Merge (Recomendado)

```bash
git config pull.rebase false
```

### Para Rebase

```bash
git config pull.rebase true
```

### Global (Todos tus Repos)

Añade `--global`:

```bash
git config --global pull.rebase false
```

## Mejores Prácticas

### ✅ Hacer Fetch Frecuentemente

```bash
# Ejecutar cada mañana o antes de empezar a trabajar
git fetch origin
```

Esto te mantiene informado de cambios remotos sin afectar tu trabajo local.

### ✅ Trabajar en Feature Branches

En lugar de trabajar directamente en `main`:

```bash
git checkout -b feature/my-feature
# ... hacer commits ...
git push origin feature/my-feature
# Abrir PR en GitHub
```

Esto evita divergencias en `main`.

### ✅ Pull Antes de Push

```bash
git fetch origin
git status
# Si hay cambios remotos, decide merge o rebase
git pull
# Ahora puedes pushear
git push
```

### ⚠️ Evitar Force Push en Ramas Compartidas

```bash
# ❌ NUNCA en main compartido
git push --force origin main

# ✅ OK solo en tus feature branches
git push --force origin feature/my-feature
```

## Casos Especiales

### Si Hiciste Rebase por Error y Quieres Revertir

```bash
# Ver el reflog (historial de cambios de HEAD)
git reflog

# Volver a un estado anterior
git reset --hard HEAD@{2}
```

### Si Quieres Descartar Tus Commits Locales

```bash
# ⚠️ CUIDADO: Esto descarta tus commits locales permanentemente
git reset --hard origin/main
```

### Si Quieres Preservar Cambios Locales Sin Commit

```bash
# Guardar cambios temporalmente
git stash

# Sincronizar con remoto
git pull

# Recuperar tus cambios
git stash pop
```

## Resumen: Checklist Rápido

- [ ] **Fetch**: `git fetch origin main --tags`
- [ ] **Analizar**: `git log origin/main..main --oneline` y `git log main..origin/main --oneline`
- [ ] **Decidir**: Merge (preservar historia) vs Rebase (lineal)
- [ ] **Ejecutar**: `git merge origin/main` o `git rebase origin/main`
- [ ] **Resolver**: Conflictos si los hay
- [ ] **Verificar**: `git log --graph --oneline -10`
- [ ] **Push**: `git push origin main`
- [ ] **Confirmar**: Archivos críticos intactos

## Conclusión

La divergencia de ramas es un escenario común en equipos colaborativos. La clave está en:

1. **Entender qué ha divergido** (análisis con `git log`)
2. **Elegir la estrategia correcta** (merge para equipos, rebase para trabajo local)
3. **Verificar el resultado** antes de hacer push

En entornos colaborativos con Pull Requests, **merge es generalmente la opción más segura** ya que preserva la historia completa y evita reescribir commits que otros pueden estar usando como base.

---

## Referencias

- [Git Documentation - git-merge](https://git-scm.com/docs/git-merge)
- [Git Documentation - git-rebase](https://git-scm.com/docs/git-rebase)
- [Atlassian Git Tutorials - Merging vs. Rebasing](https://www.atlassian.com/git/tutorials/merging-vs-rebasing)
