#' Converts the corrected manuscript between formats.
#'
#' @description They convert between the different formats required for the
#' `~!guri_` workflow, applying the appropriate lua filters at each stage and
#' using the appropriate templates and metadata. The `~!guri_to_md` function
#' converts between the revised (and formatted) manuscript in `docx` format to
#' markdown format. The `guri_to_html`, `guri_to_jats` and `guri_to_pdf`
#' functions convert from the markdown file to `html`, `xml` (xml-jats) and
#' `pdf` (`tex`) formats, respectively. Last, `guri_to_AST` and `guri_biblio`
#' are auxiliary functions that generate a file with the Abstract Syntax Tree
#' (mostly for debugging purposes) and a file with the references used by the
#' article, respectively.
#'
#' @inheritParams guri_article
#'
#' @details These functions are, mostly, a wrapper of the internal function
#' [guri_convert]. The functions are exported primarily for debugging and error
#' detection purposes. For day-to-day work it is advisable to use the [guri]
#' function directly, which coordinates the generation of all these formats and
#' ensures the correct definition of the parameters.
#'
#' For the generation of pdf files, LuaTex ([tinytex::lualatex]) is used
#' internally.
#'
#' @return Invisible `TRUE`

guri_to_md <- function(art_path, art_id, verbose = TRUE){

  cli_process_start(col_yellow("Creating markdown file (docx -> md)."))

  guri_convert(art_path = art_path, art_id = art_id,
               output = "md", verbose = verbose)

  cli_process_done(msg_done = col_grey("Creating markdown file (docx -> md)."))

  invisible(T)
}

#' @rdname guri_to_md

guri_to_html <- function(art_path, art_id, verbose = TRUE){

  cli_process_start(col_yellow("Creating html file (md -> html)."))

  guri_convert(art_path = art_path, art_id = art_id,
               output = "html", verbose = verbose)

  cli_process_done(msg_done = col_grey("Creating html file (md -> html)."))

  invisible(T)
}

#' @rdname guri_to_md

guri_to_jats <- function(art_path, art_id, verbose = TRUE){

  cli_process_start(col_yellow("Creating xml-jats file (md -> xml-jats)."))

  guri_convert(art_path = art_path, art_id = art_id,
               output = "jats", verbose = verbose)

  cli_process_done(msg_done = col_grey("Creating xml-jats file (md -> xml-jats)."))

  invisible(T)
}

#' @rdname guri_to_md
#' @param pdf Logical. Should the pdf be generated? (default = TRUE)

guri_to_pdf <- function(art_path, art_id, verbose = TRUE, pdf = TRUE){

  # Conversión md -> tex

  cli_process_start(col_yellow("Creating latex file (md -> tex)."))

  guri_convert(art_path = art_path, art_id = art_id,
               output = "tex", verbose = verbose)

  cli_process_done(msg_done = col_grey("Creating latex file (md -> tex)."))

  # Conversión tex -> pdf

  wdir <- file.path(getwd(), art_path)
  file_tex    <- paste0(art_id, ".tex")

  proj_dir <- setwd(wdir)
  on.exit(setwd(proj_dir), add = T)  # Volver a valores por defecto al salir

  # Retener warnings?
  # if(verbose){
  # ### tinytex_warn <- options()$tinytex.latexmk.warning
  # tinytex_warn <- options(tinytex.latexmk.warning = verbose)
  # on.exit(options(tinytex.latexmk.warning = tinytex_warn))
  # }

  if(pdf){
    cli_process_start(col_yellow("Creating pdf file (tex -> pdf)."))
    tinytex::lualatex(file_tex)
    cli_process_done(msg_done = col_grey("Creating pdf file (tex -> pdf)."))
  }

  invisible(T)
}

# Genera archivo con xml para crossref

#' @rdname guri_to_md

guri_to_crossref <- function(art_path, art_id, verbose = TRUE) {

  is_doi <- fs::path(art_path, art_id, ext = "md") |>
    rmarkdown::yaml_front_matter() |>
    purrr::pluck("article") |>
    purrr::pluck("doi")

  if(is.null(is_doi)){
    if(verbose){
      ui_alert_info("There is no DOI present. Does not generate DOI register files for Crossref.")
    }
    return(invisible(F))
  }

  cli_process_start(col_yellow("Creating crossref xml file (md -> xml-crossref)."))

  guri_convert(art_path = art_path, art_id = art_id,
               output = "crossref", verbose = verbose)

  cli_process_done(msg_done = col_grey("Creating crossref xml file (md -> xml-crossref)."))

  invisible(T)
}

# Genera archivo con AST

#' @rdname guri_to_md

guri_to_AST <- function(art_path, art_id, verbose = TRUE) {

  cli_process_start(col_yellow("Creating AST file (md -> native)."))

  guri_convert(art_path = art_path, art_id = art_id,
               output = "AST", verbose = verbose)

  cli_process_done(msg_done = col_grey("Creating AST file (md -> native)."))

  invisible(T)
}

# Genera archivo con bibliografia (en biblatex o csljson)

#' @rdname guri_to_md
#'
#' @param bib_type description

guri_biblio <- function(art_path, art_id, bib_type = "csljson"){

  cli_process_start(col_yellow("Creating biblio file (md -> ", bib_type, ")."))

  # Archivos de entrada / salida
  file_input  <- paste0(art_id, ".docx")

  if(bib_type == "csljson"){
    file_out <- paste0(art_id, "_biblio.json")
  }else if(bib_type == "biblatex"){
    file_out <- paste0(art_id, "_biblio.bib")
  }else{
    ui_abort("'bib_type' argument must be 'biblatex' or 'csljson'.")
  }

  rmarkdown::pandoc_convert(wd = file.path(getwd(), art_path),
                            input = file_input,
                            from = "docx+citations",
                            output = file_out ,
                            to = bib_type)
  cli_process_done(msg_done = col_grey("Creating biblio file (md -> ", bib_type, ")."))

  invisible(T)
}

