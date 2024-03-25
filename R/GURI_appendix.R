#' DESCRIBE
#'
#' @param wdir description
#' @param art description
#'
#' @return Returns the name of the files containing the appendices in markdown format.

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

