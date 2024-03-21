# 1. Load {guri} package

library(guri)

# 2. Installation and configuration
# Instalar paquetes y distribución de latex (ejecutar la primera vez que ejecuta ~!gurí_)
# GURI_install()

# Crear el directorio y los archivos de revista (ejecutar sólo una vez por revista)
# GURI_make_journal("journal name")

# 3. Ajustes principales
# Defina el directorio de su revista (`journal`), así como el prefijo utilizado
#   para indicar los números de su revista (`prefix`). Por último indique el
#   número que desea procesar (`issue`).

journal <- "example"    # Define directorio de la revista (no usar espacios)
prefix <- "num"         # Prefijo para diferenciar número/volumen. Define directorio de número actual
issue <- 1              # Número/volumen de la revista que desea procesar


# 4. File data

# Definir paths
path_root    <- paste0("./", journal, "/")
path_aux     <- paste0(path_root, "files/")
path_issue   <- paste0(path_root, prefix, issue, "/")

# 5. Armado de archivos base de cada artículo
#   * Devuelve lista de archivos en cada carpeta ./{issue}/{art}
#   * Diferencia artículos según tipo
(art <- GURI_listfiles(path_issue) )

# 6. Creating output files
walk2(art$art_path, art$art_id,
      \(x, y) GURI(x, y, verbose = F) )
