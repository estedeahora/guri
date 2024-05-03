#' Lists the articles in a journal issue
#'
#' @param path_issue String with the path to the issue folder to list the
#'   articles in the issue.
#'
#' @return A tibble with two columns: articles path (art_path) and articles id (art_id).

guri_list_articles <- function(path_issue){

  if(!dir.exists(path_issue)){
    ui_abort("The folder {.path ", path_issue, "} does not exist.\n",
             "Create the directory with the articles to format. ",
             "Remember to place a folder for each article using as folder name ",
             "'art' and three numbers, followed by the text of your choice ",
             "(example: art301_my-article).")
  }

  art_path <- fs::dir_ls(path_issue, type = "directory")

  art_dir <- art_path |>
    fs::path_split() |>
    purrr::map_chr(~.x[length(.x)])

  art_id <- art_dir |>
    stringr::str_extract("^art[0-9]{3}")

  art <- dplyr::tibble(path = art_path,
                       dir  = art_dir,
                       id   = art_id)

  return(art)
}
