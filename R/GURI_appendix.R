#' Make markdown appendix from docx documents
#'
#'
#' @param wdir The working directory where the appendix files are located.
#' @param art The article name used to identify the appendix files. The appendix files should be named as "art_app1.docx", "art_app2.docx", etc.
#'
#' @return A character vector containing the names of the converted Markdown files.

guri_appendix <- function(wdir, art){
  appendix_files <-  list.files(wdir, pattern = paste0(art, "_app[0-9]*\\.docx"))

  purrr::walk(appendix_files,
              \(file){
                rmarkdown::pandoc_convert(wd = wdir,
                                          input = file,
                                          from = "docx+citations",
                                          output = stringr::str_replace(file, "docx", "md") ,
                                          citeproc = T,
                                          to = "markdown")}
  )

  return(stringr::str_replace(appendix_files, "docx", "md"))
}

