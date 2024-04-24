#' Create the basic file structure for a new journal/journal repository
#'
#' @description
#' Create the basic file structure for a new journal or journal repository
#'   (to manage multiple journals).
#'
#' @param journal A string with the short name of the journal. This 'short name'
#'   can contain only letters, numbers or a low dash (_) and must begin with a
#'   letter. Use only if you will work with the journal repository model (for
#'   single journal use NULL, default value). The journal name 'example' is not
#'   allowed.
#' @param repository Logical. Will it work with the journal repository model
#'   (Default: `FALSE`). If `TRUE` is chosen, you must set a value for `journal`
#'   (unless `example = TRUE`) and a separate folder will be created for each
#'   journal. If `FALSE` the root folder will contain the files needed to
#'   manage your journal.
#' @param csl_name A string with the CSL's name (without its extension).
#'   See: https://github.com/citation-style-language/styles
#' @param example Logical. Do you want to create the journal provided as an
#'   example? (Default = FALSE)
#' @param force Logical. Should the journal be generated even if it already exists
#'   in the folder? This will ignore the '.guri' file if present. (Default: FALSE)
#'
#' @details
#' Create the journal folder (if repository `TRUE`). The journal directory
#' includes a configuration folder with the files used to configure the journal
#' output (`_config`) and a folder with the basic files you will use for the
#' production process (`default-files`). In addition, the `_journal.yaml` file
#' will be generated, which you will have to edit manually with the basic journal
#' data.
#'
#' The folder structure can contain one journal (repository = TRUE) or multiple
#' journals (repository = TRUE). Journal repositories allow to manage multiple
#' journals in a single working environment. The internal structure of the
#' journals within a repository is identical to that of a single journal.
#'
#' The configuration file features (in `_config`) can be defined with this function
#' during journal creation or independently using (see [guri_config_journal]).
#'
#' If 'example = TRUE' a directory of the journal 'example' (`.\example`) is
#' created with the necessary file structure to generate the final output files.
#'
#' @return Invisible returns the journal folder.
#'
#' @examples
#' # Create a folder structure for a new journal.
#'
#' guri_make_journal(journal = "new_journal", repository = TRUE)
#' fs::dir_tree("new_journal")
#'
#' unlink("new_journal", recursive = TRUE)
#' unlink(".guri")
#'
#' # Create a folder structure for the 'example journal'.
#'
#' guri_make_journal(example = TRUE, repository = TRUE)
#' fs::dir_tree("example", type =  "directory")
#'
#' unlink("example/", recursive = TRUE)
#' unlink(".guri")
#'
#' @export

guri_make_journal <- function(journal = NULL, repository = FALSE,
                              csl_name = NULL, example = FALSE,
                              force = FALSE){

  # TEST: arguments
  if(repository){
    if(example){ # repository = T; example = T -> journal = 'example'
      if(!is.null(journal)){
        ui_alert_info("The name of the example journal is predefined ",
                      "and cannot be modified. ",
                      "The name 'example' will be used instead ",
                      "of the name given in the 'journal' parameter.")
      }

      journal <- "example"

    }else{       # repository = T; example = F
      if(is.null(journal)) {
        ui_abort("Provide a name for the journal.")
      }
      if(length(journal) != 1) {
        ui_abort("Provide a unique name for the journal.")
      }
      if(stringr::str_detect(journal, "^[a-zA-Z]([a-zA-Z0-9_])*$", negate = T)) {
        ui_abort("The name of the journal can only use letters [a-zA-Z], ",
                 "numbers[0-9] and low dash (_) and must begin with a letter.")
      }
      if(journal == "example"){
        ui_abort("'example' is not a valid name for a journal. ",
                 "This name is reserved for the 'example' journal.")
      }
    }

    ui_alert_info("The journal ('", journal ,"') will be generated as part of ",
                  "a journal repository.")

  }else{         # repository = F -> journal = '.'
    if(!is.null(journal)){
      ui_alert_info("`journal` is not a valid field if `repository = FALSE`. ",
                    "This field is ignored and the files are placed in the root folder.")
    }
    journal <- "."
  }

  # CHECK: './.guri' file
  CHECK_guri_file(journal = journal, repository = repository, force = force)

  # CHECK: 'force' confirmation
  if(force){
    CHECK_force(journal = journal, repository = repository)
  }

  # MAKE: './journal_folder' (repository) or "./" (journal)
  if(repository){     # repository = T

    journal_folder <- file.path(getwd(), journal)

    if(!force && dir.exists(journal_folder)){
      if(example){
        ui_abort("'example' is already present in folder. ",
                 "If you want to reinstall the 'example journal', run ",
                 "{.code guri_make_journal(example = TRUE, force = TRUE)}")
      }else{
        ui_abort("The journal name '", journal, "' already exists. To create a ",
                 "new journal, choose a new journal name or set 'force = TRUE'.")
      }
    }

    dir.create(journal_folder)
    ui_alert_success("Create journal folder ('./", journal, "').")

  }else{              # repository = F

    journal_folder <- file.path(getwd())

    standard_files <-  c(dir.exists(file.path(journal_folder, c("_config", "_default-files"))),
                         file.exists(file.path(journal_folder, "_journal.yaml")) )

    if(!force && any(standard_files) ){
      ui_abort("In the working directory there are files/folders that look like ",
               "they belong to an existing journal. If you want to overwrite them, ",
               "delete these files manually or set 'force = TRUE'.")
      }
  }

  # COPY: default files to './_default-files/*'
  file.copy(from = pkg_file("config-files", "_default-files"),
            to = journal_folder,
            recursive = T)
  ui_alert_success("Copy default files in '", fs::path_rel(file.path(journal_folder, "_default-files", "*")), "'.")

  # MAKE: './_config'
  dir.create(file.path(journal_folder, "_config"))
  ui_alert_success("Create configuration folder '(", fs::path_rel(file.path(journal_folder, "_config", "*")), "').")

  # COPY: templates and metadata files to './_config/*'
  guri_config_journal(journal_folder, csl_name = csl_name)

  # COPY: '_journal.yaml'
  if(example){
    use_folder = pkg_file("example")
  }else{
    use_folder = pkg_file("config-files")
  }

  file.copy(from = file.path(use_folder, "_journal.yaml"),
            to = file.path(journal_folder, "_journal.yaml"),
            overwrite = T)

  ui_alert_success("Copy '", fs::path_rel(file.path(journal_folder, "_journal.yaml")),"' file.")

  if(example){

    # COPY: 'example' files
    cli_process_start("Copy example journal issue ({.path ./example/num1/}).")
    file.copy(from = file.path(use_folder, "num1"),
              to = journal_folder, recursive = T,
              overwrite = T)
    cli_process_done()

    # TODO: Agregar función correcta
    ui_alert_info("To generate the output files for this 'example' journal run:\n",
                  col_red("{.code guri_output_issue(path = 'num1', journal = 'example')}."))

    journal <- "The 'example' journal"
  }else{
    ui_alert_info("Edit manually {.path ", fs::path_rel(file.path(journal_folder, "_journal.yaml")), "} file.")

    journal_yaml <- file.path(journal_folder, "_journal.yaml")

    if(rstudioapi::isAvailable() && rstudioapi::hasFun("navigateToFile")) {
      invisible(rstudioapi::navigateToFile(journal_yaml))
    }else {
      utils::file.edit(journal_yaml)
    }
  }

  ui_alert_success(col_green("The journal was successfully created."))

   invisible(journal_folder)
}

