# Ajustes principales

journal <- "QUID16"      # Define directorio de la revista (no usar espacios)
prefijo <- "num"         # Prefijo para diferenciar número/volumen. Define directorio de número actual

numero <- 20

# Definir paths
path_root    <- paste0("./", journal, "/") 
path_aux     <- paste0(path_root, "files/")
path_issue   <- paste0(path_root, prefijo, numero, "/")

# Packages ----------------------------------------------------------------

library(tidyverse)
library(rmarkdown)
library(readxl)
library(tinytex)
library(crayon)

# Cargar funciones

source("scripts/GURI_00_fx.R", encoding = "UTF-8")

# Armado de archivos base de cada artículo
#   * Devuelve lista de archivos en cada carpeta ./{issue}/{art}
#   * Diferencia artículos según tipo
art <- GURI_listfiles(path_issue) 

# Armado de archivos finales
walk2(art$art_path, art$art_id, 
      \(x, y) GURI(x, y, verbose = F) )

# i <- 6
# GURI(art$art_path[i], art$art_id[i], verbose = F)


