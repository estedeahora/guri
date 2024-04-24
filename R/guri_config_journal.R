# TODO: optional customized journal (metadata + templates)
# TODO: función autónoma exportada?
# TODO: permitir generar archivo csl?

# "chicago-author-date-16th-edition"
# customized_tex = "default", customized_html = "default",
# customized_tex = NULL, customized_html = NULL,

#' Create the journal configuration files
#'
#' @description
#' Create the journal configuration files in `_config`. If `csl_name` is given,
#'   it also places the corresponding csl in the configuration folder.
#'
#' @param journal_folder A string with the path to the journal. If `NULL` (default),
#'   the working folder is used. For journal repositories, this must be provided.
#' @param csl_name A string with the CSL's name (without its extension).
#'   See: https://github.com/citation-style-language/styles
#' @param force Logical. Should it be overwritten if a configuration folder already
#'   exists (Default: FALSE)?
#'
#' @return Invisible `TRUE`.
#'
#' @export

guri_config_journal <- function(journal_folder = NULL,
                                csl_name  = NULL,
                                force = FALSE){

  # templates files
  templates_files <- c("custom_journal.sty", "template.latex",
                       "styles.html", "template.html")
  file.copy(from = pkg_file("template", templates_files),
            to = file.path(journal_folder, "_config", templates_files))

  ui_alert_success("Copy template files in '",
                   fs::path_rel(file.path(journal_folder, "_config", "*")),
                   "'.")

  # metadata files
  metadata_files <- paste0(c("html", "latex"), "_metadata.yaml")
  file.copy(from = pkg_file("pandoc", metadata_files),
            to = file.path(journal_folder, "_config", metadata_files))

  ui_alert_success("Copy metadata files in '",
                   fs::path_rel(file.path(journal_folder, "_config", "*")),
                   "'.")

  ui_alert_info("Edit the files within '{.path ",
                fs::path_rel(file.path(journal_folder, "_config")),
                "}' to customise the appearance of your journal.")

  # if(!is.null(csl_name)){
  #
  #   download.file(paste0("https://raw.githubusercontent.com/citation-style-language/styles/master/",
  #                        csl_name, ".csl"),
  #                 file.path(journal_folder, "_config", paste0(csl_name, ".csl")),
  #                 quiet = T)
  #   file.copy(from = temp,
  #             to = )
  # }

  invisible(TRUE)

}
