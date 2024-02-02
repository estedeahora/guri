# Load Packages

library(tidyverse)
library(rmarkdown)
library(readxl)
library(tinytex)
library(crayon)

# GURI_install -----------------------------------------------
# Actualiza paquetes y distribución latex necesaria para el funcionamiento de GURI 

GURI_install <- function(install_tinytex = T){
  
  dep <- c("tidyverse", "rmarkdown", "readxl", "tinytex", "crayon")
  pkg <- .packages(all.available = TRUE)
  
  dep_needed <- dep [!dep %in% pkg]
  
  if(length(dep_needed) > 0){
    cat("\n", "Instalando paquetes R faltantes:", 
        paste0(dep_needed, collapse = ", ") )
    install.packages(dep_needed)
  }else{
    cat("\n", "Paquetes R necesarios presentes") 
  }
  
  # Instalación de distribución tinytex y paquetes sugeridos
  if(install_tinytex){
    if(!tinytex::is_tinytex()){
      
      cat("\n", "Instalando la distribución de latex tinytex\n")
      tinytex::install_tinytex()
      
    }else{
      cat("\n", "Actualizando la distribución de latex tinytex\n")
      # latex_version <- tinytex::tlmgr_version()
      tinytex::tlmgr_update()
    }
    
    latex_pkg <- c("amsmath", "amsfonts", "lm", "unicode-math", "iftex", "listings", 
                   "fancyvrb", "booktabs", "hyperref", "xcolor", "soul", "geometry", 
                   "setspace", "babel", "fontspec", "selnolig", "mathspec", "biblatex",
                   "bibtex", "upquote", "microtype", "csquotes", "natbib", 
                   "bookmark", "xurl", "parskip", "svg", "geometry", "multirow", 
                   "etoolbox", "luacolor",  "lua-ul", 
                   "adjustbox", "fontawesome5", "caption",  "ccicons",
                   "relsize", "koma-script", "truncate", "lastpage"
                   # "amssymb", "longtable", "graphicx", "xecjk", "footnotehyper",
                   # "footnote", "fontenc", "inputenc", "textcomp", "luatexja-preset",
                   # "array", "calc", "xeCJKfntef", "subcaption"
    )
    
    
    cat("\n", "Comprobando paquetes latex necesarios")
    latex_pkg_installed <- lapply(latex_pkg, tinytex::check_installed)  |> 
      as.logical()
    
    if(sum(!latex_pkg_installed) > 0){
      cat("\n", "Instalando paquetes latex necesarios", "\n")
      tinytex::tlmgr_install(paste0(latex_pkg[!latex_pkg_installed], ".sty"))
    }
  }
  
}

# GURI_make_journal -----------------------------------------------

GURI_make_journal <- function(journal, issue_prefix = "num", issue_first = 1){
  
  journal_folder <- paste0("./", journal)
  if(dir.exists(journal_folder)){
    stop("The journal name already exists. To create a new journal, choose a new journal name.")
  }
  
  cat("* Create journal folder (", journal_folder, ").\n", sep = "")
  dir.create(journal_folder)
  
  
  cat("* Copy config files.\n", sep = "")
  file.copy(from = "files/_config-files/_config/",
            to = journal_folder, recursive = T)
  
  cat("* Copy default files files.\n", sep = "")
  file.copy(from = "files/_config-files/_default-files/",
            to = journal_folder, recursive = T)
  
  cat("* Copy _journal.yaml file (edit manually with the journal data).\n")
  file.copy(from = "files/_config-files/_journal.yaml",
            to = paste0(journal_folder, "/_journal.yaml"))
  file.edit(paste0(journal_folder, "/_journal.yaml"))
  
  script_path <- paste0("scripts/GURI_", journal, ".R")
  cat("* Create journal script (", paste0(script_path), ")\n", sep = "")
  
  file.copy(from = "scripts/GURI_01_make-files.R",
            to = script_path)
  iocon <- file(script_path,"r+")
  script <- readLines(iocon)
  
  # Modificar variable journal
  script <- map_chr(script, 
                    \(x) {str_replace(x, '^journal <- "example"', 
                                      paste0('journal <- "', journal, '"'))})
  # Modificar variable prefix
  script <- map_chr(script, 
                    \(x) {str_replace(x, '^prefix <- "num"', 
                                      paste0('prefix <- "', issue_prefix, '"'))})
  # Modificar primer issue
  script <- map_chr(script, 
                    \(x) {str_replace(x, '^issue <- 1', 
                                      paste0('issue <- ', issue_first))})
  
  writeLines(script, con=iocon)
  close(iocon)
  
  file.edit(script_path)
}
  
