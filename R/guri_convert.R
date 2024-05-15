#' Converts the corrected manuscript between the formats required by `~!guri_`.
#'
#'
#' @param path_art A string with the path to the article directory
#' @param art A string with the article id.
#' @param verbose Logical. Specifies whether to display verbose output.
#' @param output A string. The desired output format (see ).
#'
#' @description
#' This function converts a document using `~!guri_`. It takes the path to the
#' article, the article id, the desired output format, and an optional verbose
#' flag. It performs the conversion by calling the [rmarkdown::pandoc_convert]
#' function.
#'
#' @return Invisible TRUE

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
  config_path  <- fs::path_abs( file.path(wdir, "..", "..", "_config"  ) )
  config_files <- list.files(config_path)

  # General options
  opt_gral <- pandoc_options$opts[c("option", output)]
  opt_gral <- opt_gral$option[order(opt_gral[[output]]) & !is.na(opt_gral[[output]])]

  opt_gral <- c(opt_gral,
                paste0("--metadata=config_path:", file.path(program_path, "filters")),
                paste0("--metadata=GURI_VERSION:", guri_version))

  if(verbose){
    opt_gral <- c(opt_gral, paste0("--log=log-", output, ".log"))
  }

  # Lua Filters
  opt_filters <- pandoc_options$lua[c("filter", output)]                            # select pandoc options
  opt_filters <- opt_filters$filter[order(opt_filters[[output]]) & !is.na(opt_filters[[output]])] # filter NA and order filters
  if(length(opt_filters) > 0 ){
    if(verbose){
      ui_alert_info("Internal lua filters used: ", paste(col_blue(opt_filters), collapse = "; "), ".")
    }
    opt_filters <- file.path(program_path, "filters", opt_filters)                    # make path to internal program filters
    opt_filters <- paste0("--lua-filter=", opt_filters, ".lua")                       # add pandoc flags and lua extension
  }

  # Customised filters
  customised_filters <- stringr::str_extract(config_files, paste0("^", output, "_[0-9]{1,2}_.+\\.lua$"))  |> stats::na.omit()
  if(length(customised_filters) > 0){
    if(verbose){
      ui_alert_info("Customized lua filters used: ", paste(col_blue(customised_filters), collapse = "; "), ".")
    }
    customised_filters <- file.path(config_path, sort(customised_filters))
    customised_filters <- paste0("--lua-filter=", customised_filters)
  }

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

    config_csl <- stringr::str_extract(config_files, ".*\\.csl$") |> stats::na.omit()

    if(length(config_csl) == 1){
      opt_biblio <- c(opt_biblio, paste0("--csl=", file.path(config_path, config_csl) ))
      if(verbose){
        ui_alert_info("Citation style used: {.path ", config_csl, "}.")
      }
    }else if(length(config_csl) > 1){
      ui_abort("There are multiple 'csl' files in {.path 'JOURNAL/_config/'}. Only one csl file should be provided.")
    }else{
      ui_alert_info("Default csl is used. See: {.url https://pandoc.org/chunkedhtml-demo/9.2-specifying-a-citation-style.html}")
    }
  }

  # Templates (Only in md -> tex/html/jats)
  opt_templ <- NULL

  if(!is.na(opt_type[["template"]])) {

    template_file <- paste0("template.",  opt_type[["template"]])

    # Detects: (a) if customizable; + (b) if custom template exists in '_config'
    if(!is.na(opt_type[["custom"]]) && any(stringr::str_detect(config_files, paste0("^", template_file, "$")))){
      opt_templ <- paste0("--template=", file.path(config_path, template_file))

      if(verbose){
        ui_alert_info("Customised template is used ({.path ",
                      "JOURNAL/_config/", template_file,"}).")
      }
    # Default template is used
    }else{
      if(verbose && !is.na(opt_type[["custom"]])){
        ui_alert_info("No custom template file exists in {.path 'JORUNAL/_config/'}. ",
                      "Default ", opt_type["template"], " template is used.")
      }
      opt_templ <- paste0("--template=", file.path(program_path, "template", template_file))
    }
  }

  # Metadata files
  opt_meta <- NULL

  if(output == "md"){

    metadata_files <- c(article = file.path(paste0(art, ".yaml")),          # article
                        issue = file.path("..", "_issue.yaml"),             # issue
                        journal = file.path("..", "..", "_journal.yaml"))   # journal

    metadata_files <- fs::path_abs(file.path(wdir, metadata_files))
    metadata_exist <- file.exists(metadata_files)

    if(any(!metadata_exist)){
      ui_abort("Configuration file is not present. Missing: {.path ",
               metadata_files[!metadata_exist], "}" )
    }

    opt_meta <- paste0("--metadata-file=", metadata_files)

  }else if(!is.na(opt_type[["metadata"]]) ){

    metadata_file <- paste0(opt_type[["metadata"]], "_metadata.yaml")

    # Detects: (a) if customizable; + (b) if custom metadata exists in '_config'
    if(!is.na(opt_type[["custom"]]) && any(stringr::str_detect(config_files, paste0("^", metadata_file, "$")))){
      opt_meta <- paste0("--metadata-file=", file.path(config_path, metadata_file))

      if(verbose){
        ui_alert_info("Customised metadata is used ({.path ",
                      "JOURNAL/_config/", metadata_file,"}).")
      }
    # Default metadata is used
    }else{
      if(verbose && !is.na(opt_type[["custom"]])){
        ui_alert_warning("No custom metadata file exists in {.path ", config_path, "}. ",
                         "It is desirable to provide a custom {.path ",  metadata_file, "}. ",
                          "Default ", opt_type["metadata"], " metadata is used.")
      }
      opt_meta <- paste0("--metadata-file=", file.path(program_path, "pandoc", metadata_file))
    }

  }else{
    # xml/AST pasa por acá
  }

  rmarkdown::pandoc_convert(wd = wdir,
                            input = file_input,
                            from = opt_type["from"],
                            output = file_output,
                            to = opt_type["to"],
                            citeproc = T,
                            verbose = F,
                            options = c(opt_gral, opt_meta, app_files,
                                        opt_filters, opt_biblio, opt_templ)
  )

  invisible(TRUE)
}


