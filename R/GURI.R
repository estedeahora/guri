# art_id <- "art101"
# journal <-  "example"
# art_path <- "num1/art101_lorem-ipsum/"
# verbose = T; clean_files = T

#' Función para generar archivos finales de un artículo individual
#'
#' @description
#' describir
#'
#' @param art_path String...
#' @param art_id String...
#' @param journal String... description
#' @param verbose Logical...
#' @param clean_files Logical...
#'
#' @return Invisible. ...
#'
#' @export

guri <- function(art_path, art_id, journal = NULL,
                 verbose = F, clean_files = T){

  # CHECK: dependences version (pandoc)
  if(!pandoc::pandoc_version() >= pandoc_req){
    ui_abort("Upgrade the Pandoc version (", pandoc_req, " or later is required). ",
             "To upgrade Pandoc run ", col_red("`GURI_install(pandoc = T, tinytex = F)`"),
             "; or Download manually the latest version from the Pandoc site: ",
             "{.url https://github.com/jgm/pandoc/releases/latest}")
  }

  # CHECK: '.guri' file
  if(file.exists('.guri')){

    con <- file('.guri')
    guri_file <- readLines(con)
    close(con)

    guri_repository <- any(stringr::str_detect(guri_file, "^repository: TRUE$"))
    guri_journal <- any(stringr::str_detect(guri_file, paste0("^journals:.*", journal)))

    if(is.null(journal) &&  guri_repository){
      ui_abort("No `journal` field was provided, but it seems to be working in ",
               "a journal repository (see `.guri` file).  The `journal` parameter ",
               "is mandatory.")
    }

    if(guri_repository && !guri_journal){
      ui_alert_warning("The journal ('", journal, "') is not listed in the ",
                       "`.guri` file. It is advisable to generate your journals ",
                       "with `.guri_make_journal`.")
    }

  }else{ # No '.guri' file
    ui_alert_warning("There is not a `.guri` file in your working directory. It ",
                     "is advisable to generate your journals with `.guri_make_journal`.")
  }

  cli_h1(col_green(paste("Article:", art_id)))

  if(is.null(journal)){
    path <- fs::path_abs(file.path(art_path))
  }else{
    path <- fs::path_abs(file.path(journal, art_path))
  }

  # CHECK: exist files
  art_files <- paste0(art_id, c(".docx", ".yaml"))
  if(!dir.exists(path)){
    ui_abort("Check `journal` and `art_path`. ",
             "The specified folder does not exist: ",
             "{.path ", path, "}.")
  }else if(!all(file.exists(file.path(path, art_files)))){
    ui_abort("It is necessary that ",
             paste0(paste0("'", art_files, "' "), collapse = "and "),
             "exist in the specified folder.")
  }

  # PREPARE: art[~]_CREDIT.xlsx -> to -> art[~]_CREDIT.csv
  CREDIT_to_CSV(path = path, art_id = art_id, verbose = verbose)

  # CONVERT: files to format
  path_relative <- fs::path_rel(path)
  guri_to_md(path_relative, art_id, verbose = verbose)
  guri_to_jats(path_relative, art_id, verbose = verbose)
  guri_to_html(path_relative, art_id, verbose = verbose)
  guri_to_pdf(path_relative, art_id, verbose = verbose)

  guri_biblio(path, art_id)
  guri_to_AST(path, art_id)

  # docx -> md
  # cli_process_start(col_yellow("Crear archivo markdown"))
  # cli_process_done()

  # md -> jats
  # cat("\033[33m", "* Crear archivo jats-xml (", art_id, ".xml ).", "\033[39m")
  # cat("DONE\n")
  # md -> html
  # cat("\033[33m", "* Crear archivo html (", art_id, ".html ).", "\033[39m")
  # cat("DONE\n")
  # md -> tex + pdf
  # cat("\033[33m", "* Crear archivo latex (", art_id, ".tex ).",
  #     "y pdf (", art_id, "pdf ).", "\033[39m")
  # cat("DONE\n")

  # docx -> biblio
  # cat("\033[33m", "* Crear archivo de bibliografia (", art_id, "_biblio).", "\033[39m")
  # cat("DONE\n")
  # md -> AST
  # cat("\033[33m", "* Crear AST (", art_id, "_AST.json ).", "\033[39m")
  # cat("DONE\n")

  # File reorganization
  wd_orig <- getwd()
  setwd(art_path)


  # Clean files
  if(clean_files){
    cat("\033[33m", "* Mover archivos temporales a './_temp/'", "\033[39m")
    guri_clean_temp(art_id)
    cat("DONE\n")
    cat("\033[33m", "* Mover archivos finales a './_output/'", "\033[39m")
    guri_output(art_id)
    cat("DONE\n")
  }
  setwd(wd_orig)
}

#' Convert the 'xlsx' file with the credit information to csv format.
#'
#' @param path A string with the path to the article folder.
#' @param art_id A string. The 'article id'.
#' @param verbose Logical.
#'
#' @return Invisible TRUE.

CREDIT_to_CSV <- function(path, art_id, verbose){

  credit_files <- paste0(art_id, "_credit.", c("xlsx", "csv"))
  credit_paths <- file.path(path, credit_files)

  if(file.exists(credit_paths[[1]])){

    readxl::read_xlsx(credit_paths[[1]]) |> write.csv(credit_paths[[2]], row.names = F, na = "")

    if(verbose){
      ui_alert_success("File preparation (converting '", credit_files[[1]], "' to csv file)")
    }
  }else{
    ui_alert_warning("There is no '", credit_files[[1]],"' file with the credit data.")
  }

  invisible(T)

}
