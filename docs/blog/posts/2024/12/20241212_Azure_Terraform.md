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

En ocasiones, cuando trabajamos con Terraform, necesitamos gestionar múltiples archivos de variables para diferentes entornos o configuraciones. En este post, os muestro cómo ejecutar Terraform con archivos de variables de forma sencilla.

## Terraform y archivos de variables

Terraform permite cargar variables desde archivos `.tfvars` mediante la opción `--var-file`. Por ejemplo, si tenemos un archivo `variables.tf` con la siguiente definición:

```hcl
variable "region" {
  type    = string
  default = "westeurope"
}

variable "resource_group_name" {
  type = string
}
```

Podemos crear un archivo `variables.tfvars` con los valores de las variables:

```hcl
region = "westeurope"
resource_group_name = "my-rg"
```

Y ejecutar Terraform con el archivo de variables:

```bash
terraform plan --var-file variables.tfvars
```

## Ejecutar Terraform con múltiples archivos de variables

Si tenemos múltiples archivos de variables, podemos ejecutar Terraform con todos ellos de forma sencilla. Para ello, podemos crear un script que busque los archivos `.tfvars` en un directorio y ejecute Terraform con ellos.

El problema de ejecutar Terraform con múltiples archivos de variables es que la opción `--var-file` no admite un array de archivos. Por lo tanto, necesitamos construir el comando de Terraform con todos los archivos de variables, lo cual puede ser un poco tedioso.

A continuación, os muestro un ejemplo de cómo crear una función en Bash/pwsh que ejecuta Terraform con archivos de variables:


