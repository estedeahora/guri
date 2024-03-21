# GURI_appendix() ------------------------------------------
# Transformación de archivos de anexos docx -> md
# Devuelve el listado de archivos para anexos

GURI_appendix <- function(wdir, art){
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

