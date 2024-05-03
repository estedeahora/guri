# art_id <- "art101"
# art_dir <- "art101_lorem-ipsum"
# art_path <-  "C:/Users/este.de.ahora/Documents/_investigacion/99_Otros-proyectos/guri/example/vol10num1/art101_lorem-ipsum"
# verbose = T; clean_files = T

#' Función para generar archivos finales de un artículo individual
#'
#' @description
#' describir
#'
#' @param art_id String...
#' @param path_issue String... description
#' @param verbose Logical...
#' @param clean_files Logical...
#'
#' @return Invisible. ...

guri_article <- function(art_path, art_dir, art_id,
                         path_issue, verbose = T, clean_files = T){

  title <- art_dir |> stringr::str_replace_all("_", ": ") |> stringr::str_replace_all("-", " ")
  cli_h1(col_green(paste0("Article ", title)))

  # CHECK: arguments
  if(length(art_path) != 1 || length(art_dir) != 1 || length(art_id) != 1 ){
    ui_abort("'art_path', 'art_dir' and 'art_id' must be length() == 1.")
  }

  # CHECK: mandatory article files and folders
  art_files <- paste0(art_id, c(".docx", ".yaml"))

  if(!fs::dir_exists(art_path)){
    ui_abort("The specified article folder does not exist: ",
             "{.path ", art_path, "}.")
  }else if(!all(fs::file_exists(fs::path(art_path, art_files)))){
    ui_abort("It is necessary that ",
             paste0(paste0("'", art_files, "' "), collapse = "and "),
             "exist in the specified folder.")
  }

  art_path <- fs::path_rel(art_path)

  # art[~]_CREDIT.xlsx -> to -> art[~]_CREDIT.csv
  CREDIT_to_CSV(art_path = art_path, art_id = art_id, verbose = verbose)

  # CONVERT files to format
  guri_to_md(art_path, art_id, verbose = verbose)
  guri_to_jats(art_path, art_id, verbose = verbose)
  guri_to_html(art_path, art_id, verbose = verbose)
  guri_to_pdf(art_path, art_id, verbose = verbose)

  # Auxiliary files
  guri_to_AST(art_path, art_id)
  guri_biblio(art_path, art_id)

  # Cleaning of temporary files, log and output
  if(clean_files){
    guri_clean_files(art_path, art_id, verbose = verbose)
  }

  ui_alert_success(col_green("Output files generated correctly."))

  invisible(TRUE)
}

#' Convert the 'xlsx' file with the credit information to csv format.
#'
#' @inheritParams guri_outputs
#' @inheritParams guri_clean_files
#'
#' @return Invisible TRUE.

CREDIT_to_CSV <- function(art_path, art_id, verbose){

  credit_files <- paste0(art_id, "_credit.", c("xlsx", "csv"))
  credit_paths <- fs::path(art_path, credit_files)

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
#' @param art_path A string with the path to the article folder.
#' @inheritParams guri_outputs
#'
#' @return Invisible TRUE.

guri_clean_files <- function(art_path, art_id, verbose){

  if(verbose){
    cli_process_start("Cleaning up working directory and temporary files.")
  }
  # Dir creation
  path_temp <- fs::dir_create(file.path(art_path, "_temp"))
  path_out <- fs::dir_create(file.path(art_path, "_output"))
  if(verbose){
    path_log <- fs::dir_create(file.path(art_path, "_log"))
  }

  archivos <- fs::dir_ls(art_path, recurse = F, type = "file")

  sel_temp <- c("\\.tex", "\\.native", "\\.md", "_app[0-9]\\.md",
                "_credit\\.csv", "_biblio\\.((json)|(bib))")
  pattern_temp <- make_pattern(sel_temp, art_id )
  move_files(pattern_temp, path_dest = path_temp, file_list = archivos)
  # ui_alert_success("Move temporary files to './_temp/'")

  sel_out <- c("\\.pdf", "\\.xml", "\\.html")
  pattern_out <- make_pattern(sel_out, art_id )
  move_files(pattern_out, path_dest = path_out, file_list = archivos)
  # ui_alert_success("Move output files to './_output/'")

  if(verbose){
    pattern_log <- paste0(".*log-.*\\.log")
    move_files(pattern_log, path_dest = path_log, file_list = archivos)
    # ui_alert_success("Move log files to './_log/'")
  }

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
