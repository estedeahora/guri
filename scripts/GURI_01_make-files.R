# Ajustes principales

journal <- "QUID16"      # Define directorio de la revista (no usar espacios)
prefijo <- "num"         # Prefijo para diferenciar número/volumen. Define directorio de número actual

numero <- 30

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

# Armado de archivos base

# Obtener archivos de cada artículo
#   * Devuelve lista de archivos en cada carpeta ./{issue}/{art}
#   * Diferencia artículos según tipo
art <- GURI_listfiles(path_issue) 

GURI(art$art_path[1], art$art_id[1], verbose = T)
GURI(art$art_path[2], art$art_id[2], verbose = F)
  
  