#' Función para generar archivos finales de un artículo individual
#'
#' @description
#' describir
#'
#' @param art_path String...
#' @param art_name String...
#' @param verbose Logical...
#' @param zip_file Logical...
#' @param clean_files Logical...
#'
#' @return Invisible. ...
#'
#' @export

# art_path <- file.path(".","example", "num1", "art301_messi")
# art_name <- "art301"

guri <- function(art_path, art_name, verbose = F,
                 zip_file = F, clean_files = T){

  pandoc_req <- "3.1.12"

  if(!pandoc::pandoc_version() >= pandoc_req){
    cli_alert_info(paste0("To upgrade Pandoc run",
                          col_red("`GURI_install(pandoc = T, tinytex = F)`"),
                          "; or Download manually the latest version from the Pandoc site:",
                          "{.url https://github.com/jgm/pandoc/releases/latest}"))
    cli_abort(paste0("Upgrade the Pandoc version (", pandoc_req, " or later is required)."))
  }

  cli_h1(col_blue( paste("Article:", art_name)))

  # Modificar: art[~]_CREDIT.xlsx -> art[~]_CREDIT.csv

  credit_xlsx <- file.path(art_path, paste0(art_name, "_credit.xlsx"))

  if(file.exists(credit_xlsx)){
    # TODO: Pasar a función independiente `CREDITtoCSV()`

    cli_process_start(paste0(col_yellow("File preparation (converting "),
                             "{.path ", art_name, "_CREDIT.xml}",
                             col_yellow(" to csv file).")) )

    credit_csv  <- stringr::str_replace(credit_xlsx, "\\.xlsx$", "\\.csv")
    readxl::read_xlsx(credit_xlsx) |> write.csv(credit_csv, row.names = F, na = "")

    cli_process_done()

  }


  # docx -> biblio
  cat("\033[33m", "* Crear archivo de bibliografia (", art_name, "_biblio).", "\033[39m")
  guri_biblio(art_path, art_name)
  cat("DONE\n")
  # md -> AST
  cat("\033[33m", "* Crear AST (", art_name, "_AST.json ).", "\033[39m")
  guri_to_AST(art_path, art_name)
  cat("DONE\n")

  # Convert files
  # docx -> md
  cli_process_start(col_yellow("Crear archivo markdown"))
  guri_to_md(art_path, art_name, verbose = verbose)
  cli_process_done()

  # md -> jats
  cat("\033[33m", "* Crear archivo jats-xml (", art_name, ".xml ).", "\033[39m")
  guri_to_jats(art_path, art_name, verbose = verbose)
  cat("DONE\n")
  # md -> html
  cat("\033[33m", "* Crear archivo html (", art_name, ".html ).", "\033[39m")
  guri_to_html(art_path, art_name, verbose = verbose)
  cat("DONE\n")
  # md -> tex + pdf
  cat("\033[33m", "* Crear archivo latex (", art_name, ".tex ).",
      "y pdf (", art_name, "pdf ).", "\033[39m")
  guri_to_pdf(art_path, art_name, verbose = verbose)
  cat("DONE\n")

  # File reorganization
  wd_orig <- getwd()
  setwd(art_path)

  # Zip file
  if(zip_file){
    cat("\033[33m", "* Crear zip con archivos usados como entrada", "\033[39m")
    zip_input(art_name)
    cat("DONE\n")
  }
  # Clean files
  if(clean_files){
    cat("\033[33m", "* Mover archivos temporales a './_temp/'", "\033[39m")
    guri_clean_temp(art_name)
    cat("DONE\n")
    cat("\033[33m", "* Mover archivos finales a './_output/'", "\033[39m")
    guri_output(art_name)
    cat("DONE\n")
  }
  setwd(wd_orig)
}

