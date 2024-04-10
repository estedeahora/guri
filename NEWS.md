# guri (development version)

## Breaking changes

* Se modifica programa para que este disponible como paquete de R.
* Se simplifica estructura de funciones.
* Se modifican funciones para permitir diferentes plataformas y sistemas operativos (rutas con `file.path`).
* Se incorpora instalacion de dependencias de Pandoc y tinytex desde funcion integrada (ver `guri_install`).
* Se modifica la generacion de documentos finales unificando las funciones de generacion de documentos (`guri_to_*`) mediante funcion interna `guri_convert`.
* Se mejoran los mensajes (usando `{cli}` en lugar de interface base y ) y se traducen a ingles.
* Se permiten filtros personalizados.
* El idioma principal no necesita ser el español. Actualmente se da soporte completo para inglés y, parcialmente, para portugués. Nuevos idiomas pueden ser incorporados agregando diccionario de palabras.
* Se permite el uso de múltiples idiomas para metadatos.
* Se permite idioma del artículo diferente del idioma principal de la revista.
* Se actualiza templates para que sea compatible con Pandoc 3.1.13.
* Se genera documentacion y ejemplos para todas las funciones.
* Se soluciona problema de cambio de directorios usando `on.exit()`.
* La revistas de ejemplo se incorpora como opcional dentro de `guri_make_journal`.

## New features

* Desarrollar

## Documentation improvements

* Desarrollar

## Minor improvements and bug fixes

* Desarrollar

# guri 1.1.0

Initial release.
