#' Converts the corrected manuscript in docx format to markdown format.
#'
#' @inheritParams guri_convert
#'
#' @return Invisible
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
    cli_process_start(col_yellow("Creating pdf file (md -> pdf)."))
    tinytex::lualatex(file_tex)
    cli_process_done()
  }

  invisible(T)

}

#' Genera archivo con bibliografia (en biblatex o csljson)
#'
#' @rdname guri_to_md

guri_to_AST <- function(path_art, art, verbose = F) {

  wdir <- paste0(getwd(), path_art)

  # Archivos de entrada / salida
  file_input  <- paste0(art, ".md")
  file_json    <- paste0(art, "_AST.json")

  # Archivos de programa ('./files/')
  program_path = "../../../files/"

  # Opciones generales
  op_gral <- c("--wrap=none", "--metadata=link-citations",
               "--mathml",
               "--reference-links=true")

  # Filtros Lua
  op_filters <- paste0("--lua-filter=",  program_path, "filters/",
                       c("include-float-in-format",
                         "metadata-format-in-text"),
                       ".lua")

  rmarkdown::pandoc_convert(wd = wdir,
                            input = file_input,
                            from = "markdown",
                            output = file_json,
                            to = "json",
                            citeproc = T,
                            options = c(op_gral, op_filters))
}

#' Genera archivo con bibliografia (en biblatex o csljson)
#'
#' @rdname guri_to_md
#'
#' @param bib_type description

guri_biblio <- function(path_art, art, verbose = F, bib_type = "csljson"){

  wdir <- paste0(getwd(), path_art)

  # Archivos de entrada / salida
  file_input  <- paste0(art, ".docx")

  if(bib_type == "csljson"){
    file_out <- paste0(art, "_biblio.json")
  }else if(bib_type == "biblatex"){
    file_out <- paste0(art, "_biblio.bib")
  }else{
    ui_abort("'bib_type' debe ser 'biblatex' o 'csljson'")
  }

  rmarkdown::pandoc_convert(wd = wdir,
                            input = file_input,
                            from = "docx+citations",
                            output = file_out ,
                            to = bib_type)

}

