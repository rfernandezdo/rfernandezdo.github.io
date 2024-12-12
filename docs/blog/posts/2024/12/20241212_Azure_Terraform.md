---
draft: false
date: 2024-12-12
authors:
  - rfernandezdo
categories:
    - HashiCorp
tags:
    - Terraform
---
# Ejecutar Terraform con archivos de variables

Script para ejecutar Terraform con archivos de variables:

 ```bash
    function terraform_with_var_files() {
    local dir="$1"
    local action="$2"
    local auto="$3"

    if [[ ! -d "$dir" ]]; then
        echo "El directorio especificado no existe."
        return 1
    fi

    if [[ "$action" != "plan" && "$action" != "apply" && "$action" != "destroy" ]]; then
        echo "Acción no válida. Usa 'plan', 'apply' o 'destroy'."
        return 1
    fi

    local var_files=()
    for file in "$dir"/*.tfvars; do
        if [[ -f "$file" ]]; then
        var_files+=("--var-file $file")
        fi
    done

    if [[ ${#var_files[@]} -eq 0 ]]; then
        echo "No se encontraron archivos .tfvars en el directorio especificado."
        return 1
    fi

    local command="terraform $action ${var_files[@]}"
    
    if [[ "$auto" == "auto" && ( "$action" == "apply" || "$action" == "destroy" ) ]]; then
        command="$command -auto-approve"
    fi

    echo "Ejecutando: $command"
    eval "$command"
    }

    # Uso de la función
    # terraform_with_var_files "/ruta/al/directorio" "plan"
    # terraform_with_var_files "/ruta/al/directorio" "apply" "auto"
    # terraform_with_var_files "/ruta/al/directorio" "destroy" "auto"
```

Para cargar la función en tu terminal, copia y pega el script en tu archivo `.bashrc`, `.zshrc` o el que toque y recarga tu terminal.

Espero que os sea de utilidad. ¡Saludos!

 