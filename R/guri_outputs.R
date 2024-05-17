#' Generate output files for selected articles in an issue
#'
#' @description For selected articles in an issue, generates output files in
#'   pdf, xml-jats and html format. In addition, it generates auxiliary and log
#'   files (see below for details). If `doi_batch = TRUE` is set, it also
#'   generates a single xml file to do the DOI deposit in Crossref for the
#'   selected articles.
#'
#' @param art_id String or vector of strings with the article id to be processed
#'   in the issue. If "all" all articles are processed.
#' @param issue String. The issue folder.
#' @param journal String (optional, mandatory if repository is `TRUE`). If the
#'   journal is not provided, it is assumed that the working directory is the
#'   journal repository. See [guri_make_journal] for details.
#' @param doi_batch Logical. If `TRUE` a `doi_batch` file is created in the
#'   'journal/issue/doi_register' folder (default `FALSE`).
#' @param verbose Logical. Specifies whether to display verbose output (default
#'   `TRUE`).
#' @param clean_files Logical. Should the temporary files be deleted and
#'   reordered in folders after the creation of the final files?. Primarily for
#'   debugging purposes (default is `TRUE`).
#'
#' @details The function generates the output files for each (selected) article
#'   in the issue folder. If art_id is "all", all articles in the issue folder
#'   are processed. The `journal` parameter is mandatory if it is a repository
#'   of journals, otherwise it will be `NULL`.
#'
#' The function generates the following final files for each article:
#' * `art[id].xml`: a xml-jats file. See: https://jats.nlm.nih.gov/publishing/
#' * `art[id].html`: a html file with the article content.
#' * `art[id].pdf`: a pdf file with the article content.
#'
#' Also, the following auxiliary files are created:
#' * `art[id].md`: a markdown file with the article content, used as an intermediate
#'   common format for the conversion to other formats.
#' * `art[id].tex`: a tex (latex) file used to generate the pdf.
#' * `art[id]_crossref.xml`: a xml file with the single article metadata for Crossref
#'   deposit. See:
#'   https://data.crossref.org/reports/help/schema_doc/5.3.1/index.html
#' * `art[id]_biblio.json`: a json file with the article references.
#'   Primarily useful for debugging purposes.
#' * `art[id]_AST.native`: the 'abstract syntax tree' used for Pandoc conversion.
#'
#' In addition, if clean_files is `TRUE`, the function will create following
#'   folders in the article directory:
#' * _output: with the final files generated (xml-jats, html and pdf).
#' * _temp: with the temporary and auxiliary files generated during the process.
#' * _log: with the log files generated during the process (only present if verbose is `TRUE`).
#'
#' If `doi_batch = TRUE`, the function makes a single xml file (in
#'   'journal/issue/doi_register') with the metadata of all selected articles to
#'   do the DOI deposit in Crossref. An inform file is also created with the
#'   information present in the xml file.
#'
#' @return Invisible, a logical vector with the success of the process for each
#'   article.
#'
#' @export

guri_outputs <- function(art_id,
                         issue,
                         journal = NULL,
                         doi_batch = FALSE,
                         verbose = TRUE,
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

  if(doi_batch){#
    if(!all(success)){
      # TODO
      # Preguntar a usuario si no son todos success
    }
    cli_h1("Doi batch creation")

    cli_process_start(col_yellow("Creating doi batch for Crossref."))

    doi_batch_file <- guri_doi_batch(article_list[success, ], path_issue)

    cli_process_done(msg_done = col_grey("Creating doi batch for Crossref."))

    ui_alert_info("See files:\n",
                  "* XML: {.path ", doi_batch_file, "}\n",
                  "* INFO: {.path ", stringr::str_replace(doi_batch_file, "\\.xml$", ".txt") , "}")

  }

  cli_h1("Summary of processed articles")

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