# CHECK_guri_file()
# Making checks for the `.guri` file

CHECK_guri_file <- function(repository, journal, force){
  if(file.exists('.guri') && !force){  # './.guri' && force = F

    con <- file('.guri')
    guri_file <- readLines(con)
    close(con)

    if(any(stringr::str_detect(guri_file, paste0("^repository: ", !repository, "$")))){
      ui_abort("Currently 'repository=", !repository, "' is configured in this folder. ",
               "If you want to overwrite the current configuration use 'force = TRUE' ",
               "(WARNING: you can override configuration of the journals currently present).")
    }

    if(repository){                    #  .guri && force = F && repository = T

      list_journals <- stringr::str_detect(guri_file, paste0("^journals: .*", "$"))
      guri_file[list_journals] <- paste(guri_file[list_journals], journal, sep = ", ")

      cat(guri_file, file= ".guri", sep = "\n")
      ui_alert_info("'", journal, "' is added to {.path .guri}.")
    }

  }else{
    if(file.exists('.guri')){          # .guri && force = T
      ui_alert_warning(col_yellow("[WARNING] "), "The root folder is already ",
                       "configured as a ~!guri_ repository/journal folder.\n",
                       "            Do you want to overwrite this configuration (",
                       cli::style_underline(col_red("not usually recommended")), ")?\n",
                       col_yellow("Press: N/y"))
      confirm <- readline()
      if(!confirm %in% c("y", "Y")){
        ui_abort("Journal creation not allowed (force = TRUE but not confirmed by user)")
      }
    }
    cat("repository: ", repository, "\n", file= ".guri", sep = "")
    if(repository){
      cat("journals: ", journal, "\n", file= ".guri", sep = "", append = TRUE)
    }

    ui_alert_info("{.path .guri} file created in the root folder.")

  }

  invisible(TRUE)
}

# CHECK_force()
# Verify that the use of `force = TRUE` is as desired (do not remove without user confirmation).

CHECK_force <- function(repository, journal){

  if(repository){
    ui_alert_warning(col_yellow("[WARNING] "), "The chosen journal folder ",
                     "{.path ./", journal, "} is already present.")
  }else{
    ui_alert_warning(col_yellow("[WARNING] "), "There is a journal in the current folder.\n")
  }

  cat("            ",
      "Do you want to overwrite it (",
      cli::style_underline(col_red("existing files will be",
                                   "removed and replaced")),
      ")?)\n",
      col_yellow("   Press: N/y"), sep = "")

  confirm <- readline()
  if(!confirm %in% c("y", "Y")){
    ui_abort("Journal creation not allowed ('force = TRUE', but not confirmed by user)")
  }

  invisible(TRUE)
}
