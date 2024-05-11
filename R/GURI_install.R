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

guri_install <- function(pandoc = T, tinytex = T, force = F){

  # Pandoc
  if(pandoc){
    pandoc::pandoc_install(force = force)
  }

  # tinytex & LaTeX packages
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

    latex_pkg <- c("amsmath", "amsfonts", "lm", "unicode-math", "iftex",
                   "fancyvrb", "booktabs", "hyperref", "xcolor", "geometry",
                   "babel", "fontspec", "selnolig", "etoolbox", "bibtex",
                   "natbib", "bookmark",
                   # not in https://github.com/rstudio/tinytex/blob/main/tools/pkgs-custom.txt
                   "upquote", "microtype", "csquotes", "xurl", "parskip",
                    "luacolor",  "lua-ul", "svg",  "multirow",
                   "adjustbox", "caption", "fontawesome5", "ccicons",  "rorlink",
                   "koma-script", "truncate", "lastpage", "relsize","listings",
                   "soul", "setspace", "mathspec", "biblatex")

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
