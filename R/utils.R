# Funciones auxiliares

# Manejar archivos ---------------------------------

# devtools_loaded()
# Adapted from rmarkdown
# https://github.com/rstudio/rmarkdown/blob/ee69d59f8011ad7b717a409fcbf8060d6ffc4139/R/util.R#L562
# Also from pkgdown & downlit
# https://github.com/r-lib/pkgdown/blob/77f909b0138a1d7191ad9bb3cf95e78d8e8d93b9/R/utils.r#L52

devtools_loaded <- function(x) {
  if (!x %in% loadedNamespaces()) {
    return(FALSE)
  }
  ns <- .getNamespace(x)
  !is.null(ns$.__DEVTOOLS__)
}

# pkg_file()
# needs to handle the case when this function is used in a package loaded with
# devtools or pkgload load_all(). Required for testing with testthat also.
# adapted from rmarkdown:
# https://github.com/rstudio/rmarkdown/blob/ee69d59f8011ad7b717a409fcbf8060d6ffc4139/R/util.R#L45C1-L56C2
# Also from pkgdown:
# https://github.com/r-lib/pkgdown/blob/04d3a76892320ac4bd918b39604c157e9f83507a/R/utils-fs.R#L85
pkg_file <- function(..., package = "guri", mustWork = FALSE) {
  if (devtools_loaded(package)) {
    # used only if package has been loaded with devtools or pkgload
    file.path(find.package(package), "inst", ...)
  } else {
    system.file(..., package = package, mustWork = mustWork)
  }
}

# pkg_file_lua()
# Get the full paths of Lua filters in an R package
#
# Adapted from rmarkdown:
# https://github.com/rstudio/rmarkdown/blob/ee69d59f8011ad7b717a409fcbf8060d6ffc4139/R/util.R#L58-L60

pkg_file_lua <- function(filters = NULL, package = "guri") {
  files <- pkg_file(
    "filters", if (is.null(filters)) '.' else filters,
    package = package, mustWork = TRUE
  )
  # if (is.null(filters)) {
  #   files <- list.files(dirname(files), "[.]lua$", full.names = TRUE)
  # }
  rmarkdown::pandoc_path_arg(files)
}

# GURI_to_AST() -----------------------------------
# Genera archivo con estructura AST

GURI_to_AST <- function(path_art, art) {

  wdir <- paste0(getwd(), path_art)

  # Archivos de entrada / salida
  file_input  <- paste0(art, ".md")
  file_json    <- paste0(art, "_AST.json")

  # Archivos de programa ('./files/')
  program_path = "../../../files/"

  # Opciones generales
  op_gral <- c("--wrap=none", "--mathml",
               "--metadata=link-citations",
               "--reference-links=true")

  # Filtros Lua
  op_filters <- paste0("--lua-filter=",  program_path, "filters/",
                       c("include-float-in-format",
                         "metadata-format-in-text"),
                       ".lua")

  pandoc_convert(wd = wdir,
                 input = file_input,
                 from = "markdown",
                 output = file_json,
                 to = "json",
                 citeproc = T,
                 options = c(op_gral, op_filters))
}

# GURI_biblio() ----------------------------------
# Genera archivo con bibliografía (en biblatex o csljson)

GURI_biblio <- function(path_art, art, bib_type = "csljson"){

  wdir <- paste0(getwd(), path_art)

  # Archivos de entrada / salida
  file_input  <- paste0(art, ".docx")

  if(bib_type == "csljson"){
    file_out <- paste0(art, "_biblio.json")
  }else if(bib_type == "biblatex"){
    file_out <- paste0(art, "_biblio.bib")
  }else{
    stop("'bib_type' debe ser 'biblatex' o 'csljson'")
  }

  pandoc_convert(wd = wdir,
                 input = file_input,
                 from = "docx+citations",
                 output = file_out ,
                 to = bib_type)

}

# GURI_zip_input() ----------------------------------------------------------

GURI_zip_input <- function(id_art){

  work_files <- paste0(paste0(id_art, c(".docx", #"_biblio.json",
                                        "_notes.md", ".yaml",
                                        "_credit.xlsx") ))
  float_dir <- paste0("float")
  if(dir.exists(float_dir) ){
    work_files <- c(work_files, float_dir)
  }

  zip_file <- paste0(id_art, "_", format(today(), "%Y.%m.%d"), ".zip")

  zip(zipfile = zip_file, files = work_files)

}

# GURI_clean_temp() -------------------------------------------

GURI_clean_temp <- function(id_art){

  if(!dir.exists("./_temp")){
    dir.create("./_temp")
  }
  archivos <- list.files(".")
  patron <- paste0(id_art, c("\\.tex", "_AST\\.json", "\\.md",
                             "_app[0-9]\\.md", "_credit\\.csv",
                             "_biblio\\.((json)|(bib))"
  )) |>
    paste0(collapse = "|")
  archivos <- archivos[str_detect(archivos, patron)]

  walk2(archivos, paste0("./_temp/", archivos),
        file.rename)

}

# GURI_output() -------------------------------------------

GURI_output <- function(id_art){

  if(!dir.exists("./_output")){
    dir.create("./_output")
  }

  archivos <- paste0(id_art, c(".pdf", ".xml", ".html"))

  walk2(archivos, paste0("./_output/", archivos),
        file.rename)

}