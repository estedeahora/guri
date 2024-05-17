#' Make markdown appendix from docx documents
#'
#' @param art_path A string with the path to the article folder, where the appendix files are located.
#' @param art_id A string with the article id, used to identify the appendix files. The appendix files should be named as "art_app1.docx", "art_app2.docx", etc.
#'
#' @return A character vector containing the names of the converted Markdown files.

guri_appendix <- function(art_path, art_id){
  appendix_files <-  list.files(art_path, pattern = paste0(art_id, "_app[0-9]*\\.docx"))

  purrr::walk(appendix_files,
              \(file){
                rmarkdown::pandoc_convert(wd = art_path,
                                          input = file,
                                          from = "docx+citations",
                                          output = stringr::str_replace(file, "docx", "md") ,
                                          citeproc = T,
                                          to = "markdown")}
  )

  return(stringr::str_replace(appendix_files, "docx", "md"))
}

