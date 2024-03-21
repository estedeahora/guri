#' Crear revista de ejemplo
#'
#' @export

GURI_example <- function(){

  journal <- "example"
  GURI_make_journal(journal = journal)

  example_folder <- pkg_file(journal)
  file.copy(from = file.path(example_folder, "num1"),
            to = file.path(".", journal), recursive = T,
            overwrite = T)
  cli_alert_success(paste0("Copy example journal issue ({.path ./example/num1/})."))

  file.copy(from = file.path(example_folder, "_journal.yaml"),
            to = file.path(".", journal, "_journal.yaml"), overwrite = T)

  cli_alert_success("Copy {.path ./_journal.yaml} file.")

  cli_alert_info("Ejecute GRUI_output_issue('num1', journal = 'example') para generar los archivos finales de esta revista de ejemplo")
  invisible(T)

}

