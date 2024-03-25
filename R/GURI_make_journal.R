#' Create the basic file structure for a new journal
#'
#' @description
#' Create the basic file structure for a new journal.
#'
#' @param journal A string with the short name of the journal. This 'short name'
#'   can contain only letters, numbers or a low dash (_) and must begin with a
#'   letter. The journal name 'example' is not allowed.
#' @param issue_prefix A string. This prefix is used to identify the folders
#'   where each issue of your journal will be stored. For example, if you use
#'   'num' (default) the folders where you should store the issues of your
#'   journal will be 'num1', 'num2', and so on.
#' @param example Logical. Do you want to create the journal provided as an
#'   example? (Default = FALSE)
#'
#' @details
#' Create the journal folder with configuration and template files. The
#' journal directory includes a folder with the files used to configure
#' the journal output (`_config`) and a folder with the basic files you
#' will use for the production process (`default-files`). In addition,
#' the `_journal.yaml` file will be generated, which you will have to
#' edit manually with the journal data.
#'
#'
#' If 'example = TRUE' a directory of the journal 'example' (`.\example`) is
#' created with the necessary file structure to generate the final output files.
#'
#' @return Invisible returns the journal folder.
#'
#' @examples
#' \dontrun{
#' # Create a folder structure for a new journal.
#' new_journal_folder <- guri_make_journal(journal = "new_journal")
#'
#' list.files(new_journal_folder, recursive = TRUE, include.dirs = TRUE)
#'
#' # Create a folder structure for the 'example journal'.
#' guri_make_journal(example = TRUE)
#'
#' head(list.files("example", recursive = TRUE, include.dirs = TRUE))
#' guri_list_articles("example/num1/")
#' }
#' @export

guri_make_journal <- function(journal = NULL, issue_prefix = "num",
                              example = FALSE){

  if(example){
    if(!is.null(journal)){
      cli_alert_info(paste("The name of the example journal is predefined",
                           "and cannot be modified.",
                           "The name 'example' will be used instead",
                           "of the name given in the 'journal' parameter."))
    }

    journal <- "example"

  }else{

    if(is.null(journal)) {
      stop("Provide a name for the journal.")
    }

    if(length(journal) != 1) {
      stop("Provide a unique name for the journal.")
    }

    if(stringr::str_detect(journal, "^[a-zA-Z]([a-zA-Z0-9_])*$", negate = T)) {
      stop("The name of the journal can only use letters [a-zA-Z], ",
           "numbers[0-9] and low dash (_) and must begin with a letter.")
    }

    if(journal == "example"){
      stop("'example' is not a valid name for a journal.",
           "This name is reserved for the 'example' journal.")
    }

    if(length(issue_prefix) != 1) {
      stop("Provide a unique value for the 'issue_prefix'.")
    }
  }

  journal_folder <- file.path(".", journal)
  if(dir.exists(journal_folder)){
    if(example){
      cli_alert_info(paste("If you want to reinstall the 'example journal',",
                           "delete the './example/' folder",
                           "and run 'guri_make_journal(example = TRUE)'"))
      stop("'example' is already present in folder.\n")
    }else{
      stop("The journal name already exists. To create a new journal, ",
           "choose a new journal name.")
    }
  }

  dir.create(journal_folder)
  cli_alert_success(paste0("Create journal folder ({.path ", journal_folder, "})."))

  config_folder <- pkg_file("config-files")
  file.copy(from = file.path(config_folder, c("_config", "_default-files")),
            to = journal_folder, recursive = T)
  cli_alert_success(paste0("Copy configuration files in {.path ",
                                journal_folder, "/_config/}."))
  cli_alert_success(paste0("Copy default files in {.path ",
                                journal_folder, "/_default-files/}."))

  if(example){

    cli_process_start("Copy example journal issue ({.path ./example/num1/}).")
    example_folder <- pkg_file(journal)
    file.copy(from = file.path(example_folder, "num1"),
              to = file.path(".", journal), recursive = T,
              overwrite = T)
    cli_process_done()

    file.copy(from = file.path(example_folder, "_journal.yaml"),
              to = file.path(".", journal, "_journal.yaml"),
              overwrite = T)
    cli_alert_success("Copy {.path ./_journal.yaml} file.")

    # TODO: Agregar función correcta
    cli_alert_info(paste("To generate the output files for this 'example' journal run:\n",
                         col_red("'GRUI_output_issue('num1', journal = 'example')'.")))

    journal <- "The 'example' journal"
  }else{
    file.copy(from = file.path(config_folder, "_journal.yaml"),
              to = file.path(journal_folder, "_journal.yaml"))

    cli_alert_success("Copy {.path ./_journal.yaml} file.")
    cli_alert_info("Edit manually {.path ./_journal.yaml} file.")

    file.edit(paste0(journal_folder, "/_journal.yaml"))
  }

  cli_alert_success(col_green(paste0(journal, " was successfully created.")))

  invisible(journal_folder)
}

# TODO Definir si se usará (o no) issue_prefix y issue_first (actualmente no se usan).
# TODO Crear carpeta para documentación?
# TODO Generar script (y modificar para adaptar a revista?)

# dir.create(paste0(journal_folder, "/_docs") )
# cli::cli_alert_success(paste0("Create journal documents folder (",
#                              journal_folder, "/_docs)."))


# script_path <- paste0(journal_folder, "/guri_", journal, ".R")
# cat("* Create journal script (", paste0(script_path), ")\n", sep = "")
#
# file.copy(from = "scripts/guri_01_make-files.R",
#           to = script_path)
# iocon <- file(script_path,"r+")
# script <- readLines(iocon)
#
# # Modificar variable journal
# script <- map_chr(script,
#                   \(x) {str_replace(x, '^journal <- "example"',
#                                     paste0('journal <- "', journal, '"'))})
# # Modificar variable prefix
# script <- map_chr(script,
#                   \(x) {str_replace(x, '^prefix <- "num"',
#                                     paste0('prefix <- "', issue_prefix, '"'))})
# # Modificar primer issue
# script <- map_chr(script,
#                   \(x) {str_replace(x, '^issue <- 1',
#                                     paste0('issue <- ', issue_first))})
#
# writeLines(script, con=iocon)
# close(iocon)
#
# file.edit(script_path)
