#' Lists the articles in a journal issue
#'
#' @param path_issue String with the path to the issue folder to list the
#'   articles in the issue.
#'
#' @return A tibble with two columns: articles path (art_path) and articles id (art_id).
#'
#' @export

guri_list_articles <- function(path_issue){

  if(!dir.exists(path_issue)){
    ui_abort("The folder {.path ", path_issue, "} does not exist.\n",
             "Create the directory with the articles to format. ",
             "Remember to place a folder for each article using as folder name ",
             "'art' and three numbers, followed by the text of your choice ",
             "(example: art301_my-article).")
  }

  art <- dplyr::tibble(art_path = list.dirs(path_issue, recursive = F ))
  art$art_id <- art$art_path |>
    stringr::str_remove(path_issue) |>
    stringr::str_remove("_.*$")

  return(art)
}
