
# GURI() ----------------------------------------------------

GURI <- function(art_path, art_name, verbose = F,
                 zip_file = F, clean_files = T){

  pandoc_req <- "3.1.10"
  if(!pandoc_version() >= pandoc_req){
    stop("Necesita actualizar su versión de Pandoc (se requiere ",
         pandoc_req, " o posterior). Descargue la última versión",
         "en el sitio de Pandoc: https://github.com/jgm/pandoc/releases/latest")
  }

  # Preprar archivos
  cat("Artículo:", "\033[34m", art_name, "\033[39m", "\n")
  cat("\033[33m", "* Preparación de archivos.", "\033[39m")
  GURI_prepare(art_path, art_name)
  cat("DONE\n")

  # Convert files
  # docx -> md
  cat("\033[33m", "* Crear archivo markdown (", art_name, ".md ).", "\033[39m")
  GURI_to_md(art_path, art_name, verbose = verbose)
  cat("DONE\n")
  # docx -> biblio
  cat("\033[33m", "* Crear archivo de bibliografía (", art_name, "_biblio).", "\033[39m")
  GURI_biblio(art_path, art_name)
  cat("DONE\n")
  # md -> AST
  cat("\033[33m", "* Crear AST (", art_name, "_AST.json ).", "\033[39m")
  GURI_to_AST(art_path, art_name)
  cat("DONE\n")
  # md -> jats
  cat("\033[33m", "* Crear archivo jats-xml (", art_name, ".xml ).", "\033[39m")
  GURI_to_jats(art_path, art_name)
  cat("DONE\n")
  # md -> html
  cat("\033[33m", "* Crear archivo html (", art_name, ".html ).", "\033[39m")
  GURI_to_html(art_path, art_name)
  cat("DONE\n")
  # md -> tex + pdf
  cat("\033[33m", "* Crear archivo latex (", art_name, ".tex ).",
      "y pdf (", art_name, "pdf ).", "\033[39m")
  GURI_to_pdf(art_path, art_name, verbose = verbose)
  cat("DONE\n")

  # File reorganization
  wd_orig <- getwd()
  setwd(art_path)

  # Zip file
  if(zip_file){
    cat("\033[33m", "* Crear zip con archivos usados como entrada", "\033[39m")
    GURI_zip_input(art_name)
    cat("DONE\n")
  }
  # Clean files
  if(clean_files){
    cat("\033[33m", "* Mover archivos temporales a './_temp/'", "\033[39m")
    GURI_clean_temp(art_name)
    cat("DONE\n")
    cat("\033[33m", "* Mover archivos finales a './_output/'", "\033[39m")
    GURI_output(art_name)
    cat("DONE\n")
  }
  setwd(wd_orig)
}

