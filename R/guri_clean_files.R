#' Clean temporary log and output files
#'
#' @param art_path A string with the path to the article folder.
#' @inheritParams guri_outputs
#'
#' @return Invisible TRUE.

guri_clean_files <- function(art_path, art_id, verbose){

  if(verbose){
    cli_process_start("Cleaning up working directory and temporary files.")
  }
  # Dir creation
  path_temp <- fs::dir_create(file.path(art_path, "_temp"))
  path_out <- fs::dir_create(file.path(art_path, "_output"))
  if(verbose){
    path_log <- fs::dir_create(file.path(art_path, "_log"))
  }

  archivos <- fs::dir_ls(art_path, recurse = F, type = "file")

  sel_temp <- c("\\.tex", "\\.native", "\\.md", "_app[0-9]\\.md",
                "_credit\\.csv", "_biblio\\.((json)|(bib))")
  pattern_temp <- make_pattern(sel_temp, art_id )
  move_files(pattern_temp, path_dest = path_temp, file_list = archivos)
  # ui_alert_success("Move temporary files to './_temp/'")

  sel_out <- c("\\.pdf", "\\.xml", "\\.html")
  pattern_out <- make_pattern(sel_out, art_id )
  move_files(pattern_out, path_dest = path_out, file_list = archivos)
  # ui_alert_success("Move output files to './_output/'")

  if(verbose){
    pattern_log <- paste0(".*log-.*\\.log")
    move_files(pattern_log, path_dest = path_log, file_list = archivos)
    # ui_alert_success("Move log files to './_log/'")
  }

  if(verbose){
    cli_process_done(msg_done = col_grey("Cleaning up working directory and temporary files."))
  }
  invisible(TRUE)
}

make_pattern <- function(string, root){

  groups <- paste0("(", string, ")")
  groups_collapsed <- paste0(groups, collapse = "|")

  pattern <- paste0(".*", root, "(", groups_collapsed,")" )
  return(pattern)
}

move_files <- function(pattern, path_dest, file_list){

  files <- stringr::str_extract(file_list, pattern)
  files <- stats::na.omit(files)

  fs::file_move(path = files, new_path = path_dest)

  invisible(TRUE)
}
