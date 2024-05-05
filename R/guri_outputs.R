# art_id <- "art101"
# journal <-  "example"
# issue <- "num1"
# verbose = T; clean_files = T

# Opciones: guri_publishing / guri_outputs / guri_to_formats /
# guri_format_generator / guri_publish_formatter / guri_output_generator

#' Función para generar archivos finales
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
#'
#' @export

guri_outputs <- function(art_id,
                         issue,
                         journal = NULL,
                         verbose = FALSE,
                         clean_files = TRUE){

  # CHECK: dependences version (pandoc and tinytex)
  if(!pandoc::pandoc_version() >= pandoc_req){
    ui_abort("Upgrade the Pandoc version (", pandoc_req, " or later is required). ",
             "To upgrade Pandoc run ", col_red("`GURI_install(pandoc = T, tinytex = F)`"),
             "; or Download manually the latest version from the Pandoc site: ",
             "{.url https://github.com/jgm/pandoc/releases/latest}")
  }else if(!tinytex::is_tinytex()){
    ui_abort("Tinytex (Latex distribution) is not available. To install tinytex",
             "try running ", col_red("`GURI_install(pandoc = F, tinytex = T)`"), ". ",
             "If it doesn't work try ", col_red("'tinytex::install_tinytex()'"), ".")
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

  # CHECK: mandatorory issue folders and files
  if(!fs::dir_exists(path_issue)){
    ui_abort("The specified folder does not exist (",
             "{.path ", path_issue, "}.) ",
             "Check the `journal` and `issue` parameters.")
  }else if(!file.exists(fs::path(path_issue, "_issue.yaml"))){
    ui_abort("It is necessary that '_issue.yaml' exist in the issue folder.")
  }

  # List of articles present in the issue
  article_list <- guri_list_articles(path_issue)

  if(length(art_id) != 1 || art_id != "all"){

    # filter by art_id
    article_list <- article_list[article_list$id %in% art_id, ]

    id_is_present <- art_id %in% article_list$id
    if(!all(id_is_present)){
      ui_abort("Theare are ids not present in the issue folder (see: ",
               paste0(paste0("'", art_id[!id_is_present], "'"), collapse = ", "),
               ").")
    }
  }

  success <- purrr::pmap_lgl(article_list,
                             function(path, dir, id,
                                      v = verbose, cf = clean_files){
                               tryCatch(
                                 expr = guri_article(art_path = path,
                                                    art_dir = dir,
                                                    art_id = id,
                                                    verbose = v,
                                                    clean_files = cf),
                                 error = function(e) {
                                     print(e)
                                     invisible(F)
                                   }
                               )
                             }
                           )

  names(success) <- article_list$dir

  cli_h1("Summary of processed articles:")

  ui_alert_info("Processed articles: ", length(success),
                col_blue(" (", sum(success), " successfull)"), ".")

  purrr::walk2(success, article_list$id,
              \(.x, .y){
                if(.x){
                  ui_alert_success(cli::col_white(.y))
                }else{
                  ui_alert_danger(col_yellow(.y))
                }
              })

  invisible(success)
}