# Armado de archivos base ------------------------------

  # GURI_listfiles() ----------------------------------------
  
  GURI_listfiles <- function(path_issue){
    
    if(!dir.exists(path_issue)){ 
      stop("No existe el directorio ", "\033[34m", path_issue, "\033[39m", "\n",
           "Cree el directorio con los artículos a maquetar.", 
           "Recuerde colocar una carpeta para artículo.")
    }
    
    art <- data.frame(art_path = list.dirs(path_issue, recursive = F)) |>
      filter(str_detect(art_path, paste0(path_issue, "art[0-9]{3}.*"), negate = F)
               ) |> 
      mutate(#g = str_detect(art_path, paste0(path_issue, "art[0-9]{3}_*.*?/")),
             art_id = str_remove(art_path, path_issue),
             art_id = str_remove(art_id, "_.*$"),
             art_path = paste0(art_path, "/"))
    
    files <- map(art$art_path, ~list.files(.x, all.files = T, recursive = T)) |> 
      map2_df(.y = art$art_id, ~GURI_filetype(.x, .y)) |> 
      mutate(across(starts_with("is_"), as.logical) )
    
    art <- cbind(art, files)
    
    return(art)
  }
  
  # GURI_filetype() -----------------------------------------
  
  GURI_filetype <- function(art_files, art_id){
    
    search1 <- c(".docx", ".yaml", "_credit.xlsx", # "_biblio.json",
                "_app[0-9]{2}.docx", "_notes.md")
    
    res1 <- map_lgl(search1, ~any(str_detect(art_files, paste0(art_id, .x) ))) |> 
      set_names(c("is_docx", "is_yaml", "is_credit", # "is_biblio", 
                  "is_appendix", "is_notes"))
    
    # bib <- art_files[str_detect(art_files, paste0(art_id, "_biblio.json"))]
    # print(read.delim(paste0(path_issue, bib)))
    
    search2 <- c("float/TAB_[0-9]{2}.xlsx+", "float/FIG_[0-9]{2}.+")
    
    res2 <- map_int(search2, ~sum(str_detect(art_files, .x ))) |> 
      set_names(c("float_tab", "float_fig"))

    return(c(res1, res2))
  }

  # GURI_prepare() ---------------------------------------
  
  GURI_prepare <- function(art_path, art_pre){
    
    # # Crear "art[~]_biblio.json" vacío si no tiene bibliografía
    # biblio <- paste0(art_path, art_pre, "_biblio.json")
    # if(!file.exists(biblio)){
    #   write_file(x = "[]", file = biblio)
    # }
    
    # Generar "art[~]_credit.csv "
    credit_xlsx <- paste0(art_path, art_pre, "_credit.xlsx")
    credit_csv  <- paste0(art_path, art_pre, "_credit.csv")
    
    if(file.exists(credit_xlsx)){
      read_xlsx(credit_xlsx) |> write.csv(credit_csv, row.names = F, na = "")
    }
  }
  
  
  # GURI_appendix() ------------------------------------------
  # Transformación de archivos de anexos docx -> md
  # Devuelve el listado de archivos para anexos
  
  GURI_appendix <- function(wdir, art){
    appendix_files <-  list.files(wdir, pattern = paste0(art, "_app[0-9]*\\.docx"))
  
    walk(appendix_files,
        \(file){
          pandoc_convert(wd = wdir,
                         input = file,
                         from = "docx+citations",
                         output = str_replace(file, "docx", "md") ,
                         citeproc = T,
                         to = "markdown")}
    )
    
    return(str_replace(appendix_files, "docx", "md"))
  }
  
  
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
    proj_dir <- getwd()
    wdir <- paste0(proj_dir, path_art)
    setwd(wdir) 
    
    # Archivos de entrada / salida
    file_input  <- paste0(art, ".md")
    file_tex    <- paste0(art, ".tex")
    file_pdf    <- paste0(art, ".pdf")
    
    # Archivos de programa ('./files/') y configuración de revista ('./JOURNAL/_config')
    program_path = "../../../files/"
    config_path = "../../_config/"
    config_files = list.files(paste0(wdir, config_path))
    
    # Retener warnings?
    # tinytex_warn <- options()$tinytex.latexmk.warning
    # options(tinytex.latexmk.warning = verbose)
    
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
    
    # Volver a valores por defecto
    setwd(proj_dir) 
    # options(tinytex.latexmk.warning = tinytex_warn)
    
  }
  
