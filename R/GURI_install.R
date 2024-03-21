#' Updates/installs the external dependencies necessary for working `~!guri_`.
#'
#' @description
#' Upgrade or install (as necessary) pandoc, as well as the latex distribution
#' (tinytex) and latex packages.
#'
#' @param pandoc Logical. Should pandoc be installed/updated? (default 'TRUE')
#' @param tinytex Logical. Should tinytex be installed/updated? (default 'TRUE')
#' @param force Logical. Should pandoc  and tinytex be forced to reinstall? (default 'FALSE')
#'
#' @return Invisible. A list with a logical vector indicating whether tinytex
#' and pandoc are available and two items with the installed versions of Tinitex and Pandoc.
#'
#' @export
#

GURI_install <- function(pandoc = T, tinytex = T, force = F){

  if(pandoc){
    pandoc::pandoc_install(force = force)
  }

  # Instalación de distribución tinytex y paquetes sugeridos
  if(tinytex){
    if(!tinytex::is_tinytex() | force){

      cli_process_start("Installing latex distribution (tinytex)")
      tinytex::install_tinytex()
      cli_process_done()

    }else{
      cli_process_start("Updating the tinytex latex distribution")
      tinytex::tlmgr_update()
      cli_process_done()
    }

    latex_pkg <- c("amsmath", "amsfonts", "lm", "unicode-math", "iftex", "listings",
                   "fancyvrb", "booktabs", "hyperref", "xcolor", "soul", "geometry",
                   "setspace", "babel", "fontspec", "selnolig", "mathspec", "biblatex",
                   "bibtex", "upquote", "microtype", "csquotes", "natbib",
                   "bookmark", "xurl", "parskip", "svg", "geometry", "multirow",
                   "etoolbox", "luacolor",  "lua-ul",
                   "adjustbox", "fontawesome5", "caption",  "ccicons",
                   "relsize", "koma-script", "truncate", "lastpage")

    cli_process_start("Checking necessary latex packages")
    latex_pkg_installed <- lapply(latex_pkg, tinytex::check_installed)  |>
      as.logical()
    cli_process_done()

    if(sum(!latex_pkg_installed) > 0){
      cli_process_start("Installing necessary latex packages")
      tinytex::tlmgr_install(paste0(latex_pkg[!latex_pkg_installed], ".sty"))
      cli_process_done()
    }
  }
  invisible(list(c(tinytex = tinytex::is_tinytex(),
                   pandoc = pandoc::pandoc_available()),
                 tinytex_version = tinytex::tlmgr_version(),
                 pandoc_version = pandoc::pandoc_version() ))
}


# dep <- c("tidyverse", "rmarkdown", "readxl", "tinytex", "crayon")
# pkg <- .packages(all.available = TRUE)
#
# dep_needed <- dep [!dep %in% pkg]
#
# if(length(dep_needed) > 0){
#   cat("\n", "Instalando paquetes R faltantes:",
#       paste0(dep_needed, collapse = ", ") )
#   install.packages(dep_needed)
# }else{
#   cat("\n", "Paquetes R necesarios presentes")
# }
