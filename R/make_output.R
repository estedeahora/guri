
# Generar documentos finales ---------------------------

# GURI_to_md() --------------------------------------------------------------

GURI_to_md <- function(path_art, art, verbose = F){

  wdir <- paste0(getwd(), path_art)

  # Archivos de entrada / salida
  file_input  <- paste0(art, ".docx")
  file_output <- paste0(art, ".md")

  # Archivos de programa ('./files/') y configuración de revista ('./JOURNAL/_config')
  program_path = "../../../files/"
  config_path = "../../_config/"
  config_files = list.files(paste0(wdir, config_path))

  # Opciones generales
  op_gral <- c( "-s", #"--log=./log_pandoc.log",
                "--extract-media=./",
                "--wrap=none")

  app_files <- GURI_appendix(wdir, art)
  if(length(app_files) > 0){
    app_files <- paste0("--metadata=appendix:", app_files)
  }else{
    app_files <- NULL
  }

  # Filtros Lua
  op_filters <- paste0("--lua-filter=", program_path, "filters/",
                       c("title",
                         "unhighlight",
                         "add-credit",
                         "metadata-div-before-bib",
                         "include-files",
                         "cross-references",
                         "translate-citation-elements",
                         "include-float-marks",
                         "author-to-canonical"),
                       ".lua")

  # Opciones de bibliografía
  op_biblio <- c()#c(paste0("--bibliography=./", art, "_biblio.json"))

  config_csl <- config_files[str_detect(config_files, ".*[.]csl$") ]

  if(length(config_csl) == 1){
    op_biblio <- c(op_biblio, paste0("--csl=", config_path, config_csl))
  }else if(length(conf_csl) > 1){
    stop("\nExisten múltiples archivos csl en 'root/_config/'")
  }else{
    cat("\nSe usará csl por defecto")
  }

  # Archivos de metadatos
  op_meta <- c(paste0("--metadata-file=./", art, ".yaml"), # artículo
               "--metadata-file=../_issue.yaml",           # número
               "--metadata-file=../../_journal.yaml")      # revista

  pandoc_convert(wd = wdir,
                 input = file_input,
                 from = "docx+citations",
                 output = file_output,
                 citeproc = T, verbose = verbose,
                 to = "markdown", # +footnotes+citations+smart+grid_tables-implicit_figures+link_attributes
                 options = c(op_gral, op_meta, app_files,
                             op_filters, op_biblio)
  )
}

# GURI_to_html() --------------------------------------------------------------

GURI_to_html <- function(path_art, art){

  wdir <- paste0(getwd(), path_art)

  # Archivos de entrada / salida
  file_input  <- paste0(art, ".md")
  file_output <- paste0(art, ".html")

  # Archivos de programa ('./files/') y configuración de revista ('./JOURNAL/_config')
  program_path = "../../../files/"
  config_path = "../../_config/"
  config_files = list.files(paste0(wdir, config_path))

  # Opciones generales
  op_gral <- c("--wrap=none", "-s", "--metadata=link-citations",
               #"-V link-citations=true",
               "--mathml",
               paste0("--template=", program_path, "template/template.html"),
               "--reference-links=true")

  # Filtros Lua
  op_filters <- paste0("--lua-filter=", program_path, "filters/",
                       c("include-float-in-format"),
                       ".lua" )

  pandoc_convert(wd = paste0(getwd(), path_art),
                 input = file_input,
                 from = "markdown",
                 output = file_output,
                 to = "html",
                 citeproc = T,
                 options =  c(op_gral, op_filters))
}

# GURI_to_jats() --------------------------------------------------------------

GURI_to_jats <- function(path_art, art){

  wdir <- paste0(getwd(), path_art)

  # Archivos de entrada / salida
  file_input  <- paste0(art, ".md")
  file_output <- paste0(art, ".xml")

  # Archivos de programa ('./files/') y configuración de revista ('./JOURNAL/_config')
  program_path = "../../../files/"
  config_path = "../../_config/"
  config_files = list.files(paste0(wdir, config_path))

  # Opciones generales
  op_gral <- c("--wrap=none", "--mathml", "--reference-links=true",
               paste0("--metadata-file=", program_path, "pandoc/jats_metadata.yaml"),
               paste0("--template=", program_path, "template/template_default.jats_publishing"))

  # Filtros Lua
  op_filters <- paste0("--lua-filter=", program_path, "filters/",
                       c("include-float-in-format",
                         "metadata-format-in-text"),
                       ".lua" )

  pandoc_convert(wd = wdir,
                 input = file_input,
                 from = "markdown",
                 output = file_output,
                 to = "jats_publishing+element_citations",
                 citeproc = T,
                 options = c(op_filters, op_gral) )
}

# GURI_to_pdf() --------------------------------------------------------------

GURI_to_pdf <- function(path_art, art, verbose = F){

  # Directorio de trabajo
  wdir <- paste0(getwd(), path_art)
  proj_dir <- setwd(wdir)
  on.exit(setwd(proj_dir), add = T)  # Volver a valores por defecto al salir

  # Archivos de entrada / salida
  file_input  <- paste0(art, ".md")
  file_tex    <- paste0(art, ".tex")
  file_pdf    <- paste0(art, ".pdf")

  # Archivos de programa ('./files/') y configuración de revista ('./JOURNAL/_config')
  program_path = "../../../files/"
  config_path = "../../_config/"
  config_files = list.files(paste0(wdir, config_path))

  # Retener warnings?
  # ### tinytex_warn <- options()$tinytex.latexmk.warning
  # tinytex_warn <- options(tinytex.latexmk.warning = verbose)
  # on.exit(options(tinytex.latexmk.warning = tinytex_warn))

  # Opciones generales
  op_gral <- c( "-s", "--pdf-engine=lualatex" )

  # Filtros Lua
  op_filters <- paste0("--lua-filter=", program_path, "filters/",
                       c("include-float-in-format",
                         "metadata-format-in-text",
                         "latex-prepare"),
                       ".lua")

  # Busca archivo de TEMPLATE customizado (en ./JOURNAL/_config/)
  config_latex_template <- config_files[str_detect(config_files, "^template.latex$") ]

  if(config_latex_template == "template.latex"){
    op_templ <- paste0("--template=", config_path, config_latex_template)
  }else{
    cat("No existe archivo 'root/_config/latex.template'.",
        "Se usará latex.template por defecto")
    op_templ <- paste0("--template=", program_path, "template/", config_latex_template)
  }

  # Busca archivo de METADATA customizado (en ./JOURNAL/_config/)
  config_latex_meta <- config_files[str_detect(config_files, "^latex_metadata.yaml$") ]

  if(config_latex_meta == "latex_metadata.yaml"){
    op_meta <- paste0("--metadata-file=", config_path, config_latex_meta)
  }else{
    cat("No existe archivo 'root/_config/latex_metadata.yaml'.",
        "Se usará latex_metadata.yaml por defecto")
    op_meta <- paste0("--metadata-file=", program_path, "pandoc/", config_latex_meta)
  }

  # Conversión md -> tex
  pandoc_convert(wd = "./",
                 input = file_input,
                 from = "markdown",
                 output = file_tex,
                 to = "latex",
                 citeproc = T,
                 verbose = verbose,
                 options = c(op_gral, op_filters,
                             op_templ, op_meta))

  # Conversión tex -> pdf
  lualatex(file_tex)

}