# Funciones auxiliares --------------------
  # GURI_to_AST() -----------------------------------
  # Genera archivo con estructura AST
  
  GURI_to_AST <- function(path_art, art) {
    
    wdir <- paste0(getwd(), path_art)
    
    # Archivos de entrada / salida
    file_input  <- paste0(art, ".md")
    file_json    <- paste0(art, "_AST.json")
    
    # Archivos de programa ('./files/')
    program_path = "../../../files/"
    
    # Opciones generales
    op_gral <- c("--wrap=none", "--mathml", 
                 "--metadata=link-citations",
                 "--reference-links=true")
    
    # Filtros Lua
    op_filters <- paste0("--lua-filter=",  program_path, "filters/",
                         c("include-float-in-format",
                           "metadata-format-in-text"),
                         ".lua")
    
    pandoc_convert(wd = wdir, 
                   input = file_input,
                   from = "markdown",
                   output = file_json,
                   to = "json",
                   citeproc = T,
                   options = c(op_gral, op_filters))
  }
  
  # GURI_biblio() ----------------------------------
  # Genera archivo con bibliografía (en biblatex o csljson)
  
  GURI_biblio <- function(path_art, art, bib_type = "csljson"){
    
    wdir <- paste0(getwd(), path_art)
    
    # Archivos de entrada / salida
    file_input  <- paste0(art, ".docx")
    
    if(bib_type == "csljson"){
      file_out <- paste0(art, "_biblio.json")
    }else if(bib_type == "biblatex"){
      file_out <- paste0(art, "_biblio.bib")
    }else{
      stop("'bib_type' debe ser 'biblatex' o 'csljson'")
    }
    
    pandoc_convert(wd = wdir,
                   input = file_input,
                   from = "docx+citations",
                   output = file_out ,
                   to = bib_type)
    
  }
  
  # GURI_zip_input() ----------------------------------------------------------

  GURI_zip_input <- function(id_art){
    
    work_files <- paste0(paste0(id_art, c(".docx", #"_biblio.json", 
                                          "_notes.md", ".yaml", 
                                          "_credit.xlsx") ))
    float_dir <- paste0("float")
    if(dir.exists(float_dir) ){
      work_files <- c(work_files, float_dir)
    }
    
    zip_file <- paste0(id_art, "_", format(today(), "%Y.%m.%d"), ".zip")
    
    zip(zipfile = zip_file, files = work_files)
    
  }
  
  
  # GURI_clean_temp() -------------------------------------------
  
  GURI_clean_temp <- function(id_art){
    
    if(!dir.exists("./_temp")){
      dir.create("./_temp")
    }
    archivos <- list.files(".")
    patron <- paste0(id_art, c("\\.tex", "_AST\\.json", "\\.md", 
                               "_app[0-9]\\.md", "_credit\\.csv",
                               "_biblio\\.((json)|(bib))"
                               )) |> 
      paste0(collapse = "|")
    archivos <- archivos[str_detect(archivos, patron)]

    walk2(archivos, paste0("./_temp/", archivos), 
          file.rename)
    
  }
  
  # GURI_output() -------------------------------------------
  
  GURI_output <- function(id_art){
    
    if(!dir.exists("./_output")){
      dir.create("./_output")
    }
    
    archivos <- paste0(id_art, c(".pdf", ".xml", ".html"))
    
    walk2(archivos, paste0("./_output/", archivos), 
          file.rename)
    
  }
  
# GURI() ---------------------------------------------------- 
  
  GURI <- function(art_path, art_name, verbose = F, 
                   zip_file = F, clean_files = T){
    
    pandoc_req <- "3.1.10"
    if(!pandoc_version() >= pandoc_req){
      stop("Necesita actualizar su versión de Pandoc (se requiere ", 
           pandoc_req, " o posterior). Descargue la última versión",
           "en el sitio de Pandoc: https://github.com/jgm/pandoc/releases/latest")
    }
    
    # Preprar archivos
    cat("Artículo:", "\033[34m", art_name, "\033[39m", "\n")
    cat("\033[33m", "* Preparación de archivos.", "\033[39m")
    GURI_prepare(art_path, art_name)
    cat("DONE\n")
    
    # Convert files
    # docx -> md
    cat("\033[33m", "* Crear archivo markdown (", art_name, ".md ).", "\033[39m")
    GURI_to_md(art_path, art_name, verbose = verbose)
    cat("DONE\n")
    # docx -> biblio
    cat("\033[33m", "* Crear archivo de bibliografía (", art_name, "_biblio).", "\033[39m")
    GURI_biblio(art_path, art_name)
    cat("DONE\n")
    # md -> AST
    cat("\033[33m", "* Crear AST (", art_name, "_AST.json ).", "\033[39m")
    GURI_to_AST(art_path, art_name)
    cat("DONE\n")
    # md -> jats
    cat("\033[33m", "* Crear archivo jats-xml (", art_name, ".xml ).", "\033[39m")
    GURI_to_jats(art_path, art_name)
    cat("DONE\n")
    # md -> html
    cat("\033[33m", "* Crear archivo html (", art_name, ".html ).", "\033[39m")
    GURI_to_html(art_path, art_name)
    cat("DONE\n")
    # md -> tex + pdf
    cat("\033[33m", "* Crear archivo latex (", art_name, ".tex ).",
        "y pdf (", art_name, "pdf ).", "\033[39m")
    GURI_to_pdf(art_path, art_name, verbose = verbose)
    cat("DONE\n")
    
    # File reorganization
    wd_orig <- getwd()
    setwd(art_path)
    
    # Zip file
    if(zip_file){
      cat("\033[33m", "* Crear zip con archivos usados como entrada", "\033[39m")
      GURI_zip_input(art_name)
      cat("DONE\n")
    }
    # Clean files
    if(clean_files){
      cat("\033[33m", "* Mover archivos temporales a './_temp/'", "\033[39m")
      GURI_clean_temp(art_name)
      cat("DONE\n")
      cat("\033[33m", "* Mover archivos finales a './_output/'", "\033[39m")
      GURI_output(art_name)
      cat("DONE\n")
    }
    setwd(wd_orig)
  }
  
  