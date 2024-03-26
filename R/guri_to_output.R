#' Converts the corrected manuscript in docx format to markdown format.
#'
#' @inheritParams guri_convert
#'
#' @return Invisible
#'
#' @export

guri_to_md <- function(path_art, art, verbose = F){

  guri_convert(path_art = path_art, art = art,
               output = "md", verbose = verbose)

  invisible(T)
}

#' @rdname guri_to_md
#'
#' @export

guri_to_html <- function(path_art, art, verbose = F){

  guri_convert(path_art = path_art, art = art,
               output = "html", verbose = verbose)

}

#' @rdname guri_to_md
#'
#' @export

guri_to_jats <- function(path_art, art, verbose = F){

  guri_convert(path_art = path_art, art = art,
               output = "jats", verbose = verbose)

}

#' @rdname guri_to_md
#'
#' @export

guri_to_pdf <- function(path_art, art, verbose = F){

  # Directorio de trabajo
  wdir <- paste0(getwd(), path_art)
  proj_dir <- setwd(wdir)
  on.exit(setwd(proj_dir), add = T)  # Volver a valores por defecto al salir

  # # Archivos de entrada / salida
  # file_input  <- paste0(art, ".md")
  file_tex    <- paste0(art, ".tex")
  file_pdf    <- paste0(art, ".pdf")

  # # Archivos de programa ('./files/') y configuracion de revista ('./JOURNAL/_config')
  program_path = "../../../files/"
  config_path = "../../_config/"
  config_files = list.files(paste0(wdir, config_path))

  # Retener warnings?
  # ### tinytex_warn <- options()$tinytex.latexmk.warning
  tinytex_warn <- options(tinytex.latexmk.warning = verbose)
  on.exit(options(tinytex.latexmk.warning = tinytex_warn))

  # # Opciones generales
  # op_gral <- c( "-s", "--pdf-engine=lualatex" )
  #
  # # Filtros Lua
  # op_filters <- paste0("--lua-filter=", program_path, "filters/",
  #                      c("include-float-in-format",
  #                        "metadata-format-in-text",
  #                        "latex-prepare"),
  #                      ".lua")

  # Busca archivo de TEMPLATE customizado (en ./JOURNAL/_config/)
  config_latex_template <- config_files[stringr::str_detect(config_files, "^template.latex$") ]

  if(config_latex_template == "template.latex"){
    op_templ <- paste0("--template=", config_path, config_latex_template)
  }else{
    cat("No existe archivo 'root/_config/latex.template'.",
        "Se usara latex.template por defecto")
    op_templ <- paste0("--template=", program_path, "template/", config_latex_template)
  }

  # Busca archivo de METADATA customizado (en ./JOURNAL/_config/)
  config_latex_meta <- config_files[stringr::str_detect(config_files, "^latex_metadata.yaml$") ]

  if(config_latex_meta == "latex_metadata.yaml"){
    op_meta <- paste0("--metadata-file=", config_path, config_latex_meta)
  }else{
    cat("No existe archivo 'root/_config/latex_metadata.yaml'.",
        "Se usara latex_metadata.yaml por defecto")
    op_meta <- paste0("--metadata-file=", program_path, "pandoc/", config_latex_meta)
  }

  # # Conversión md -> tex
  # pandoc_convert(wd = "./",
  #                input = file_input,
  #                from = "markdown",
  #                output = file_tex,
  #                to = "latex",
  #                citeproc = T,
  #                verbose = verbose,
  #                options = c(op_gral, op_filters,
  #                            op_templ, op_meta))

  # Conversión tex -> pdf
  tinytex::lualatex(file_tex)

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
    cli_abort("'bib_type' debe ser 'biblatex' o 'csljson'")
  }

  rmarkdown::pandoc_convert(wd = wdir,
                            input = file_input,
                            from = "docx+citations",
                            output = file_out ,
                            to = bib_type)

}

