# Armado de archivos base ------------------------------

  # GURI_listfiles() ----------------------------------------
  
  GURI_listfiles <- function(path_issue){
    
    if(!dir.exists(path_issue)){ 
      stop("No existe el directorio ", "\033[34m", path_issue, "\033[39m", "\n",
           "Cree el directorio con los artículos a maquetar.", 
           "Recuerde colocar una carpeta para artículo.")
    }
    
    art <- data.frame(art_path = list.dirs(path_issue)) |>
      filter(str_detect(art_path, paste0(path_issue, "art[0-9]{3}$"))) |> 
      mutate(art_id = str_remove(art_path, path_issue),
             art_path = paste0(art_path, "/"))
    
    files <- map(art$art_path, ~list.files(.x, all.files = T, recursive = T)) |> 
      map2_df(.y = art$art_id, ~GURI_filetype(.x, .y)) |> 
      mutate(across(starts_with("is_"), as.logical) )
    
    art <- cbind(art, files)
    
    return(art)
  }
  
  # GURI_filetype() -----------------------------------------
  
  GURI_filetype <- function(art_files, art_id){
    
    search1 <- c(".docx", ".yaml", "_biblio.json", "_credit.xlsx", 
                "_app[0-9]{2}.docx", "_notes.md")
    
    res1 <- map_lgl(search1, ~any(str_detect(art_files, paste0(art_id, .x) ))) |> 
      set_names(c("is_docx", "is_yaml", "is_biblio", "is_credit",
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
    
    # Crear "art[~]_biblio.json" vacío si no tiene bibliografía
    biblio <- paste0(art_path, art_pre, "_biblio.json")
    if(!file.exists(biblio)){
      write_file(x = "[]", file = biblio)
    }
    
    # Generar "art[~]_credit.csv "
    credit_xlsx <- paste0(art_path, art_pre, "_credit.xlsx")
    credit_csv  <- paste0(art_path, art_pre, "_credit.csv")
    
    if(file.exists(credit_xlsx)){
      read_xlsx(credit_xlsx) |> write.csv(credit_csv, row.names = F, na = "")
    }
  }
  
# Generar documentos finales ---------------------------   

  # GURI_to_md() --------------------------------------------------------------
  
  GURI_to_md <- function(path_art, art, verbose = F){
    
    wdir <- paste0(getwd(), path_art)
    file_input  <- paste0(art, ".docx")
    file_output <- paste0(art, ".md")
    
    config_path = "../../_config/"
    config_files = list.files(paste0(wdir, config_path))
    
    op_gral <- c( "-s",
                  "--extract-media=./",
                  "--wrap=none")
    
    op_filters <- paste0("--lua-filter=../../../files/filters/",
                         c("title", "credit", "unhighlight", "cross-references",
                           "md_include-float-files"),
                         ".lua")
    
    op_biblio <- c("--citeproc",
                   paste0("--bibliography=./", art, "_biblio.json"))
    
    # csl latex
    config_csl <- config_files[str_detect(config_files, ".*[.]csl$") ]
    
    if(length(config_csl) == 1){
      op_biblio <- c(op_biblio, paste0("--csl=", config_path, config_csl))
    }else if(length(conf_csl) > 1){
      stop("Existen múltiples archivos csl en 'root/_config/'")
    }else{
      cat("Se usará csl por defecto")
    }
    
    op_meta <- c(paste0("--metadata-file=./", art, ".yaml"), # artículo
                 "--metadata-file=../_issue.yaml",           # número
                 "--metadata-file=../../_journal.yaml")      # revista
    
    pandoc_convert(wd = wdir, 
                   input = file_input,
                   from = "docx+citations",
                   output = file_output, verbose = T,
                   to = "markdown+footnotes+citations+smart+grid_tables-implicit_figures+link_attributes",
                   options = c(op_gral, op_meta, 
                               op_filters, op_biblio)
    )
  }

  # GURI_to_html() --------------------------------------------------------------
  
  GURI_to_html <- function(path_art){
    
    wdir <- paste0(getwd(), path_art)
    file_input  <- paste0(art, ".md")
    file_output <- paste0(art, ".html")
    
    config_path = "../../_config/"
    config_files = list.files(paste0(wdir, config_path))
    
    op_gral <- c("--wrap=none", "-s", "-M lang=es-AR",
                 "-M link-citations=true", "-M ",
                 # "--mathml", #, "-V link-citations=true", 
                 # "--metadata-file=../../../files/pandoc/jats_metadata.yaml",
                 "--citeproc", "--reference-links=true",
                 "--template=../../../files/template/template_default.jats_publishing")
    
    op_filters <- paste0("--lua-filter=../../../files/filters/",
                         c("include-float-in-format",
                           "author-to-canonical"), ".lua" )
    
    # csl
    config_csl <- config_files[str_detect(config_files, ".*[.]csl$") ]
    if(length(config_csl) == 1){
      op_gral <- c(op_gral, paste0("--csl=", config_path, config_csl))
    }else if(length(conf_csl) > 1){
      stop("Existen múltiples archivos csl en 'root/_config/'")
    }else{
      cat("Se usará csl por defecto")
    }
    
    pandoc_convert(wd = paste0(getwd(), path_art),
                   input = "index.md",
                   from = "markdown",
                   output = "index.html",
                   to = "html",
                   options =  config_csl)
  }
  
  # GURI_to_jats() --------------------------------------------------------------

  GURI_to_jats <- function(path_art, art){
    
    wdir <- paste0(getwd(), path_art)
    file_input  <- paste0(art, ".md")
    file_output <- paste0(art, ".xml")
    
    config_path = "../../_config/"
    config_files = list.files(paste0(wdir, config_path))
    
    op_gral <- c("--wrap=none", "--mathml", #"-V lang=es", "-V link-citations=true", 
                 "--metadata-file=../../../files/pandoc/jats_metadata.yaml",
                  "--citeproc", "--reference-links=true",
                  "--template=../../../files/template/template_default.jats_publishing")
    
    op_filters <- paste0("--lua-filter=../../../files/filters/",
                         c("include-float-in-format",
                           "author-to-canonical"), 
                         ".lua" )
    
    pandoc_convert(wd = wdir, 
                   input = file_input,
                   from = "markdown", 
                   output = file_output,
                   to = "jats_publishing+element_citations",
                   options = c(op_filters, op_gral) )
  }

  # GURI_to_pdf() --------------------------------------------------------------
  
  GURI_to_pdf <- function(path_art, art, verbose = F, depure = F){
    
    proj_dir <- getwd()
    wdir <- paste0(proj_dir, path_art)
    setwd(wdir) 
    
    file_input  <- paste0(art, ".md")
    file_tex    <- paste0(art, ".tex")
    file_pdf    <- paste0(art, ".pdf")
    
    tinytex_warn <- options()$tinytex.latexmk.warning
    options(tinytex.latexmk.warning = verbose)
    
    # Opciones generales
    op_gral <- c( "-s", "--pdf-engine=lualatex" )
    
    # Filtros Lua
    op_filters <- paste0("--lua-filter=../../../files/filters/",
                         c("include-float-in-format",
                           "author-to-canonical",
                           "credit-before-bib", "latex-prepare"),
                         ".lua")
    
    op_biblio <- c("--citeproc")
    
    # Archivos de 'root_journal/_config'
    config_path = "../../_config/"
    config_files = list.files(paste0(wdir, config_path))
    
    # template
    config_latex_template <- config_files[str_detect(config_files, "^template.latex$") ]
    if(config_latex_template == "template.latex"){
      op_templ <- paste0("--template=", config_path, config_latex_template)
    }else{
      cat("No existe archivo 'root/_config/latex.template'.",
          "Se usará latex.template por defecto")
      op_templ <- paste0("--template=../../../files/template/", config_latex_template)
    }
    
    # latex metadata
    config_latex_meta <- config_files[str_detect(config_files, "^latex_metadata.yaml$") ]
    if(config_latex_meta == "latex_metadata.yaml"){
      op_meta <- paste0("--metadata-file=", config_path, config_latex_meta)
    }else{
      cat("No existe archivo 'root/_config/latex_metadata.yaml'.",
          "Se usará latex_metadata.yaml por defecto")
      op_meta <- paste0("--metadata-file=../../../files/pandoc/", config_latex_meta)
    }
    
    pandoc_convert(wd = "./", verbose = verbose,
                   input = file_input,
                   from = "markdown",
                   output = file_tex,
                   to = "latex",
                   options = c(op_gral, op_biblio, op_filters, 
                               op_templ, op_meta))
    
    lualatex(file_tex)
    
    # Volver a valores por defecto
    options(tinytex.latexmk.warning = tinytex_warn)
    setwd(proj_dir) 
    
  }
  
  # GURI_to_AST() -----------------------------------
  
  GURI_to_AST <- function(path_art, art) {
    
    wdir <- paste0(getwd(), path_art)
    file_input  <- paste0(art, ".md")
    file_json    <- paste0(art, "_AST.json")
    
    config_path = "../../_config/"
    config_files = list.files(paste0(wdir, config_path))
    
    op_gral <- c("--wrap=none", "--mathml", #"-V lang=es", "-V link-citations=true", 
                 "--metadata-file=../../../files/pandoc/jats_metadata.yaml",
                 "--citeproc", "--reference-links=true",
                 "--template=../../../files/template/template_default.jats_publishing")
    
    # Filtros Lua
    op_filters <- paste0("--lua-filter=../../../files/filters/",
                         c("include-float-in-format",
                           "author-to-canonical",
                           "credit-before-bib", "latex-prepare"),
                         ".lua")
    
    # csl
    config_csl <- config_files[str_detect(config_files, ".*[.]csl$") ]
    if(length(config_csl) == 1){
      op_gral <- c(op_gral, paste0("--csl=", config_path, config_csl))
    }else if(length(conf_csl) > 1){
      stop("Existen múltiples archivos csl en 'root/_config/'")
    }else{
      cat("Se usará csl por defecto")
    }
    
    # latex metadata
    config_latex_meta <- config_files[str_detect(config_files, "^latex_metadata.yaml$") ]
    if(config_latex_meta == "latex_metadata.yaml"){
      op_meta <- paste0("--metadata-file=", config_path, config_latex_meta)
    }else{
      cat("No existe archivo 'root/_config/latex_metadata.yaml'.",
          "Se usará latex_metadata.yaml por defecto")
      op_meta <- paste0("--metadata-file=../../../files/pandoc/", config_latex_meta)
    }
    
    pandoc_convert(wd = paste0(getwd(), path_art), 
                   input = file_input,
                   from = "markdown",
                   output = file_json,
                   to = "json",
                   options = c(op_gral, op_filters,  op_meta))
  }
  
  
  # GURI() ---------------------------------------------------- 
  
  GURI <- function(art_path, art_name, verbose = F){
    pandoc_req <- "3.1.8"
    if(!pandoc_version() >= pandoc_req){
      stop("Necesita actualizar su versión de Pandoc (se requiere ", 
           pandoc_req, " o posterior). Descargue la última versión",
           "en el sitio de Pandoc: https://github.com/jgm/pandoc/releases/latest")
    }
    
    cat("Artículo:", "\033[34m", art_name, "\033[39m", "\n")
    cat("\033[33m", "* Preparación de archivos.", "\033[39m")
    GURI_prepare(art_path, art_name)
    cat("DONE\n")
    cat("\033[33m", "* Crear archivo markdown (", art_name, ".md ).", "\033[39m")
    GURI_to_md(art_path, art_name, verbose = verbose)
    cat("DONE\n")
    if (verbose){
      cat("\033[33m", "* Crear AST (", art_name, "_AST.json ).", "\033[39m")
      GURI_to_AST(art_path, art_name)
      cat("DONE\n")
    }
    cat("\033[33m", "* Crear archivo jats-xml (", art_name, ".xml ).", "\033[39m")
    GURI_to_jats(art_path, art_name)
    cat("DONE\n")
    cat("\033[33m", "* Crear archivo latex (", art_name, ".tex ).",
        "y pdf (", art_name, "pdf ).", "\033[39m")
    GURI_to_pdf(art_path, art_name, verbose = verbose)
    cat("DONE\n")
  }
  
  