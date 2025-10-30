#!/usr/bin/env python3
"""
Script de validación de posts para MkDocs Material Blog
Verifica formato, frontmatter y convenciones del blog rfernandezdo.github.io
"""

import sys
import re
from pathlib import Path
from datetime import datetime
import yaml


class PostValidator:
    """Validador de posts del blog"""

    REQUIRED_FRONTMATTER = ['draft', 'date', 'authors', 'categories', 'tags']
    VALID_AUTHOR = 'rfernandezdo'
    DATE_FORMAT = '%Y-%m-%d'
    FILENAME_PATTERN = r'^\d{8}_[a-z0-9_]+\.md$'

    def __init__(self, filepath: Path):
        self.filepath = filepath
        self.errors = []
        self.warnings = []
        self.content = None
        self.frontmatter = None

    def validate(self) -> bool:
        """Ejecuta todas las validaciones"""
        self._load_file()
        self._validate_filename()
        self._validate_frontmatter()
        self._validate_structure()
        self._validate_markdown()

        return len(self.errors) == 0

    def _load_file(self):
        """Carga el contenido del archivo"""
        try:
            with open(self.filepath, 'r', encoding='utf-8') as f:
                self.content = f.read()
        except Exception as e:
            self.errors.append(f"Error leyendo archivo: {e}")
            return

        # Extraer frontmatter
        fm_match = re.match(r'^---\n(.*?)\n---\n', self.content, re.DOTALL)
        if fm_match:
            try:
                self.frontmatter = yaml.safe_load(fm_match.group(1))
            except yaml.YAMLError as e:
                self.errors.append(f"Error parseando frontmatter YAML: {e}")
        else:
            self.errors.append("No se encontró frontmatter válido (debe empezar con ---)")

    def _validate_filename(self):
        """Valida el formato del nombre de archivo"""
        filename = self.filepath.name

        if not re.match(self.FILENAME_PATTERN, filename):
            self.errors.append(
                f"Nombre de archivo inválido: '{filename}'. "
                f"Debe seguir el patrón YYYYMMDD_descriptive_slug.md"
            )

        # Validar que la fecha del filename coincida con la del frontmatter
        if self.frontmatter and 'date' in self.frontmatter:
            date_from_filename = filename[:8]
            try:
                date_obj = datetime.strptime(str(self.frontmatter['date']), self.DATE_FORMAT)
                expected_date = date_obj.strftime('%Y%m%d')
                if date_from_filename != expected_date:
                    self.warnings.append(
                        f"Fecha en filename ({date_from_filename}) no coincide "
                        f"con frontmatter ({expected_date})"
                    )
            except ValueError:
                pass  # Ya se reportará en validate_frontmatter

    def _validate_frontmatter(self):
        """Valida el frontmatter obligatorio"""
        if not self.frontmatter:
            return  # Ya se reportó el error

        # Verificar campos obligatorios
        for field in self.REQUIRED_FRONTMATTER:
            if field not in self.frontmatter:
                self.errors.append(f"Campo obligatorio faltante en frontmatter: '{field}'")

        # Validar draft (debe ser booleano)
        if 'draft' in self.frontmatter:
            if not isinstance(self.frontmatter['draft'], bool):
                self.errors.append("Campo 'draft' debe ser true o false (sin comillas)")

        # Validar fecha (formato ISO 8601: YYYY-MM-DD)
        if 'date' in self.frontmatter:
            try:
                date_str = str(self.frontmatter['date'])
                datetime.strptime(date_str, self.DATE_FORMAT)
            except ValueError:
                self.errors.append(
                    f"Formato de fecha inválido: '{self.frontmatter['date']}'. "
                    f"Debe ser YYYY-MM-DD (ISO 8601)"
                )

        # Validar author
        if 'authors' in self.frontmatter:
            authors = self.frontmatter['authors']
            if not isinstance(authors, list):
                self.errors.append("Campo 'authors' debe ser una lista")
            elif self.VALID_AUTHOR not in authors:
                self.errors.append(
                    f"Author debe ser '{self.VALID_AUTHOR}' (case-sensitive)"
                )

        # Validar categories (debe ser lista)
        if 'categories' in self.frontmatter:
            if not isinstance(self.frontmatter['categories'], list):
                self.errors.append("Campo 'categories' debe ser una lista")
            elif len(self.frontmatter['categories']) == 0:
                self.warnings.append("No hay categorías definidas")

        # Validar tags (debe ser lista)
        if 'tags' in self.frontmatter:
            if not isinstance(self.frontmatter['tags'], list):
                self.errors.append("Campo 'tags' debe ser una lista")
            elif len(self.frontmatter['tags']) == 0:
                self.warnings.append("No hay tags definidos")

    def _validate_structure(self):
        """Valida la estructura del contenido"""
        if not self.content:
            return

        # Quitar frontmatter para analizar contenido
        content_body = re.sub(r'^---\n.*?\n---\n', '', self.content, flags=re.DOTALL)

        # Verificar que tenga al menos un H1
        if not re.search(r'^# .+', content_body, re.MULTILINE):
            self.warnings.append("No se encontró ningún título principal (# Título)")

        # Verificar sección de Resumen
        if not re.search(r'^## Resumen', content_body, re.MULTILINE):
            self.warnings.append("Falta sección '## Resumen' recomendada")

        # Verificar sección de Referencias
        if not re.search(r'^## Referencias', content_body, re.MULTILINE):
            self.warnings.append("Falta sección '## Referencias' recomendada")

    def _validate_markdown(self):
        """Valida sintaxis Markdown común"""
        if not self.content:
            return

        # Detectar bloques de código sin lenguaje especificado (solo aperturas)
        # Patrón: ``` seguido de salto de línea sin texto en la misma línea
        # Pero excluir cierres (líneas que empiezan con ``` y nada más)
        lines = self.content.split('\n')
        code_block_open = False
        blocks_without_lang = 0

        for line in lines:
            if line.startswith('```'):
                if not code_block_open:
                    # Es una apertura
                    if line.strip() == '```':
                        # Sin lenguaje especificado
                        blocks_without_lang += 1
                    code_block_open = True
                else:
                    # Es un cierre
                    code_block_open = False

        if blocks_without_lang > 0:
            self.warnings.append(
                f"Hay {blocks_without_lang} bloque(s) de código sin lenguaje especificado. "
                "Usa ```bash, ```python, etc."
            )

        # MD032: Listas deben tener línea en blanco antes y después
        self._validate_list_spacing()

        # Detectar marcas prohibidas (validado MCP, etc.)
        forbidden_marks = [
            'validado MCP', 'MCP validado', 'verificado con MCP',
            'validado Terraform MCP', 'validación MCP'
        ]
        for mark in forbidden_marks:
            if mark.lower() in self.content.lower():
                self.errors.append(
                    f"Marca prohibida detectada: '{mark}'. "
                    "La validación MCP es interna, no debe aparecer en el post."
                )

    def _validate_list_spacing(self):
        """Valida MD032: Lists should be surrounded by blank lines"""
        if not self.content:
            return

        lines = self.content.split('\n')
        in_code_block = False
        in_frontmatter = False
        issues = []

        for i, line in enumerate(lines, start=1):
            # Detectar frontmatter
            if line.strip() == '---':
                if i == 1:
                    in_frontmatter = True
                elif in_frontmatter:
                    in_frontmatter = False
                continue

            if in_frontmatter:
                continue

            # Detectar bloques de código
            if line.startswith('```'):
                in_code_block = not in_code_block
                continue

            if in_code_block:
                continue

            # Detectar inicio de lista (-, *, + o número.)
            is_list_item = bool(re.match(r'^(\s*)([-*+]|\d+\.)\s+', line))

            if is_list_item:
                # Verificar línea anterior (debe estar vacía o ser parte de lista/tabla)
                if i > 1:
                    prev_line = lines[i - 2]  # i-1 porque enumerate empieza en 1
                    prev_is_list = bool(re.match(r'^(\s*)([-*+]|\d+\.)\s+', prev_line))
                    prev_is_table = prev_line.strip().startswith('|')
                    prev_is_empty = prev_line.strip() == ''

                    # Casos válidos: línea anterior vacía, es otra lista, o es tabla
                    if not (prev_is_empty or prev_is_list or prev_is_table):
                        # Verificar si la línea anterior es bold/italic (ej: "**Título:**")
                        # En ese caso necesita línea en blanco
                        if prev_line.strip() and not prev_line.startswith('#'):
                            issues.append(
                                f"Línea {i}: Lista sin línea en blanco anterior. "
                                f"Agrega línea vacía antes de '{line.strip()[:50]}...'"
                            )

        if issues:
            self.errors.append(
                f"MD032 - Listas deben estar rodeadas de líneas en blanco:\n  " +
                "\n  ".join(issues[:5])  # Mostrar solo primeros 5
            )

    def print_results(self):
        """Imprime resultados de la validación"""
        print(f"\n{'='*70}")
        print(f"Validando: {self.filepath.name}")
        print(f"{'='*70}\n")

        if self.errors:
            print("❌ ERRORES CRÍTICOS:")
            for i, error in enumerate(self.errors, 1):
                print(f"  {i}. {error}")
            print()

        if self.warnings:
            print("⚠️  ADVERTENCIAS:")
            for i, warning in enumerate(self.warnings, 1):
                print(f"  {i}. {warning}")
            print()

        if not self.errors and not self.warnings:
            print("✅ Post válido - no se encontraron problemas\n")
        elif not self.errors:
            print("✅ Post válido - solo advertencias menores\n")
        else:
            print("❌ Post inválido - corrige los errores críticos\n")

        return len(self.errors) == 0


def main():
    """Función principal"""
    if len(sys.argv) < 2:
        print("Uso: python validate_post.py <ruta_al_post.md>")
        print("\nEjemplo:")
        print("  python validate_post.py docs/blog/posts/2025/10/20251026_mi_post.md")
        sys.exit(1)

    filepath = Path(sys.argv[1])

    if not filepath.exists():
        print(f"❌ Error: Archivo no encontrado: {filepath}")
        sys.exit(1)

    if not filepath.suffix == '.md':
        print("❌ Error: El archivo debe ser .md (Markdown)")
        sys.exit(1)

    validator = PostValidator(filepath)
    is_valid = validator.validate()
    validator.print_results()

    sys.exit(0 if is_valid else 1)


if __name__ == '__main__':
    main()
