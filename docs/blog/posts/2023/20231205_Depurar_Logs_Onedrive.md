---
date: 2023-12-05
authors:
  - rfernandezdo
categories:
  - Microsoft 365
tags:
  - OneDrive for Business
  
---
# Depurar logs de OneDrive para detectar problemas de sincronización

!!! info "Necesitas WSL2"
    Para poder seguir este tutorial necesitas tener instalado WSL2 en tu equipo, si no lo tienes, puedes seguir este tutorial [Instalar WSL2 en Windows 11 con chocolatey]


[Instalar WSL2 en Windows 11 con chocolatey]: 20231204_Instalar_WSL2.md

## Introducción

Llevo unos días con sync pending en algunos ficheros en mi OneDrive for Business sin ninguna razón aparente, por lo que he decidido investigar un poco y compartir como he resuelto el problema.

Lo primero es seguir la siguiente documentación de Microsoft que puede ser útil para alguien que tenga problemas de sincronización con OneDrive:

[Fix OneDrive sync problems](https://support.microsoft.com/en-au/office/fix-onedrive-sync-problems-0899b115-05f7-45ec-95b2-e4cc8c4670b2)

Pero si no funciona, se puede obtener más información de los logs de OneDrive.

## Pasos a seguir

### 1. Acceder a los logs de OneDrive

Para acceder a los logs de OneDrive, se debe seguir los siguientes pasos:

1. Abrir el Explorador de archivos.
2. Hacer clic en la flecha hacia arriba en la barra de direcciones.
3. Pegar la siguiente ruta en la barra de direcciones y presionar Enter:

=== "Business"

    ``` Business
    %localappdata%\Microsoft\OneDrive\logs\Business1
    ```
=== "Personal"

    ``` Personal
    %localappdata%\Microsoft\OneDrive\logs\Personal
    ```

Ahora es necesario seleccionar los archivos de log más recientes y copiarlos a un directorio, los archivos pueden tener extensión .odl,.odlgz, .odlsent  o .aold, también se debe incluir el fichero ObfuscationStringMap.txt o general.keystore.


### 2. Instalar el visor de logs de OneDrive

Para instalar el visor de logs de OneDrive, se debe seguir los siguientes pasos:

Descarga https://raw.githubusercontent.com/ydkhatri/OneDrive/main/odl.py y ejecuta el siguiente comando:

``` bash
pip3 install pycryptodome
pip3 install construct
python odl.py -o <ruta de salida>/fichero.csv <ruta de los logs>
```

Por ejemplo:

``` bash
python3 odl.py -o output/fichero.csv input/
WARNING: Multiple instances of some keys were found in the ObfuscationMap.
Read 40493 items from map
Recovered Unobfuscation key Churreradenumneros, version=1, utf_type=utf16
Searching  /mnt/c/Users/userdemo/Escritorio/input/SyncEngine-2023-09-04.0637.32.2.odl
Wrote 821 rows
Searching  /mnt/c/Users/userdemo/Escritorio/input/FileCoAuth-2023-09-03.0804.13536.1.odlgz
Wrote 203 rows
Searching  /mnt/c/Users/userdemo/Escritorio/input/FileCoAuth-2023-09-03.0804.14112.1.odlgz
.......
............
...............
Wrote 872 rows
Finished processing files, output is at output/fichero.csv
userdemo@DESKTOP:/mnt/c/Users/userdemo/Escritorio$
```

### 3. Analizar los logs

Una vez que se ha generado el fichero CSV, se puede abrir con Excel o cualquier editor de texto para analizar los logs y detectar problemas de sincronización, busca error o warn para averiguar que puede estar provocando el problema.


### Solución

En mi caso, tras poder leer los logs de OneDrive, he descubierto que OneDrive no podía escribir varios ficheros en disco, luego recordé que el otro día mi equipo no se apagó bien.

Tras un chkdsk c: /F /R,  fin de la historia, ahora todo funciona, espero que le resulte útil a alguien.

## Referencias
-  https://github.com/ydkhatri/OneDrive/tree/main

