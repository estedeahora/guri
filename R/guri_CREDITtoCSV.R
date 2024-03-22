#' Prepare the working directory for each article
#'
#' @param art_path A string with the path to the article folder.
#' @param art_pre A string. This prefix is used to identify the folders where each issue of your journal will be stored. For example, if you use 'num' (default) the folders where you should store the issues of your journal will be 'num1', 'num2', and so on.
#'
#' @return Invisible True.

GURI_CREDITtoCSV <- function(art_path, art_pre){

  # Generar "art[~]_credit.csv "
  credit_xlsx <- file.path (art_path, paste0(art_pre, "_credit.xlsx"))
  credit_csv  <- paste0(art_path, art_pre, "_credit.csv")

  if(file.exists(credit_xlsx)){
    readxl::read_xlsx(credit_xlsx) |> write.csv(credit_csv, row.names = F, na = "")
  }

  invisible(T)

}

