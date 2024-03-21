#' Create the basic file structure for a new journal
#'
#' @description
#' Create the basic file structure for a new journal. The journal directory
#' includes a folder with the files used to configure the journal output
#' (`_config`) and a folder with the basic files you will use for the
#' production process (`default-files`). In addition, the `_journal.yaml`
#' file will be generated, which you will have to edit manually with the
#' journal data.
#'
#' @param journal A string with the short name of the journal. This 'short name' can contain only letters, numbers or a low dash (_). It should preferably be a single word.
#' @param issue_prefix A string. This prefix is used to identify the folders where each issue of your journal will be stored. For example, if you use 'num' (default) the folders where you should store the issues of your journal will be 'num1', 'num2', and so on.
#'
#' @return The journal directory with configuration and template files.
#' @export

GURI_make_journal <- function(journal, issue_prefix = "num"){

  if(length(journal) != 1) {
    stop("Provide a unique name for the journal.")
  }

  if(!stringr::str_detect(journal, "^[A-z]([A-z]|[0-9])+$")) {
    stop("The journal.")
  }

  if(length(issue_prefix) != 1) {
    stop("Provide a unique value for the 'issue_prefix'")
  }

  journal_folder <- file.path(".", journal)
  if(dir.exists(journal_folder)){
    stop("The journal name already exists. To create a new journal, choose a new journal name.")
  }

  dir.create(journal_folder)
  cli_alert_success(paste0("Create journal folder ({.path ", journal_folder, "})."))

  config_folder <- pkg_file("config-files/")
  file.copy(from = paste0(config_folder, c("/_config", "/_default-files")),
            to = journal_folder, recursive = T)
  cli_alert_success(paste0("Copy configuration files in {.path ",
                                journal_folder, "/_config/}."))
  cli_alert_success(paste0("Copy default files in {.path ",
                                journal_folder, "/_default-files/}."))



  if(journal != "example"){
    file.copy(from = paste0(config_folder, "/_journal.yaml"),
              to = paste0(journal_folder, "/_journal.yaml"))

    cli_alert_success("Copy {.path ./_journal.yaml} file.")
    cli_alert_info("Edit manually {.path ./_journal.yaml} file.")

    file.edit(paste0(journal_folder, "/_journal.yaml"))
  }
  invisible(T)
}

# TODO
# dir.create(paste0(journal_folder, "/_docs") )
# cli::cli_alert_success(paste0("Create journal documents folder (",
#                              journal_folder, "/_docs)."))
#
# script_path <- paste0(journal_folder, "/GURI_", journal, ".R")
# cat("* Create journal script (", paste0(script_path), ")\n", sep = "")
#
# file.copy(from = "scripts/GURI_01_make-files.R",
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
