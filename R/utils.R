# Manejar path a archivos inst/

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
    file.path(find.package(package), "inst", "files-pkg", ...)
  } else {
    system.file("files-pkg", ..., package = package, mustWork = mustWork)
  }
}

# # pkg_file_lua()
# # Get the full paths of Lua filters in an R package
# #
# # Adapted from rmarkdown:
# # https://github.com/rstudio/rmarkdown/blob/ee69d59f8011ad7b717a409fcbf8060d6ffc4139/R/util.R#L58-L60
#
# pkg_file_lua <- function(filters = NULL, package = "guri") {
#   files <- pkg_file(
#     # "filters", if (is.null(filters)) '.' else filters,
#     "filters", filters,
#     package = package, mustWork = TRUE
#   )
#   # if (is.null(filters)) {
#   #   files <- list.files(dirname(files), "[.]lua$", full.names = TRUE)
#   # }
#   rmarkdown::pandoc_path_arg(files)
# }

#' Prepare the working directory for each article
#'
#' @param art_path A string with the path to the article folder.
#' @param art_pre A string. This prefix is used to identify the folders where each issue of your journal will be stored. For example, if you use 'num' (default) the folders where you should store the issues of your journal will be 'num1', 'num2', and so on.
#'
#' @return Invisible True.

guri_CREDITtoCSV <- function(art_path, art_pre){

  # Generar "art[~]_credit.csv "
  credit_xlsx <- file.path (art_path, paste0(art_pre, "_credit.xlsx"))
  credit_csv  <- paste0(art_path, art_pre, "_credit.csv")

  if(file.exists(credit_xlsx)){
    readxl::read_xlsx(credit_xlsx) |> write.csv(credit_csv, row.names = F, na = "")
  }

  invisible(T)

}

# zip files

zip_input <- function(id_art){

  work_files <- paste0(paste0(id_art, c(".docx",
                                        "_notes.md", ".yaml",
                                        "_credit.xlsx") ))
  float_dir <- paste0("float")
  if(dir.exists(float_dir) ){
    work_files <- c(work_files, float_dir)
  }

  zip_file <- paste0(id_art, "_", format(Sys.Date(), "%Y.%m.%d"), ".zip")

  zip(zipfile = zip_file, files = work_files)

}

# Ordenar archivos temporales (-> .JOURNAL/ISSUE/_temp/)

guri_clean_temp <- function(id_art){

  if(!dir.exists("./_temp")){
    dir.create("./_temp")
  }
  archivos <- list.files(".")
  patron <- paste0(id_art, c("\\.tex", "_AST\\.json", "\\.md",
                             "_app[0-9]\\.md", "_credit\\.csv",
                             "_biblio\\.((json)|(bib))"
  )) |>
    paste0(collapse = "|")
  archivos <- archivos[stringr::str_detect(archivos, patron)]

  purrr::walk2(archivos, paste0("./_temp/", archivos),
               file.rename)

}

# Ordenar archivos de salida (-> .JOURNAL/ISSUE/_output/)

guri_output <- function(id_art){

  if(!dir.exists("./_output")){
    dir.create("./_output")
  }

  archivos <- paste0(id_art, c(".pdf", ".xml", ".html"))

  purrr::walk2(archivos, paste0("./_output/", archivos),
               file.rename)

}
