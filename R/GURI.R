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

guri <- function(art_path,
                 art_id,
                 journal = NULL,
                 verbose = FALSE,
                 clean_files = TRUE){

  # CHECK: dependences version (pandoc)
  if(!pandoc::pandoc_version() >= pandoc_req){
    ui_abort("Upgrade the Pandoc version (", pandoc_req, " or later is required). ",
             "To upgrade Pandoc run ", col_red("`GURI_install(pandoc = T, tinytex = F)`"),
             "; or Download manually the latest version from the Pandoc site: ",
             "{.url https://github.com/jgm/pandoc/releases/latest}")
  }

  # CHECK: '.guri' file
  guri_file <- read_guri_file()
  if(!is.null(guri_file)){

    # guri_repository <- any(stringr::str_detect(guri_file$raw, "^repository: TRUE$"))
    # guri_journal <- any(stringr::str_detect(guri_file, paste0("^journals:.*", journal)))

    # if(is.null(journal) &&  guri_repository){
    if(is.null(journal) &&  guri_file$repository){
      ui_abort("No `journal` field was provided, but it seems to be working in ",
               "a journal repository (see `.guri` file).  The `journal` parameter ",
               "is mandatory.")
    }

    if(guri_file$repository && !(journal %in% guri_file$journals_list)){
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

  # CHECK: Do mandatory files and folders exist?
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

  # Auxiliary files
  guri_to_AST(path_relative, art_id)
  guri_biblio(path_relative, art_id)

  # Cleaning of temporary files, log and output
  guri_clean_files(path_relative, art_id)

  ui_alert_success(col_green("Output files generated correctly."))

}

#' Convert the 'xlsx' file with the credit information to csv format.
#'
#' @inheritParams guri
#' @inheritParams guri_clean_files
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
    ui_alert_info("There is no '", credit_files[[1]],"' file with the credit data.")
  }

  invisible(T)

}

#' Clean temporary log and output files
#'
#' @param path A string with the path to the article folder.
#' @inheritParams guri
#'
#' @return Invisible TRUE.

guri_clean_files <- function(path, art_id, verbose){

  if(verbose){
    cli_process_start("Cleaning up working directory and temporary files.")
  }
  path_temp <- fs::dir_create(file.path(path, "_temp"))
  path_out <- fs::dir_create(file.path(path, "_output"))
  path_log <- fs::dir_create(file.path(path, "_log"))

  archivos <- fs::dir_ls(path, recurse = F)

  sel_temp <- c("\\.tex", "\\.native", "\\.md", "_app[0-9]\\.md",
              "_credit\\.csv", "_biblio\\.((json)|(bib))")
  pat_temp <- make_pattern(sel_temp, art_id )
  move_files(pat_temp, path_dest = path_temp, file_list = archivos)
  # ui_alert_success("Move temporary files to './_temp/'")

  sel_out <- c("\\.pdf", "\\.xml", "\\.html")
  pat_out <- make_pattern(sel_out, art_id )
  move_files(pat_out, path_dest = path_out, file_list = archivos)
  # ui_alert_success("Move output files to './_output/'")

  pat_log <- paste0(".*log-.*\\.log")
  move_files(pat_log, path_dest = path_log, file_list = archivos)
  # ui_alert_success("Move log files to './_log/'")

  if(verbose){
    cli_process_done(msg_done = col_grey("Cleaning up working directory and temporary files."))
  }
  invisible(TRUE)
}

make_pattern <- function(string, root){

  groups <- paste0("(", string, ")")
  groups_collapsed <- paste0(groups, collapse = "|")

  pattern <- paste0(".*", root, "(", groups_collapsed,")" )
  return(pattern)
}

move_files <- function(pattern, path_dest, file_list){

  files <- stringr::str_extract(file_list, pattern)
  files <- stats::na.omit(files)
  fs::file_move(path = files, new_path = path_dest)

  invisible(TRUE)
}



