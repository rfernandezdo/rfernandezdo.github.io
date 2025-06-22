---
draft: false
date: 2025-06-16
authors:
  - rfernandezdo
categories:
  - Azure
tags:
  - draw.io
---
# **Os presento `inventariographdrawio`: De vuestro Azure a un Diagrama, Automáticamente**

¡Hola a todos\! Como muchos profesionales que trabajáis día a día con la nube, seguro que os habéis enfrentado al mismo reto que yo una y otra vez: mantener una documentación visual de la infraestructura que sea fiel a la realidad. Dibujar diagramas a mano es tedioso y, peor aún, quedan obsoletos casi al instante.

Cansado de esta tarea manual y de la eterna duda de si un diagrama reflejaba o no el estado real de los recursos, decidí que tenía que haber una forma mejor de hacerlo.

Por eso, hoy quiero presentaros con mucha ilusión un proyecto personal en el que he estado trabajando: **[inventariographdrawio](https://github.com/rfernandezdo/inventariographdrawio)**.

## **¿Qué es `inventariographdrawio`?**

Es una herramienta de línea de comandos que he creado para solucionar este problema de raíz. Se conecta a una suscripción de **Microsoft Azure**, analiza los recursos que tienes desplegados y genera automáticamente un diagrama limpio y organizado en formato **Draw.io** (diagrams.net).

En pocas palabras, es mi solución para pasar de la infraestructura real en Azure a un diagrama editable, sin esfuerzo y en segundos.

#### **¿Por qué lo creé? (Mis Objetivos Principales)**

Cuando empecé a desarrollar esta herramienta, tenía varios objetivos en mente:

1.  **Ahorrar tiempo:** Mi primer objetivo era eliminar las horas que todos perdemos en tareas de documentación repetitivas. Quería que el análisis y el dibujo lo hiciera una máquina, para poder dedicar mi tiempo a lo que de verdad importa: diseñar y mejorar la arquitectura.
2.  **Tener una fuente de la verdad:** Necesitaba un diagrama en el que pudiera confiar. Con `inventariographdrawio`, el resultado es un reflejo exacto de lo que hay desplegado, perfecto para auditorías, revisiones o para explicarle la arquitectura a un nuevo compañero.
3.  **Mejorar la visibilidad:** A veces, en el portal de Azure es difícil ver el "big picture". Representar los recursos de forma gráfica me ayuda a entender las dependencias y la estructura general de un solo vistazo.
4.  **Enfocarme en Azure:** Decidí centrarme exclusivamente en Azure para poder ofrecer un buen nivel de detalle y precisión en los recursos y servicios específicos de la plataforma, que es donde trabajo principalmente.

## **¿Cómo podéis empezar a usarlo?**

He intentado que sea lo más sencillo posible. Solo tenéis que seguir estos pasos:

1.  **Clonar el repositorio:**

    ```bash
    git clone https://github.com/rfernandezdo/inventariographdrawio.git
    cd inventariographdrawio
    ```

2.  **Instalar las dependencias:**
    La herramienta tiene unas pocas dependencias que podéis instalar fácilmente (revisad el fichero `README.md` para las instrucciones exactas).

3.  **Configurar el acceso a Azure:**
    Aseguraos de tener vuestra sesión de Azure activa (por ejemplo, con `az login` desde Azure CLI) para que la herramienta pueda autenticarse y leer los recursos.

4.  **Ejecutar y ¡listo\!**
    Lanzad el script y veréis cómo aparece un nuevo fichero `.drawio` en la carpeta del proyecto, listo para abrir y editar.

Aquí un ejemplo navegable de un diagrama de Azure con iconos, creado con [draw.io](https://draw.io) y exportado como un enlace para visualizarlo directamente en el navegador, es navegable:

[Microsoft Entra Domain Services con Replica Set en una vpn Vnet2Vnet](https://viewer.diagrams.net/?p=ex&?tags=%7B%7D&lightbox=1&highlight=0000ff&layers=1&nav=1&title=azure_full_hierarchy_with_icons.drawio&dark=auto#R%3Cmxfile%3E%3Cdiagram%20id%3D%22main-diagram%22%20name%3D%22Azure%20Infrastructure%22%3E7V1tb%2BM2Ev41%2BzGC%2BE5%2B7O52ewXaQ3EL3H0MZFt21NpWICvJpr%2F%2BaFuKLVLURInoMEyzQNamNY6keTSceWY4%2FES%2BbH78UmW3N7%2BXi3z9CaeLH5%2FI108YU5oy%2Fd9%2B5PE4gpCSx5FVVSyasdPA9%2BLvvBlMm9G7YpHvOgfWZbmui9vu4LzcbvN53RnLqqp86B62LNfdv3qbrXJr4Ps8W9uj%2FysW9c1xFBOiTh%2F8Ky9WN%2B2f5oweP9lk7dHNpexuskX5cDZEfv5EvlRlWR9fbX58ydf729femKPcN8enT2dW5du6R6Cc%2Fbm%2FIThdZzOtlcMBnzBf62M%2Fz%2FSL1f7F4vE%2Bv6pWV1m2WOyuFvmmbA%2FR3%2FN0VHPfH2%2Bbm7Ip5lW5K5d1UuW78q6aaw3hb7u72W5eFbd1UW7379vPVlV5p7V1%2BI725LcaKVenm%2FB0cbv6sb3zxeagms%2FZ7vao2GXxI9fin2%2Fqzf5ykH55Wxbb%2BqBh9vkT%2B7o%2Fel2stnpgrm9KXumBZbmtG1gh%2Fdc%2BN1%2F7tdis9DmuC32R37K%2F76p8f%2BdW%2BTavMn0i3%2F7TnPz1L4ezT3b3K%2Ft%2BNyq4z6s6%2F3E21FzTL3m5yevqUR%2FSfpoicpRpngeZNmh5OIFLNni5OYNVO5Y1cF49ffVJ4fpFcx%2Fbtw0ERsIhWyxfjActpw9clJus2O7y6r44QMPSPApO89rKbOui1jf028%2Fbusquvx6u4fp7cxFTAUAhFZzCF7u%2Frh6K7f0GXZW7cfqel5vbuzrf67zY%2FdWnahycqk%2Fn%2FHV%2FzpNpNmDFYg%2BKJR9EsZymwSn2ftM8sC9V6n1R1XfZepPNb4ptr4mmAav3v8ezv%2F79ePoTKZpIlEjBOvMzTlGwysf%2BlM8%2BnPKFlAnH70D5q4erJtbRbvbV%2FTav0VVdHl6MBISWeCirvw43t%2F3CPjDw4MDQnHmx3X%2F25XTyU03lCNOEhaT6ozvOlgvEST4TizmibDabZTOylCnBSzSnKeZX69lLEbAus8UsW2fbeV71YUCEjYHf9Olff27PfyIYUKRCRAHPab5ckuWMZ4yqNJfLbDbHfDFfLMQs5wuPKJAfEAWSBYkCIWZKZIIvsnxBZwuVZYpLxZbzlOQso4urbTF%2FKQyebqpWyDLrj%2BBV2FD49%2FHN9a9P1zARHDCiMkQ8KIznqUILRPic4pm2CoLOZ3QusrmQSKa%2B8YDCI%2FMuAwhEFAsREMtcZct8oYikc0oxVrM0Q7NsucxyMcvm0jsgwuP4LgQIrgLzHg%2BBg1Z3S%2FKlXvUeHuF3Gb0LknTDR56ScFGAPaMgPHbwMijgKXoPMNi1Kb8qH8khWjjY5fO7qqgfnWk%2BFB6V2IuF782FTJzyY0q9E0Tcb0YmCV6AhfCYxUtiQTAeNhaeSTTdFrcvRcrt3WxdzItb%2FYeqfLfrnz0Cpxz%2FOFzD9a9%2FXP%2FUXsVU4aXC7wEgIAflGyCB85H%2BACKpChkeh7lEK%2F%2Fqfrt6uNYvXuxdPAsGgROS%2FmCAkErDNhQWErBXJATOR3pEAiHsHSBhn7fcPK6yOn%2FIHl%2BKhCZx3Qw0X9ZbdBQ4G9nmsFt385fmUqbCBKZdRGinLTxE6DtyDEKngUMvDgInIQ0cTKZ%2Fimnw%2Bq9WV1W%2BKev80mXHODyG0nvdMU3NwDPEyuOe4hbcFre82JEcLm7BgROV01e3YIrTEPMTZ5Tki13F59JQ%2BENTkno6EO%2FAZbwQJYk%2FNCWJGafvAAttIIm9cwr443KPqF10916A4JVSwB%2BWY0SKyeCB0CEUXgyE5zMKgVONvhkFpswAIsSY8sApHKNKj6RC4FyjL1JBSLO0ITAINJj%2FfjfT92My%2Fe8JBv2udwlc4DTj8U5MxiHw8GeF3fSk4pD%2BA6cXJ9a%2FFB39h7g86qD%2FVwSNo7QfHo%2FoUftIdBPPggS1LPbytj9w4nBS7Wt1839sf1f%2FgVOI0z79nOJ%2FbP%2B59gMnDad9%2BnmKE%2FxW6SOr8VG%2BWDW9gzr3fD%2F8vXlbVvVNuSq32frn0%2BjnqrzbLvZq%2BJrqd6djfivL20Ypf%2BZ1%2Fdjc8uyuLrsqy7eLn%2FY9pfY6Wme7XTHXg9vy7G8cDjt9czPg1MEx13eGq%2Bam1lm1yuuz8eZy99c4qLEqX2d1cZ93%2FkrfvT%2BI6ovZF2M8HdBA8vTNf%2BwHTkAgClsdEsixvPvUpsqU6XKKhOExhzNGPB4u2PC5o1QDn2LJBGp%2Bd8VVp%2BGWfnG8oSdQP2mmD%2Bf9wG6RERmw295tYQIbKdb1btGxUN2NDJ6aaRPE0FgR6GFAjJqUywtEoIcCqVS8TgB8jlBKktNDhFWXSPDyHOFInyMe9INEiFm%2FLpozdttYRBJ%2B%2FtMVl3x6bJA4sYGFAxsYBwEOpMwHH8IGUTJJT3bDIKCEwtNjg0aKDdcE3Ex0b44NKniCznyt7oyEgblVWOkpptD04GCRgiN1gIOEMasggkVCjMCDQS4alSgh5z%2F%2B8cEjxYd0TSw8DHxwbDm9xyViTnRoRzn1jwcRJx6Yy1wEgQaZcoulQFINwoHLLhqM%2BG8aNMg40eCKSFqr8dbGAZM0kc55ACEg2CXSXL8PRvq2CBi2c6tAn%2FiIilWcEHQFPiiM%2BYlo79TgzyHYMSPhBmHOPB4C3GuPB5lWiwjwMsGiSPMAbo8rkFCes9EeF6ZoFIQsAZBmpNrSkxPP2DX0QkoP%2BIuUrnd5eGHEg0Ipq1kzlIeSLDVtMGTzekQgzDKjcnrs8XBGSkOcYSJTdfxtsqU%2BMlI4Tow7WY92i463trFYwxyZAASsLCLCbAfgZ%2BKNlUN3TbwkjOAWcasKGyLCtCFTHSLsEvCIlUZ3Uh9h0OjYTjILJIfhwZEl4iOxgiIlz1vDYLvqYUwj2jMyQjeAC0NC4kSdVb0YxLkPagxFypy7sm4EBYENpHA3xALZMMbYQFLFoFknwkakLHprH2zDQcMAh0xlwp0pWSjc36ffpNvr8IKUSBl2V1VoG5m9MVAotjfOIkBpB0M4MUUgCtIWgcJr7fia8ZMXbzdSWt3l2YTBAnHaLceF5i7BUiuchmj1PhkIp1PJgNwRHsk14bFcE6aJSqng6PAbd6WlhxgBR0rnO93AQGZ6pbqTO%2BgGcp6attiL7%2Fd0RyMDBHEhAgWCCKqYbcQAih0Ri5sC8962CFh9zlN9amf1woZf6mOCxzhSGLo8y1BCEN43l0IwFMSqpYBgaIuA2UmKSAeGF%2FAzcayku7OEKIwAxyoWBAvXKaIJPitnvsSCl0gpd%2BSaKsOIQhAXtisEuU%2BUjq4ps0VAo4aUuSXVC0TA6RiZ%2FPBYATgO4fphOqW8jaV6QnhYIYQjTVY4l4EE8jBR3o3pGYJyFXhcXZolAKNP4XPG2yAdvKxPw5FmQ1x8Uhi5U2HkyaA1wPvyIHNRip8gONIEiCuX3s4Pb72OAMueKrNhx09KNrrKzBaBjBhH4iK8No40n4JdhgiHMQ1iouhAbAm6l2L8kgVbBKZudABsYt1LYBNpdqXN3lkoDIR7IcJKt6lhFDE8OkPXIwIBj%2Bp5F0g3TgM8Emk2wm3%2BAqFbGOYDpQOQ%2BcOCjjN%2BlgCEwNcLgOziqwXgxRJ6jnFXeXkpAWyzHrE9UMRVSd5KvLUpZ6mRKoZKACkW5w17pFn746EEkOA4weGc5tsLfmtw2PM8SG8jKQdScH5sR6S5D%2BKKgnEYrAjmZHBm6BHAciB4McrRJwJHrLkP18QSRpyKCFfjcx9ofO7DEoETGXx87sMSAcnkVI7MfZgCMPvMZNLUX%2B1%2FN0VXp9xHR3yihynW3Ier3jqUKiyhupktg03pST0qDDGUE0Ei0oSEMx0Wim9GtaN13n%2B2%2B%2FiD2TEpDAHIPpkCoH3C2nuk6vRjFDr4WHNPIk2HuNeDBAJG2dNlaxiAmLW29bk0hikA0xgcuxep%2BMFfpFkRdyQSyEJGu%2BeIAGZIq68XBCdLALaYVAxUehkPyEQAjDUh4uKlA5mNdSg7minBaTqM2WkgQWNNVTjnxDDYESQJdbccgtrW9qzW95LHb%2FsoxYYO5JqxAjEYPW2JoW4MSP8b6FboxaFpo4ro4IEd8AiDPbMXp8K98lOZnBbkIXUBbERKuyNXy8hAsCHVSGRoN%2FSsRBobcZAPnrCthI0OGq5FUWFAA3FisuEwOiRPzrK5Zr5O%2BkBHpCyyczlKKC1dhJJjm80i014gKTwg4sORyIEgglK7xg5KLTAiLpNaoJGyuc6VtUFggqY9vTCAoiBMuj6Jlx75NFJy1cVjhOFTYMzo6ES%2BYOOrzC0RuHISvVIArpx8rcAztr9TySmHL0wO0cs2VpFyxGGH9Djt0jXOZwh6YCCwP%2FNzJ5Sf%2BTmEbKV4chZ0GhOEF2CzSJluZ%2FIjDGT3LDmDo07S3dLNoDKFB7qKfTSmOwx0ICEGWWsQKUokJytiFrn54DUbwxkfUFz9ywMByn4zprFmRLDkjPM2F6r42PKARcp6O6mKYNqOMZRIZzoV2vuACzJghby0nGWRkuDuNYJh7OqGKTcNCbhnuxxfeW6LwDu58Yvs5MZi5dfDbhLSUwMErYqWanSDhx4ReLOiCxG2LFYa34G7MGZGbLFzw8aOUmLBwUtzGhYpf09ceAhlw3RtRYaW2UmgzkjidGgJp49VeixSbh8HvkoPU3uZELh7uuV8g239zP0W4bZ%2BquPrG33ZvNBDkbLiznWioaSgWYpGFyVQJRPutFBeJjMeKbkcNikkCR%2BbfFRU2r33gGCuTwbyqqeSgaynGBkgmMfDxpai5MShpYa0jxaqPFIq3tm6P5hmL0yO3o4H0Z7GhT5oi3YXkdhQ4fQBURh8GcLC7poGEqo2W%2B9lfQr%2FaHQ7CWPi1U63Oq8LthYvAjECI3TAQ%2FPCt7f9oaODirM5RRjNcJFQLBEDnQiAPYjJPgZ175bhBSqRMuTY5c23RdxvDRU9R4zcohqZjSP8TDOxMtdO2xEIVSl5mqQD3QSBumOuxq3JtwTgVf%2FCEPDi%2BkbKlDs37wnEyUHcXGQNZooxtsuhoVRxjwyYK8bMYj78RF2RMu9hL%2BLs6W0N8Vpcg8iM0iDk9clAyJtKBjLF1JzXRx4P81pIDTTI8rKykceaRHAtWQoliWAvfIVKLxCxXVEoj2WLgGacIW6zxMgD9ESk%2BQmXCxGGHUepGmp3DCayEDEbi4LOhC0Cty%2BdQgRuYMpGpoVNgWd0PCVJevZjpio61zTRYxVrqsK5CDWMjm5IIDI%2BVSGNLdi8eMxtH8zYIOGkCgIpc9Nh1OhCAZFaGxF5qQ4QsaYpnI0fcRigYDId2A8G3oxXyAHq2gvXIyJNUyCX%2FQjEU9Ne%2BPjeOChxL2GVPtyNWBMTzgAykMmFUjE2gBR07MbwPSLwmhGBLhRAxpoCcXq6gUxhNvTgacvCkZfNhkWkaQlnAX8odVqYqo5XY6gaqt83V0lDcbUpANoxlqYJdW4Q56WztYg0T%2BHK2KMwMvaKjw%2B6UkUtGYjV6pEBp8aJZMAVd0bDzVcWIOi3VVnW54dX2e3N71rp%2ByP%2BDw%3D%3D%3C%2Fdiagram%3E%3C%2Fmxfile%3E#%7B%22pageId%22%3A%22main-diagram%22%7D)

## **El futuro**

Este es solo el comienzo del proyecto. Mi idea es seguir ampliándolo para que sea compatible con más servicios de Azure y añadir nuevas funcionalidades que lo hagan aún más útil.

Al ser un proyecto de código abierto, cualquier ayuda es bienvenida. Si os animáis, podéis abrir *issues* con sugerencias o incluso enviar vuestros propios *pull requests*.

Espero de corazón que esta herramienta os resulte útil y os ahorre tanto tiempo como a mí. 

¡Gracias por leer\!

