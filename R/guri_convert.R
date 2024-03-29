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
# verbose <- T
# output <- "md"

# TODO
#   [x] General options
#   [x] Lua Filters
#   [x] Appendix (md)
#   [x] Bibliography (md)
#   [-] Templates (pdf y html)
#   [-] Metadata (md y pdf)

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
  config_path  <- file.path(wdir, "..", "..", "_config"  )
  config_files <- list.files(config_path)

  # General options
  opt_gral <- pandoc_options$opts[c("option", output)]
  opt_gral <- opt_gral$option[order(opt_gral$md) & !is.na(opt_gral$md)]

  opt_gral <- c(opt_gral, paste0("--metadata=config_path:", file.path(program_path, "filters")))

  # Lua Filters
  opt_filters <- pandoc_options$lua[c("filter", output)]                            # select pandoc options
  opt_filters <- opt_filters$filter[order(opt_filters$md) & !is.na(opt_filters$md)] # filter NA and order filters
  if(verbose){
    ui_alert_info("Internal lua filters used: ", paste(col_blue(opt_filters), collapse = "; "), ".")
  }
  opt_filters <- file.path(program_path, "filters", opt_filters)                    # make path to internal program filters
  opt_filters <- paste0("--lua-filter=", opt_filters, ".lua")                       # add pandoc flags and lua extension

  # Customised filters
  customised_filters <- config_files[stringr::str_detect(config_files, paste0(output, "_[0-9]_.+\\.lua$"))]
  if(verbose & length(customised_filters) > 0){
    ui_alert_info("Customized lua filters used: ", paste(col_blue(customised_filters), collapse = "; "), ".")
  }
  customised_filters <- file.path(config_path, sort(customised_filters))

  opt_filters <- c(opt_filters, customised_filters)

  # Appendix (Only in docx -> md)
  app_files <- NULL

  if(!is.na(opt_type[["appendix"]])) {
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

  if(!is.na(opt_type[["biblio"]])) {

    config_csl <- config_files[stringr::str_detect(config_files, ".*\\.csl$") ]

    if(length(config_csl) == 1){
      opt_biblio <- c(op_biblio, paste0("--csl=", file.path(config_path, config_csl) ))
      if(verbose){
        ui_alert_info("Citation style used: {.path ", config_csl, "}.")
      }
    }else if(length(config_csl) > 1){
      ui_abort("There are multiple 'csl' files in {.path 'JOURNAL/_config/'}. Only one csl file should be provided.")
    }else{
      ui_alert_info("Default csl is used. See: {.url https://pandoc.org/chunkedhtml-demo/9.2-specifying-a-citation-style.html}")
    }
  }

  # Templates (Only in md -> tex/html)
  opt_templ <- NULL

  if(!is.na(opt_type[["template"]])) {

    template_file <- paste0("template.",  opt_type[["template"]])

    config_template <- config_files[config_files ==  template_file]

    if(config_template == "template.latex"){
      opt_templ <- paste0("--template=", config_path, config_latex_template)
    }else{
      if(verbose){
        ui_alert_info("Default ", opt_type["to"],  " template is used.")
      }
      cat("No existe archivo 'root/_config/latex.template'.",
          "Se usará latex.template por defecto")
      opt_templ <- paste0("--template=", program_path, "template/", config_latex_template)
    }
  }

  # Metadata files
  opt_meta <- NULL

  if(output == "md"){

    metadata_files <- c(art = file.path(paste0(art, ".yaml")),              # article
                        issue = file.path("..", "_issue.yaml"),             # issue
                        journal = file.path("..", "..", "_journal.yaml"))   # journal

    metadata_exist <- file.exists(file.path(wdir, metadata_files) )

    if(any(!metadata_exist)){
      ui_abort("Configuration file is not present. Missing: {.path ",
               metadata_files[!metadata_exist], "}" )
    }

    opt_meta <- paste0("--metadata-file=", metadata_files)

  }else if(!is.na(opt_type[["metadata"]])){

    # TODO TEX/HTML

  }

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

