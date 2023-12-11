# 1. Ajustes principales
# Defina el directorio de su revista (`journal`), así como el prefijo utilizado 
#   para indicar los números de su revista (`prefix`). Por último indique el 
#   número que desea procesar (`issue`). 

journal <- "example"    # Define directorio de la revista (no usar espacios)
prefix <- "num"         # Prefijo para diferenciar número/volumen. Define directorio de número actual

issue <- 1              # Número/volumen de la revista que desea procesar

# Packages ----------------------------------------------------------------

library(tidyverse)
library(rmarkdown)
library(readxl)
library(tinytex)
library(crayon)

# Cargar funciones --------------------------------------------------------

source("scripts/GURI_00_fx.R", encoding = "UTF-8")

# Datos -------------------------------------------------------------------

# Definir paths
path_root    <- paste0("./", journal, "/") 
path_aux     <- paste0(path_root, "files/")
path_issue   <- paste0(path_root, prefix, issue, "/")

# Armado de archivos base de cada artículo
#   * Devuelve lista de archivos en cada carpeta ./{issue}/{art}
#   * Diferencia artículos según tipo
(art <- GURI_listfiles(path_issue) )

# Armado de archivos finales
walk2(art$art_path, art$art_id, 
      \(x, y) GURI(x, y, verbose = F) )
