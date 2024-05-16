# art_id <- "art101"
# art_dir <- "art101_lorem-ipsum"
# art_path <-  "C:/Users/este.de.ahora/Documents/_investigacion/99_Otros-proyectos/guri/example/vol10num1/art101_lorem-ipsum"
# verbose = T; clean_files = T

#' Función para generar archivos finales de un artículo individual
#'
#' @description
#' describir
#'
#' @param art_path String... description
#' @param art_dir String... description
#' @param art_id String...
#' @param verbose Logical...
#' @param clean_files Logical...
#'
#' @return Invisible. ...

guri_article <- function(art_path, art_dir, art_id, # path_issue,
                         verbose = T, clean_files = T){

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

  # Metadata files
  guri_to_crossref(art_path, art_id, verbose = verbose)
  guri_biblio(art_path, art_id)

  # Auxiliary files
  guri_to_AST(art_path, art_id)


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
