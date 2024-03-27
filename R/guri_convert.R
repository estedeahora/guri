#' Converts the corrected manuscript between the formats required by `~!guri_`.
#'
#' @param path_art A string with the path to the article directory
#' @param art A string with the article id.
#' @param verbose Logical
#' @param output String
#'
#' @return Invisible

# path_art <- "./example/num1/art101_lorem-ipsum"
# art <- "art101"
# verbose <- F
# output <- "md"

guri_convert <- function(path_art, art,
                         output,
                         verbose = F){

  # Working directory
  wdir <- file.path(getwd(), path_art)

  # Input / output file names.
  opt_type <- pandoc_options$type[[output]]
  names(opt_type) <- pandoc_options$type[["type"]]

  file_input  <- paste(art, opt_type["file_ext_input"], sep = ".")
  file_output <- paste(art, opt_type["file_ext_output"], sep = ".")

  # Geth paths: Program files ('GURI/inst/') and customised journal configuration files ('./JOURNAL/_config').
  program_path <- pkg_file()
  config_files <- list.files(file.path(wdir, "..", "..", "_config"))

  # TODO Revisar. Se deja para check()
  config_path  <-file.path("..", "..", "_config"  )


  # TODO
  #   [x] General options
  #   [x] Lua Filters
  #   [-] Appendix (md)
  #   [-] Bibliography (md)
  #   [ ] Templates (pdf y html)
  #   [ ] Metadata (md y pdf)

  # General options
  opt_gral <- pandoc_options$opts[c("option", output)]
  opt_gral <- opt_gral$option[order(opt_gral$md) & !is.na(opt_gral$md)]

  # Lua Filters
  opt_filters <- pandoc_options$lua[c("filter", output)]                            # select pandoc options
  opt_filters <- opt_filters$filter[order(opt_filters$md) & !is.na(opt_filters$md)] # filter NA and order filters
  if(verbose){
    ui_alert_info("Internal lua filters used: ", paste(col_blue(opt_filters), collapse = "; "), ".")
  }
  opt_filters <- file.path(program_path, "filters", opt_filters)                    # make path to internal program filters
  opt_filters <- paste0("--lua-filter=", opt_filters, ".lua")                       # add pandoc flags and lua extension

  # TODO Agregar filtros personalizados
  # config_files[stringr::str_detect(config_files, paste0(output, "_.+\\.lua$"))]

  # Appendix (Only in docx -> md)
  app_files <- NULL

  if(!is.na(opt_type["appendix"])) {
    app_files <- guri_appendix(wdir, art)
    if(length(app_files) > 0){
      if(verbose){
        ui_alert_info(length(app_files), " appendices are added.")
      }
      app_files <- paste0("--metadata=appendix:", app_files)
    }
  }

  # Bibliography options (Only in docx -> md)
  opt_biblio <- NULL

  if(!is.na(opt_type["biblio"])) {

    config_csl <- config_files[stringr::str_detect(config_files, ".*\\.csl$") ]

    if(length(config_csl) == 1){
      op_biblio <- c(op_biblio, paste0("--csl=", config_path, config_csl))
    }else if(length(config_csl) > 1){
      ui_abort("There are multiple 'csl' files in {.path 'JOURNAL/_config/'}. Only one csl file should be provided.")
    }else{
      ui_alert_info("Default csl is used. See: {.url https://pandoc.org/chunkedhtml-demo/9.2-specifying-a-citation-style.html}")
    }
  }

  # Metadata files
  opt_meta <- c(paste0("--metadata-file=./", art, ".yaml"), # artículo
                "--metadata-file=../_issue.yaml",           # número
                "--metadata-file=../../_journal.yaml")      # revista
  # }else{
  #   app_files <- NULL
  #   op_meta <- NULL
  #   op_biblio <- NULL
  # }

  rmarkdown::pandoc_convert(wd = wdir,
                            input = file_input,
                            from = opt_type["from"],
                            output = file_output,
                            to = opt_type["to"],
                            citeproc = T,
                            verbose = verbose,
                            options = c(opt_gral, opt_meta, app_files,
                                        opt_filters, opt_biblio)
  )

}



# op_gral
# ------*
#
# docx -> Markdown
# op_gral <- c( "-s", "--wrap=none", #"--log=./log_pandoc.log",
#               "--extract-media=./"
#               )
#
# Markdown -> HTML
# op_gral <- c( "-s", "--wrap=none", "--metadata=link-citations",
#              "--mathml", "--reference-links=true",
#              paste0("--template=", program_path, "template/template.html"))
#
# Markdown -> JATS
# op_gral <- c("--wrap=none", "--mathml", "--reference-links=true",
#              paste0("--metadata-file=", program_path, "pandoc/jats_metadata.yaml"),
#              paste0("--template=", program_path, "template/template_default.jats_publishing"))
#
# Markdown -> tex
# op_gral <- c( "-s", "--pdf-engine=lualatex" )



