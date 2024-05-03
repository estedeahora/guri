# art_id <- "art101"
# journal <-  "example"
# issue <- "num1"
# verbose = T; clean_files = T

# Opciones: guri_publishing / guri_outputs / guri_to_formats /
# guri_format_generator / guri_publish_formatter / guri_output_generator

#' Función para generar archivos finales de un artículo individual
#'
#' @description
#' describir
#'
#' @param art_id String...
#' @param issue String...
#' @param journal String... description
#' @param verbose Logical...
#' @param clean_files Logical...
#'
#' @return Invisible. ...
#'
#' @export

guri_outputs <- function(art_id,
                         issue,
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

  # Construct path to issue
  if(is.null(journal)){
    path_issue <- fs::path_wd(issue)
  }else{
    path_issue <- fs::path_wd(journal, issue)
  }

  article_list <- guri_list_articles(path_issue)

  # recursive call for multiple articles
  if(length(art_id) > 1 || art_id == "all"){

    if(length(art_id) > 1){
      article_list <- article_list |> dplyr::filter(id %in% art_id)

      id_is_present <- art_id %in% article_list$id

      if(!all(id_is_present)){
        ui_abort("Theare are ids not present in the issue folder (see: ",
                 paste0(paste0("'", art_id[!id_is_present], "'"), collapse = ", "),
                 ").")
      }
    }

    purrr::walk(article_list$id,
                ~guri_outputs(art_id = .x,
                              issue = issue,
                              journal = journal,
                              verbose = verbose,
                              clean_files = clean_files))

    return(invisible(TRUE))
  }

  # else -> single article (base case)
  article_list <- article_list |> dplyr::filter(id %in% art_id)
  if(nrow(article_list) != 1){
    ui_abort("`" , art_id, "` does not exist in the issue folder.")
  }

  title <- article_list$dir |> stringr::str_replace_all("_", ": ") |> stringr::str_replace_all("-", " ")
  cli_h1(col_green(paste0("Article ", title)))

  # CHECK: Do mandatory files and folders exist?
  art_files <- paste0(art_id, c(".docx", ".yaml"))

  if(!dir.exists(article_list$path)){
    ui_abort("Check `journal` and `issue`. ",
             "The specified folder does not exist: ",
             "{.path ", article_list$path, "}.")
  }else if(!all(file.exists(fs::path(article_list$path, art_files)))){
    ui_abort("It is necessary that ",
             paste0(paste0("'", art_files, "' "), collapse = "and "),
             "exist in the specified folder.")
  }else if(!file.exists(fs::path(path_issue, "_issue.yaml"))){
    ui_abort("It is necessary that '_issue.yaml' exist in the issue folder.")
  }

  art_path <- fs::path_rel(article_list$path)

  # PREPARE: art[~]_CREDIT.xlsx -> to -> art[~]_CREDIT.csv
  CREDIT_to_CSV(art_path = art_path, art_id = art_id, verbose = verbose)

  # CONVERT: files to format

  guri_to_md(art_path, art_id, verbose = verbose)
  guri_to_jats(art_path, art_id, verbose = verbose)
  guri_to_html(art_path, art_id, verbose = verbose)
  guri_to_pdf(art_path, art_id, verbose = verbose)

  # Auxiliary files
  guri_to_AST(art_path, art_id)
  guri_biblio(art_path, art_id)

  # Cleaning of temporary files, log and output
  guri_clean_files(art_path, art_id, verbose = verbose)

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
#' @param path A string with the path to the article folder.
#' @inheritParams guri_outputs
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
