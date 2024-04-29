#' Converts the corrected manuscript in docx format to markdown format.
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
#' @inheritParams guri_convert
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
#'
#' @export

guri_to_md <- function(path_art, art, verbose = F){

  cli_process_start(col_yellow("Creating markdown file (docx -> md)."))

  guri_convert(path_art = path_art, art = art,
               output = "md", verbose = verbose)

  cli_process_done()

  invisible(T)
}

#' @rdname guri_to_md
#'
#' @export

guri_to_html <- function(path_art, art, verbose = F){

  cli_process_start(col_yellow("Creating html file (md -> html)."))

  guri_convert(path_art = path_art, art = art,
               output = "html", verbose = verbose)

  cli_process_done()

  invisible(T)
}

#' @rdname guri_to_md
#'
#' @export

guri_to_jats <- function(path_art, art, verbose = F){

  cli_process_start(col_yellow("Creating xml-jats file (md -> xml)."))

  guri_convert(path_art = path_art, art = art,
               output = "jats", verbose = verbose)

  cli_process_done()

  invisible(T)
}

#' @rdname guri_to_md
#' @param pdf Logical. Should the pdf be generated? (default = TRUE)
#'
#' @export

guri_to_pdf <- function(path_art, art, verbose = F, pdf = TRUE){

  # Conversión md -> tex

  cli_process_start(col_yellow("Creating latex file (md -> tex)."))

  guri_convert(path_art = path_art, art = art,
               output = "tex", verbose = verbose)

  cli_process_done()

  # Conversión tex -> pdf

  wdir <- file.path(getwd(), path_art)
  file_tex    <- paste0(art, ".tex")

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
    cli_process_done()
  }

  invisible(T)
}

# Genera archivo con bibliografia (en biblatex o csljson)

#' @rdname guri_to_md
#'
#' @export

guri_to_AST <- function(path_art, art, verbose = F) {

  cli_process_start(col_yellow("Creating AST file (md -> native)."))

  guri_convert(path_art = path_art, art = art,
               output = "AST", verbose = verbose)

  cli_process_done()

  invisible(T)
}

#' @rdname guri_to_md
#'
#' @param bib_type description
#'
#' @export

guri_biblio <- function(path_art, art, bib_type = "csljson"){

  cli_process_start(col_yellow("Creating biblio file (md -> ", bib_type, ")."))

  # Archivos de entrada / salida
  file_input  <- paste0(art, ".docx")

  if(bib_type == "csljson"){
    file_out <- paste0(art, "_biblio.json")
  }else if(bib_type == "biblatex"){
    file_out <- paste0(art, "_biblio.bib")
  }else{
    ui_abort("'bib_type' argument must be 'biblatex' or 'csljson'.")
  }

  rmarkdown::pandoc_convert(wd = file.path(getwd(), path_art),
                            input = file_input,
                            from = "docx+citations",
                            output = file_out ,
                            to = bib_type)
  cli_process_done()

  invisible(T)
}

