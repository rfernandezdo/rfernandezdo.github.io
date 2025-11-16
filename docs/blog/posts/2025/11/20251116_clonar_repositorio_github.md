---
draft: false
date: 2025-11-16
authors:
  - rfernandezdo
categories:
  - DevOps
tags:
  - GitHub
  - Git
  - Repositorios
  - Migración
  - Ownership
  - Mirror
---

# Clonar un Repositorio de GitHub de una organización a otra: Guía Paso a Paso


## Resumen
Clonar un repositorio de GitHub entre organizaciones es útil cuando no puedes (o no te conviene) transferir el ownership. Con el enfoque correcto, duplicas todo el historial, ramas y tags en un repo nuevo sin romper nada en el origen.

## ¿Cuándo clonar y no transferir?

- Transferir no es posible por políticas de la organización o compliance.
- Necesitas mantener el repo original activo (p. ej., hard fork interno).
- Quieres validar/limitar qué migra (código e historial sí; issues/PRs no).

## Requisitos

- Permisos de lectura en el repo origen y de escritura en el repo destino.
- Repo destino creado y vacío en la organización de destino.
- Autenticación configurada:
  - SSH: tener clave cargada en GitHub.
  - HTTPS: usar PAT con permisos `repo` para push.
- Opcional: `gh` CLI para crear el repo destino desde terminal.

!!! warning
    `git push --mirror` sobrescribe refs del remoto destino. Úsalo solo hacia un repo nuevo/vacío o cuando estés seguro de querer reemplazarlo por completo.

## Pasos (SSH) — Opción rápida

Este flujo parte de un repo público origen y un repo vacío destino. Define primero las variables y luego ejecuta los comandos.

```bash
# Variables
ORG_SOURCE="source-org"
ORG_DEST="dest-org"
REPO_NAME="my-repo"

git clone git@github.com:$ORG_SOURCE/$REPO_NAME
cd $REPO_NAME
git remote rename origin source
git remote add origin git@github.com:$ORG_DEST/$REPO_NAME
git push --mirror origin
git remote remove source
```

## Pasos (HTTPS) — Alternativa con PAT

```bash
# Variables
ORG_SOURCE="source-org"
ORG_DEST="dest-org"
REPO_NAME="my-repo"

git clone https://github.com/$ORG_SOURCE/$REPO_NAME.git
cd $REPO_NAME
git remote rename origin source
git remote add origin https://github.com/$ORG_DEST/$REPO_NAME.git
git push --mirror origin
git remote remove source
```

Al hacer push, Git solicitará usuario/token del PAT con permisos `repo`.

## Opción recomendada (mirror real) — Bare clone

Para evitar empujar refs de seguimiento remotas innecesarias, puedes usar un espejo bare. Es el patrón que recomienda GitHub para duplicar repos.

```bash
# Variables
ORG_SOURCE="source-org"
ORG_DEST="dest-org"
REPO_NAME="my-repo"

# 1) Crear un mirror local (bare)
git clone --mirror git@github.com:$ORG_SOURCE/$REPO_NAME

cd $REPO_NAME.git

# 2) Añadir el remoto destino (repo vacío)
git remote add mirror git@github.com:$ORG_DEST/$REPO_NAME

# 3) Empujar todas las refs (branches, tags, notes)
git push --mirror mirror
```

## Crear el repo destino (rápido con gh CLI)

Si aún no existe el repo en la organización destino:

```bash
# Autentícate si es necesario
gh auth login

# Variables
ORG_DEST="dest-org"
REPO_NAME="my-repo"

# Crea el repo vacío en la organización de destino
gh repo create "$ORG_DEST/$REPO_NAME" --private --confirm
```

## Validaciones rápidas

- Verifica ramas y tags en el remoto destino:

```bash
git ls-remote --heads origin
git ls-remote --tags origin
```

- Abre el repo destino en GitHub y comprueba default branch, tags y commits.

## Qué NO migra con este método

- Issues, PRs, Discussions, Projects, Releases, Wikis y Secrets.
- Para migrarlos, usa herramientas específicas (GitHub API/gh extensions) o realiza export/import manual según el caso.

## Limpieza y siguientes pasos

- Configura reglas de protección de rama en el repo destino.
- Revisa y recrea Secrets, variables de entorno y Webhooks.
- Actualiza pipelines (CI/CD) y badges que apunten al repo nuevo.
- Considera archivar el repo origen si ya no se pretende usar.

## Buenas prácticas

- Usa SSH para entornos corporativos; HTTPS+PAT para automatizaciones.
- Documenta la operación (fecha, responsables, commit de verificación).
- Repite el proceso en un repo de prueba antes de hacerlo en producción.
- Si el repo usa Git LFS, verifica que los objetos LFS estén correctamente en el destino.

## Referencias

- Duplicar un repositorio: https://docs.github.com/en/repositories/creating-and-managing-repositories/duplicating-a-repository
- Transferir un repositorio: https://docs.github.com/en/repositories/creating-and-managing-repositories/transferring-a-repository
- Autenticación SSH en GitHub: https://docs.github.com/en/authentication/connecting-to-github-with-ssh
- gh CLI (`gh repo create`): https://cli.github.com/manual/gh_repo_create

