# \~!gurí\_<a href="https://github.com/estedeahora/guri"><img src="docs/figures/guri_logo.png" align="right" height="100"/></a>

## Gestor Unificado de formatos para Revistas de Investigación [*Unified Format Manager for Research Journals*]

<!-- badges: start -->
[![CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](http://creativecommons.org/licenses/by-nc-sa/4.0/)
[![es](https://img.shields.io/badge/lang-es-yellow.svg)](https://github.com/estedeahora/guri/blob/main/README.md)<!-- [![pt-br](https://img.shields.io/badge/lang-pt--br-green.svg)](https://github.com/jonatasemidio/multilanguage-readme-pattern/blob/master/README.pt-br.md)-->
[![Project Status: Active – The project has reached a stable, usable state and is being actively developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![R-CMD-check](https://github.com/estedeahora/guri/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/estedeahora/guri/actions/workflows/R-CMD-check.yaml)
[![r-universe](https://estedeahora.r-universe.dev/badges/guri)](https://estedeahora.r-universe.dev/guri)
<!-- badges: end -->

`~!gurí_` is a project that facilitates the editorial production of scientific journals, through the generation of output documents from manuscript obtained in the 'peer review' phase in `docx` format.  For this purpose, this project is based on the R package `{guri}`, which coordinates the process of generating the final documents in different formats. 

This project aims to solve the difficulties faced by some diamond-access academic journals in generating final documents in different formats in a consistent way, avoiding duplicated processes and high editorial costs. It also takes into account that many scientific journals use `docx` documents as the basis of their workflows.

The aim of the project is to outline and separate the main elements that make up a scientific article. To do this, for each article, a `docx` file must be generated ( using a predefined template and with the citations identified with Zotero) and a `yaml` file with the metadata of the article. Optionally, other files can be provided with information from the [CRediT taxonomy](https://credit.niso.org/), floating elements (figures and tables) and appendices. From these initial files an intermediate `markdown` file is generated, which is used to generate the final documents (in `pdf`, `html` and `xml` format). In addition, this tool allows the generation of an xml file for the DOI deposit in Crossref. Due to its design, the project allows a strong adaptation and customisation so that it can be adapted to the particularities and aesthetics of each journal.

![General scheme](docs/figures/scheme_gral.png)

In short, we can say that the project consists of two aspects that work together: a workflow and a set of programming tools. On the one hand, the project requires the adoption of a *workflow*, which includes a certain organisation of files and folders, as well as the templating of manuscripts following a set of predefined rules. Moreover, the project is based on a set of *programming tools* that take care of the creation of the final documents in the different formats. Much of this work is done with [Pandoc](https://pandoc.org/), which is used 'under the bonnet' for conversion between mark-up formats. To adapt Pandoc to the needs of academic publishing, a set of *Lua* filters and custom *templates* are used. In addition, [*LaTeX*](https://www.latex-project.org/) is used to generate the files in `pdf` format. Finally, the project uses the *R* programming language to coordinate and 'wrap' the whole process. In practice, this whole process is coordinated by the *R* package `{guri}`. 

## Documentation

A detail of the work proposal and file preparation can be found in the [documentation web](https://estedeahora.github.io/guri/). 

## Software dependencies

The use of this tool requires the prior installation of [R](https://cran.r-project.org/) (version 4.3 or higher recommended), being recommended to have installed [RStudio](https://posit.co/products/open-source/rstudio/), which facilitates the work with R. Although other programs are used for the operation of the project, the R package `{guri}` is responsible for the installation of these dependencies (see `guri_install()`). Therefore, as part of the `{guri}` configuration, the package will install [Pandoc](https://pandoc.org/) and a *LaTeX* distribution called [tinytex](https://yihui.org/tinytex/), which has a robust integration with R, facilitating the installation of the necessary LaTeX packages.[^1]

[^1] By default, the following `LaTeX` packages which are used by the Pandoc template will also be installed: [`amsfonts`](https://ctan.org/pkg/amsfonts), [`amsmath`](https://ctan.org/pkg/amsmath), [`lm`](https://ctan.org/pkg/lm), [`unicode-math`](https://ctan.org/pkg/unicode-math), [`iftex`](https://ctan.org/pkg/iftex), [`listings`](https://ctan.org/pkg/listings), [`fancyvrb`](https://ctan.org/pkg/fancyvrb), [`longtable`](https://ctan.org/pkg/longtable), [`booktabs`](https://ctan.org/pkg/booktabs), [`graphicx`](https://ctan.org/pkg/graphicx), [`hyperref`](https://ctan.org/pkg/hyperref), [`xcolor`](https://ctan.org/pkg/xcolor), [`soul`](https://ctan.org/pkg/soul), [`geometry`](https://ctan.org/pkg/geometry), [`setspace`](https://ctan.org/pkg/setspace), [`babel`](https://ctan.org/pkg/babel), [`xeCJK`](https://ctan.org/pkg/xecjk), [`fontspec`](https://ctan.org/pkg/fontspec), [`selnolig`](https://ctan.org/pkg/selnolig), [`mathspec`](https://ctan.org/pkg/mathspec), [`biblatex`](https://ctan.org/pkg/biblatex), [`bibtex`](https://ctan.org/pkg/bibtex), [`biber`](https://ctan.org/pkg/biber), [`upquote`](https://ctan.org/pkg/upquote), [`microtype`](https://ctan.org/pkg/microtype), [`csquotes`](https://ctan.org/pkg/csquotes), [`natbib`](https://ctan.org/pkg/natbib), [`bookmark`](https://ctan.org/pkg/bookmark), [`footnotehyper`](https://ctan.org/pkg/footnotehyper), [`footnote`](https://ctan.org/pkg/footnote), [`xurl`](https://ctan.org/pkg/xurl), [`parskip`](https://ctan.org/pkg/parskip) and [svg](https://ctan.org/pkg/svg). In turn, the adaptation of the template uses the following packages:  [`adjustbox`](https://ctan.org/pkg/adjustbox), [`fontawesome5`](https://ctan.org/pkg/fontawesome5), [`caption`](https://ctan.org/pkg/caption), [`ccicons`](https://ctan.org/pkg/ccicons), [relsize](https://ctan.org/pkg/relsize), [`truncate`](https://ctan.org/pkg/truncate), [`lastpage`](https://ctan.org/pkg/lastpage) and [`koma-script`](https://ctan.org/pkg/koma-script).

## Installation

You must install {guri}. For this you can do it from `r-universe` as follows: 


``` r
options(repos = c(
    estedeahora = 'https://estedeahora.r-universe.dev',
    CRAN = 'https://cloud.r-project.org'))
install.packages('guri')
```

Alternatively, you can do it directly from the github repository, for which you can use {remotes} or {pak} as you prefer.

``` r
# install.packages("remotes")
remotes::install_github("estedeahora/guri")

# or 

# install.packages("pak")
pak::pkg_install("estedeahora/guri")
```
Once {guri} is installed, you must load the package and install the external dependencies (Pandoc and Tinytex). This process may take a few minutes and requires a stable internet connection.

``` r
library(guri)
guri_install()
```

## Licence

*`~!gurí_`* can be used as part of the production process of *diamond access journals* (journals without Article Processing Charges -APC- and without paywalls). Beyond this restriction, there are no limits other than authorship attribution. If your journal uses this tool as part of its editorial process, please add the following text within your website (usually within the 'editorial policy' section) in the different languages used in the journal:

> *Español:*\
> Los documentos finales de esta revista fueron generados utilizando [\~!guri](https://github.com/estedeahora/guri).
>
> *English:*\
> The final documents of this journal were generated using [\~!guri](https://github.com/estedeahora/guri).
>
> *Português:*\
> Os documentos finais desta revista foram gerados usando [\~!guri](https://github.com/estedeahora/guri).

This work is licensed under a [Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License](http://creativecommons.org/licenses/by-nc-sa/4.0/). This software carries no warranty of any kind.

[![CC BY-NC-SA 4.0](https://licensebuttons.net/l/by-nc-sa/4.0/88x31.png)](http://creativecommons.org/licenses/by-nc-sa/4.0/)

## Contributing

Pull requests, bug reports, and feature requests are welcome. Use the [issues](https://github.com/estedeahora/guri/issues) to report bugs or request features.
