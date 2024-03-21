#' GURI_prepare
#'

GURI_prepare <- function(art_path, art_pre){

  # # Crear "art[~]_biblio.json" vacío si no tiene bibliografía
  # biblio <- paste0(art_path, art_pre, "_biblio.json")
  # if(!file.exists(biblio)){
  #   write_file(x = "[]", file = biblio)
  # }

  # Generar "art[~]_credit.csv "
  credit_xlsx <- paste0(art_path, art_pre, "_credit.xlsx")
  credit_csv  <- paste0(art_path, art_pre, "_credit.csv")

  if(file.exists(credit_xlsx)){
    read_xlsx(credit_xlsx) |> write.csv(credit_csv, row.names = F, na = "")
  }
}
