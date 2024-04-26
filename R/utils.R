# {cli} wraps
# ----------*

ui_alert_info <- function(..., sep = ""){
  cli::cli_alert_info(paste(..., sep = sep))
}

ui_alert_warning <- function(..., sep = ""){
  cli::cli_alert_warning(paste(..., sep = sep))
}

ui_alert_success <- function(..., sep = ""){ # , color = "grey50"
  # cli_div(theme = list (.alert = list(color = color)))
  cli::cli_alert_success(col_grey(paste(..., sep = sep)))
  # cli_end()
}

ui_abort <- function(..., sep = ""){
  cli::cli_abort(paste(..., sep = sep))
}

# Manejar path a archivos inst/
# ----------------------------*

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
# Adapted from rmarkdown:
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

# Ordenar archivos temporales y output
# -----------------------------------*
# (-> .JOURNAL/ISSUE/_temp/)
# (-> .JOURNAL/ISSUE/_output/)

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

guri_output <- function(id_art){

  if(!dir.exists("./_output")){
    dir.create("./_output")
  }

  archivos <- paste0(id_art, c(".pdf", ".xml", ".html"))

  purrr::walk2(archivos, paste0("./_output/", archivos),
               file.rename)

}
