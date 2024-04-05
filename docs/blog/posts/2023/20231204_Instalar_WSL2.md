---
date: 2023-12-04
authors:
  - rfernandezdo
categories:
  - Windows
tags:
  - Windows Subsystem for Linux 2
  
---
# Instalar WSL2 en Windows 11 con chocolatey

## Introducción

Windows Subsystem for Linux (WSL) es una característica de Windows 11 que permite ejecutar un entorno de Linux en Windows. WSL2 es la segunda versión de WSL que ofrece un kernel de Linux completo y un mejor rendimiento en comparación con WSL1. Este análisis proporciona una guía paso a paso para instalar WSL2 en Windows 11.

## Pasos a seguir

### 1. Instalar Chocolatey

Chocolatey es un administrador de paquetes para Windows que facilita la instalación y gestión de software. Para instalar Chocolatey, siga los siguientes pasos:

1. Abra PowerShell como administrador.

2. Ejecute el siguiente comando para instalar Chocolatey:

```pwsh
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
```

3. Espere a que se complete la instalación de Chocolatey.

### 2. Instalar WSL2

Para instalar WSL2 en Windows 11, siga los siguientes pasos:

1. Abra PowerShell como administrador.

2. Ejecute el siguiente comando para instalar WSL2:

```pwsh
choco install wsl2
```
3. Espere a que se complete la instalación de WSL2.

### 3. Configurar WSL2

Para configurar WSL2 en Windows 11, siga los siguientes pasos:

1. Abra PowerShell como administrador.

2. Ejecute el siguiente comando para configurar WSL2 como la versión predeterminada:

```pwsh
wsl --set-default-version 2
```

3. Reinicie su computadora para aplicar los cambios.

### 4. Instalar una distribución de Linux

Para instalar una distribución de Linux en WSL2, siga los siguientes pasos:

1. Abra PowerShell.

2. Busque la distribución de Linux que desea instalar (por ejemplo, Ubuntu, Debian, Fedora)

```pwsh
wsl --list --online
```

3. Ejecute el siguiente comando para instalar la distribución de Linux seleccionada:

```pwsh
wsl --install -d <nombre de la distribución>
```

4. Espere a que se complete la instalación de la distribución de Linux.


### 5. Iniciar WSL2

Para iniciar WSL2 en Windows 11, siga los siguientes pasos:

1. Abra PowerShell.

2. Ejecute el siguiente comando para iniciar la distribución de Linux instalada:

```pwsh
wsl
```




## Referencias

-  [Chocolatey](https://chocolatey.org/)
-  [What is the Windows Subsystem for Linux?](https://learn.microsoft.com/en-us/windows/wsl/about)