!!! example

    === "bash"

        ```bash title="terraform_with_var_files.sh"
          function terraform_with_var_files() {
          if [[ "$1" == "--help" || "$1" == "-h" ]]; then
            echo "Usage: terraform_with_var_files [OPTIONS]"
            echo "Options:"
            echo "  --dir DIR                Specify the directory containing .tfvars files"
            echo "  --action ACTION          Specify the Terraform action (plan, apply, destroy, import)"
            echo "  --auto AUTO              Specify 'auto' for auto-approve (optional)"
            echo "  --resource_address ADDR  Specify the resource address for import action (optional)"
            echo "  --resource_id ID         Specify the resource ID for import action (optional)"
            echo "  --workspace WORKSPACE    Specify the Terraform workspace (default: default)"
            echo "  --help, -h               Show this help message"
            return 0
          fi

          local dir=""
          local action=""
          local auto=""
          local resource_address=""
          local resource_id=""
          local workspace="default"

          while [[ "$#" -gt 0 ]]; do
            case "$1" in
              --dir) dir="$2"; shift ;;
              --action) action="$2"; shift ;;
              --auto) auto="$2"; shift ;;
              --resource_address) resource_address="$2"; shift ;;
              --resource_id) resource_id="$2"; shift ;;
              --workspace) workspace="$2"; shift ;;
              *) echo "Unknown parameter passed: $1"; return 1 ;;
            esac
            shift
          done

          if [[ ! -d "$dir" ]]; then
            echo "El directorio especificado no existe."
            return 1
          fi

          if [[ "$action" != "plan" && "$action" != "apply" && "$action" != "destroy" && "$action" != "import" ]]; then
            echo "Acción no válida. Usa 'plan', 'apply', 'destroy' o 'import'."
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

          echo "Inicializando Terraform..."
          eval terraform init
          if [[ $? -ne 0 ]]; then
            echo "La inicialización de Terraform falló."
            return 1
          fi

          echo "Seleccionando el workspace: $workspace"
          eval terraform workspace select "$workspace" || eval terraform workspace new "$workspace"
          if [[ $? -ne 0 ]]; then
            echo "La selección del workspace falló."
            return 1
          fi

          echo "Validando la configuración de Terraform..."
          eval terraform validate
          if [[ $? -ne 0 ]]; then
            echo "La validación de Terraform falló."
            return 1
          fi

          local command="terraform $action ${var_files[@]}"

          if [[ "$action" == "import" ]]; then
            if [[ -z "$resource_address" || -z "$resource_id" ]]; then
              echo "Para la acción 'import', se deben proporcionar la dirección del recurso y el ID del recurso."
              return 1
            fi
            command="terraform $action ${var_files[@]} $resource_address $resource_id"
          elif [[ "$auto" == "auto" && ( "$action" == "apply" || "$action" == "destroy" ) ]]; then
            command="$command -auto-approve"
          fi

          echo "Ejecutando: $command"
          eval "$command"
        }

        # Uso de la función
        # terraform_with_var_files --dir "/ruta/al/directorio" --action "plan" --workspace "workspace"
        # terraform_with_var_files --dir "/ruta/al/directorio" --action "apply" --auto "auto" --workspace "workspace"
        # terraform_with_var_files --dir "/ruta/al/directorio" --action "destroy" --auto "auto" --workspace "workspace"
        # terraform_with_var_files --dir "/ruta/al/directorio" --action "import" --resource_address "resource_address" --resource_id "resource_id" --workspace "workspace"
        ```

    === "pwsh"

        ```pwsh	title="terraform_with_var_files.ps1"
        function Terraform-WithVarFiles {
            param (
                [Parameter(Mandatory=$false)]
                [string]$Dir,

                [Parameter(Mandatory=$false)]
                [string]$Action,

                [Parameter(Mandatory=$false)]
                [string]$Auto,

                [Parameter(Mandatory=$false)]
                [string]$ResourceAddress,

                [Parameter(Mandatory=$false)]
                [string]$ResourceId,

                [Parameter(Mandatory=$false)]
                [string]$Workspace = "default",

                [switch]$Help
            )

            if ($Help) {
                Write-Output "Usage: Terraform-WithVarFiles [OPTIONS]"
                Write-Output "Options:"
                Write-Output "  -Dir DIR                Specify the directory containing .tfvars files"
                Write-Output "  -Action ACTION          Specify the Terraform action (plan, apply, destroy, import)"
                Write-Output "  -Auto AUTO              Specify 'auto' for auto-approve (optional)"
                Write-Output "  -ResourceAddress ADDR   Specify the resource address for import action (optional)"
                Write-Output "  -ResourceId ID          Specify the resource ID for import action (optional)"
                Write-Output "  -Workspace WORKSPACE    Specify the Terraform workspace (default: default)"
                Write-Output "  -Help                   Show this help message"
                return
            }

            if (-not (Test-Path -Path $Dir -PathType Container)) {
                Write-Error "The specified directory does not exist."
                return
            }

            if ($Action -notin @("plan", "apply", "destroy", "import")) {
                Write-Error "Invalid action. Use 'plan', 'apply', 'destroy', or 'import'."
                return
            }

            $varFiles = Get-ChildItem -Path $Dir -Filter *.tfvars | ForEach-Object { "--var-file $_.FullName" }

            if ($varFiles.Count -eq 0) {
                Write-Error "No .tfvars files found in the specified directory."
                return
            }

            Write-Output "Initializing Terraform..."
            terraform init
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Terraform initialization failed."
                return
            }

            Write-Output "Selecting the workspace: $Workspace"
            terraform workspace select -or-create $Workspace
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Workspace selection failed."
                return
            }

            Write-Output "Validating Terraform configuration..."
            terraform validate
            if ($LASTEXITCODE -ne 0) {
                Write-Error "Terraform validation failed."
                return
            }

            $command = "terraform $Action $($varFiles -join ' ')"

            if ($Action -eq "import") {
                if (-not $ResourceAddress -or -not $ResourceId) {
                    Write-Error "For 'import' action, both resource address and resource ID must be provided."
                    return
                }
                $command = "$command $ResourceAddress $ResourceId"
            } elseif ($Auto -eq "auto" -and ($Action -eq "apply" -or $Action -eq "destroy")) {
                $command = "$command -auto-approve"
            }

            Write-Output "Executing: $command"
            Invoke-Expression $command
        }

        # Usage examples:
        # Terraform-WithVarFiles -Dir "/path/to/directory" -Action "plan" -Workspace "workspace"
        # Terraform-WithVarFiles -Dir "/path/to/directory" -Action "apply" -Auto "auto" -Workspace "workspace"
        # Terraform-WithVarFiles -Dir "/path/to/directory" -Action "destroy" -Auto "auto" -Workspace "workspace"
        # Terraform-WithVarFiles -Dir "/path/to/directory" -Action "import" -ResourceAddress "resource_address" -ResourceId "resource_id" -Workspace "workspace"
        ```

Para cargar la función en tu terminal bash, copia y pega el script en tu archivo `.bashrc`, `.zshrc` o el que toque y recarga tu terminal.

Para cargar la función en tu terminal pwsh, sigue este artículo: [Personalización del entorno de shell](https://learn.microsoft.com/es-es/powershell/scripting/learn/shell/creating-profiles?view=powershell-7.4#adding-customizations-to-your-profile)


Espero que os sea de utilidad. ¡Saludos!

 