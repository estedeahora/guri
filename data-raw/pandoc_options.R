data_excel <- "data-raw/pandoc_options.xlsx"
sheets <- c("type", "opts", "lua")
# pandoc_options <- purrr::map(sheets, \(.x) readxl::read_excel(data_excel, sheet = .x)) |>
#   purrr::set_names(sheets)

pandoc_options <- lapply(sheets, \(.x) readxl::read_excel(data_excel, sheet = .x))
names(pandoc_options) <- sheets

pandoc_req <- "3.2"
guri_version <- "1.0.0"

usethis::use_data(pandoc_options, guri_version, pandoc_req,
                  overwrite = TRUE, internal = TRUE)
