# Gurí<a href="https://github.com/estedeahora/guri"><img src="manual/figures/guri_logo.png" align="right" height="100"/></a>

## Gestor Unificado de formatos para Revistas de Investigación [*Unified Format Manager for Research Journals*]

[![CC BY-NC-SA 4.0](https://img.shields.io/badge/License-CC%20BY--NC--SA%204.0-lightgrey.svg)](http://creativecommons.org/licenses/by-nc-sa/4.0/) [![es](https://img.shields.io/badge/lang-es-yellow.svg)](https://github.com/estedeahora/guri/blob/main/README.md) [![en](https://img.shields.io/badge/lang-en-red.svg)](https://github.com/estedeahora/guri/blob/main/README.en.md)

This project makes it possible to automate the process of generating final documents for scientific journals from documents obtained in the proofreading stage. The tool is based on the use of [Pandoc](https://pandoc.org/) as a tool for conversion between formats, to which it incorporates a set of *Lua* filters, as well as a workflow that allows the correct conversion of the documents entered.

The project is a preliminary version.

## Documentation

A detail of the work proposal and file preparation can be found in the [manual](manual/manual-old-version).pdf). To generate the final files you must run the [code available in the ./scripts](script/) folder.

## Dependences

The following software is required to use this tool:

-   [Pandoc](https://pandoc.org/);
-   [R](https://cran.r-project.org/) and the r libraries: `tidyverse`, `rmarkdown`, `readxl`, `tinytex` y `crayon`;
-   Some distribution of *LaTeX*. It is recommended to use [TinyTeX](https://yihui.org/tinytex/) , which is intended to be used directly from R and facilitates much of the package installation process without requiring too much knowledge of the subject. In fact this version is used by default for the generation of `PDF` files.

## Contributing

Pull requests, bug reports, and feature requests are welcome.

## Licence

If your journal uses this tool as part of its editorial process, please add the following text within your website (usually within the 'editorial policy' section) in the different languages used in the journal:

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
