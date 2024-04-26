# {cli} wraps
# ----------*

ui_alert_info <- function(..., sep = ""){
  cli::cli_alert_info(paste(..., sep = sep))
}

ui_alert_warning <- function(..., sep = ""){
  cli::cli_alert_warning(paste(col_yellow("[WARNING] "), ..., sep = sep))
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

# Lectura/escritura de '.guri' file
# --------------------------------*

read_guri_file <- function(){

  if(file.exists('.guri')){

    con <- file('.guri')
    raw <- readLines(con)
    close(con)

    if(length(raw) == 0){
      ui_alert_warning("The '.guri' file is empty. NULL is returned.")
      return(NULL)
    }

    guri_file <- list()

    guri_file$raw <- raw
    guri_file$repository <- any(stringr::str_detect(raw, "^repository: TRUE$"))

    if(guri_file$repository){
      guri_file$journals <- any(stringr::str_detect(raw, paste0("^journals: .*", "$")))
      guri_file$journals_list <- stringr::str_extract(raw, paste0("^journals: .*", "$")) |>
        stats::na.omit() |>
        stringr::str_remove("^journals: ") |>
        stringr::str_remove_all("\\s*") |>
        stringr::str_split_1(",")
    }else{
      guri_file$journals <- FALSE
      guri_file$journals_list <- NULL
    }


    return(guri_file)
  }else{

  }
  return(NULL)
}

write_guri_file <- function(journal = NULL, repository = NULL,
                            check_exists = TRUE, force = FALSE){

  guri_file <- read_guri_file()

  if(is.null(guri_file) || force){     # no existe .guri -> hay que generarlo desde cero.

    if(is.null(repository)){      # Es obligatorio tener repository
      ui_abort("It is mandatory to provide the 'repository' field to generate ",
               "the '.guri' file.")
    }
    raw <- paste0("repository: ", repository)

    if(repository){
      if(is.null(journal)){    # Es obligatorio tener 'journal' si repository = TRUE
        ui_abort("It is mandatory to provide the 'journal' field to generate ",
                 "the '.guri' file.")
      }
      raw <- c(raw, paste0("journals: ", journal))
    }else if(!is.null(journal)){
      ui_alert_warning("Field 'journal' is ignored if repository = FALSE.")
    }
    ui_alert_info("{.path .guri} file created in the root folder.")

  }else{        # existe .guri -> hay que modificarlo
    raw <- guri_file$raw

    # Chequea si existen los directorios de las revistas
    if(check_exists && guri_file$repository){

      journal_exists <- dir.exists(guri_file$journals_list)

      if(!all(journal_exists)){
        guri_journal_fail <- guri_file$journals_list[!journal_exists]
        ui_alert_warning("The folder(s) ",
                         paste0(paste0("'", guri_journal_fail, "'"), collapse = ", "),
                         " do not exist, but are listed as an active journals ",
                         "in guri file.\n",
                         "            Do you want to remove these journals from ",
                         "your guri archive?\n",
                         col_yellow("Press: Y/n"))
        confirm <- readline()
        if(!confirm %in% c("n", "N")){
          ui_alert_info("'", guri_file$journals_list[!journal_exists],
                        "' is removed from {.path .guri}.")

          guri_file$journals_list <- guri_file$journals_list[journal_exists]
          new_journal_list <- paste0("journals: ",
                                     paste0(guri_file$journals_list, collapse = ", "))
          raw <- stringr::str_replace(raw, "^journals: .*", new_journal_list)
        }
      }
    }

    # se brinda 'repository' -> no es posible modificar repository (da error en la llamada)
    # if(!is.null(repository)){
    #   NULL
    # }

    # se brinda 'journal'
    if(!is.null(journal)){

      if(guri_file$repository){
        if(journal %in% guri_file$journals_list){
          ui_alert_warning("The journal '", journal,
                           "' already exists in '.guri'. The file is not modified.")

        }else{                    # hay que agregar journal a la lista
          guri_file$journals_list <- c(guri_file$journals_list, journal)
          new_journal_list <- paste0("journals: ",
                                     paste0(guri_file$journals_list, collapse = ", "))
          raw <- stringr::str_replace(raw, "^journals: .*", new_journal_list)

          ui_alert_info("'", journal, "' is added to {.path .guri}.")
        }
      }else{
        ui_alert_warning("Cannot add a 'journal' if 'repository' is not TRUE.")
      }
    }
  }

  cat(raw, file= ".guri", sep = "\n")

  invisible(TRUE)
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
