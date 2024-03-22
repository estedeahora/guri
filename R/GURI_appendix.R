#' Converts files containing appendices in '.docx' format to markdown ('.md') format.
#'
#' @return Returns the name of the files containing the appendices in markdown format.


guri_appendix <- function(wdir, art){
  appendix_files <-  list.files(wdir, pattern = paste0(art, "_app[0-9]*\\.docx"))

  walk(appendix_files,
       \(file){
         pandoc_convert(wd = wdir,
                        input = file,
                        from = "docx+citations",
                        output = str_replace(file, "docx", "md") ,
                        citeproc = T,
                        to = "markdown")}
  )

  return(str_replace(appendix_files, "docx", "md"))
}

